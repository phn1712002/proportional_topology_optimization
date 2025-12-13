function [rho_opt, history, time_elapsed] = run_ptos_optimization(problem_def, ptos_params, solver_config)
%RUN_PTOS_OPTIMIZATION Executes the Performance-based Topology Optimization (PTOs) algorithm.
%
%   This function optimizes the material density within a specified domain
%   to minimize compliance, while ensuring the maximum von Mises stress
%   remains within an allowable limit.
%
%   [RHO_OPT, HISTORY, TIME_ELAPSED] = RUN_PTOS_OPTIMIZATION(PROBLEM_DEF, PTOS_PARAMS, SOLVER_CONFIG)
%
% Inputs:
%   problem_def - A struct containing the problem definition:
%     .nelx, .nely   - Number of elements along the x and y axes.
%     .dx, .dy       - Element dimensions.
%     .load_dofs     - Degrees of freedom subjected to loads.
%     .load_vals     - Load values.
%     .fixed_dofs    - Fixed degrees of freedom.
%
%   ptos_params - A struct containing the PTOs algorithm parameters:
%     .E0, .nu       - Young's modulus and Poisson's ratio.
%     .initial_tm    - Initial target material (Total Material).
%     .allowable_stress - Allowable von Mises stress.
%     .stress_tau    - Tolerance for the allowable stress band (e.g., 0.05 for ±5%).
%     .penalty       - Penalty factor in the SIMP model (p).
%     .dist_exp      - Material distribution exponent (q).
%     .filter_radius - Density filter radius (r_min).
%     .move_limit    - Density change move limit per iteration (alpha).
%
%   solver_config - A struct containing solver configurations:
%     .max_iterations  - Maximum number of iterations.
%     .plot_flag       - Flag to enable/disable plotting (true/false).
%     .plot_frequency  - Plotting frequency (e.g., every 5 iterations).
%
% Outputs:
%   rho_opt       - The optimized material density matrix.
%   history       - A struct containing the history of metrics per iteration.
%   time_elapsed  - Total execution time of the algorithm (in seconds).
%
% Assumptions: Helper functions such as FEA_analysis, compute_stress,
% material_distribution_PTOs, density_filter, update_density,
% and check_convergence are available in the MATLAB path.

% ======================================================================
% INITIALIZATION AND SETUP
% ======================================================================

% Material and algorithm constants
RHO_MIN = 1e-3; % Minimum density to avoid singular stiffness matrix
RHO_MAX = 1.0;  % Maximum density
MAX_INNER_ITERATIONS = 20; % Max iterations for material redistribution
TM_INCREASE_FACTOR = 1.05; % Factor to increase material when stress is too high
TM_DECREASE_FACTOR = 0.95; % Factor to decrease material when stress is too low
RM_CONVERGENCE_TOL = 1e-6; % Convergence tolerance for remaining material
CONVERGENCE_TOL = 1e-3;    % Convergence tolerance for density change

% Unpack input structs for better readability
nelx = problem_def.nelx;
nely = problem_def.nely;
dx = problem_def.dx;
dy = problem_def.dy;

E0 = ptos_params.E0;
nu = ptos_params.nu;
penalty_p = ptos_params.penalty;
stress_tau = ptos_params.stress_tau;
allowable_stress = ptos_params.allowable_stress;
dist_exp_q = ptos_params.dist_exp;
filter_radius = ptos_params.filter_radius;
move_limit = ptos_params.move_limit;

% Initialize with a uniform density distribution
initial_volume_fraction = ptos_params.initial_tm / (nelx * nely);
rho = ones(nely, nelx) * initial_volume_fraction;
rho = max(RHO_MIN, min(RHO_MAX, rho));

% Initialize history struct
history.iteration = [];
history.compliance = [];
history.volume = [];
history.sigma_max = [];
history.target_material = [];
history.change = [];

% Set the initial (adjustable) target material
target_material = ptos_params.initial_tm;

% Start timer
tic;

% ======================================================================
% MAIN OPTIMIZATION LOOP
% ======================================================================

for iter = 1:solver_config.max_iterations
    fprintf('PTOs Iteration %d: Target Material = %.4f\n', iter, target_material);

    % 1. Perform Finite Element Analysis (FEA)
    [U, K_global] = FEA_analysis(nelx, nely, rho, penalty_p, E0, nu, ...
        problem_def.load_dofs, problem_def.load_vals, problem_def.fixed_dofs);

    % 2. Compute von Mises stresses
    sigma_vm = compute_stress(nelx, nely, rho, penalty_p, E0, nu, U);
    sigma_max = max(sigma_vm(:));

    % 3. Adjust target material based on the stress constraint
    if sigma_max > (1 + stress_tau) * allowable_stress
        % Stress is too high -> more material is needed
        target_material = target_material * TM_INCREASE_FACTOR;
        fprintf('  Stress %.3f > allowable band -> increasing TM to %.4f\n', sigma_max, target_material);
    elseif sigma_max < (1 - stress_tau) * allowable_stress
        % Stress is too low -> reduce material to save cost/weight
        target_material = target_material * TM_DECREASE_FACTOR;
        fprintf('  Stress %.3f < allowable band -> decreasing TM to %.4f\n', sigma_max, target_material);
    end

    % 4. Material redistribution loop
    remaining_material = target_material;
    rho_opt_inner = zeros(nely, nelx);

    for inner_iter = 1:MAX_INNER_ITERATIONS
        % Compute optimal density for the current remaining material
        rho_opt_iter = material_distribution_PTOs(sigma_vm, remaining_material, dist_exp_q, 1.0, RHO_MIN, RHO_MAX);

        % Sum of density allocated in this inner iteration
        allocated_density = sum(rho_opt_iter(:));

        % Update remaining material
        remaining_material = remaining_material - allocated_density;

        % Accumulate the optimal density
        rho_opt_inner = rho_opt_inner + rho_opt_iter;

        % Stop if the remaining material is negligible
        if remaining_material < RM_CONVERGENCE_TOL * target_material
            break;
        end
    end

    % 5. Apply density filter
    rho_filtered = density_filter(rho_opt_inner, filter_radius, nelx, nely, dx, dy);

    % 6. Update density with move limit
    rho_new = update_density(rho, rho_filtered, move_limit, RHO_MIN, RHO_MAX);

    % 7. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));

    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.sigma_max(end+1) = sigma_max;
    history.target_material(end+1) = target_material;
    history.change(end+1) = change;

    % 8. Check for convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, solver_config.max_iterations, ...
        CONVERGENCE_TOL, 'PTOs', sigma_max, allowable_stress, stress_tau);

    % 9. Plot intermediate results (optional)
    if solver_config.plot_flag && (mod(iter, solver_config.plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        subplot(2,3,1); imagesc(1-rho_new); colormap(gray); axis equal tight off; title(sprintf('Density (iter %d)', iter));
        subplot(2,3,2); imagesc(sigma_vm); axis equal tight off; colorbar; title(sprintf('Stress (max=%.2f)', sigma_max));
        subplot(2,3,3); plot(history.iteration, history.compliance, 'b-o'); grid on; title('Compliance');
        subplot(2,3,4); plot(history.iteration, history.volume, 'r-*'); grid on; title('Volume');
        subplot(2,3,5); plot(history.iteration, history.sigma_max, 'g-s'); grid on; title('Max Stress');
        yline(allowable_stress*(1-stress_tau), '--r', 'Lower Bound'); yline(allowable_stress*(1+stress_tau), '--r', 'Upper Bound');
        subplot(2,3,6); plot(history.iteration, history.change, 'm-d'); grid on; title('Density Change'); set(gca, 'YScale', 'log');
        drawnow;
    end

    % Update density for the next iteration
    rho = rho_new;

    % Stop if converged
    if converged
        fprintf('PTOs algorithm converged after %d iterations.\n', iter);
        break;
    end
end

% Final optimized density
rho_opt = rho;

% Stop timer
time_elapsed = toc;

fprintf('Total execution time: %.2f seconds.\n', time_elapsed);

end
