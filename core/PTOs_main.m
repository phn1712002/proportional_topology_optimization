function [rho_opt, history] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, plot_flag, plot_frequency)
% PTOS_MAIN Main function for stress-constrained Proportional Topology Optimization
%
%   [RHO_OPT, HISTORY] = PTOS_MAIN(NELX, NELY, P, Q, R_MIN, ALPHA, SIGMA_ALLOW, TAU, MAX_ITER, TM_INIT, PLOT_FLAG)
%   runs the PTOs algorithm and returns the optimized density field and iteration history.
%
% Inputs:
%   nelx, nely - Number of elements in x and y directions
%   p          - SIMP penalty exponent (typically 3)
%   q          - Stress exponent for material distribution (typically 0.5-2)
%   r_min      - Filter radius (in element units)
%   alpha      - Move limit (0 < alpha < 1, typically 0.2-0.5)
%   sigma_allow- Allowable von Mises stress
%   tau        - Stress tolerance band (default: 0.05)
%   max_iter   - Maximum iterations (default: 200)
%   TM_init    - Initial target material volume (default: 0.4 * nelx * nely)
%   plot_flag  - Whether to plot intermediate results (default: true)
%
% Outputs:
%   rho_opt    - Optimized density field (nely x nelx)
%   history    - Structure containing iteration history
%
% Example:
%   [rho, hist] = PTOs_main(60, 30, 3, 1, 1.5, 0.3, 100, 0.05, 200, 0.4, true);

% Default parameters
if nargin < 12
    plot_frequency = 10;
end
if nargin < 11
    plot_flag = true;
end
if nargin < 10
    TM_init = 0.4 * nelx * nely;  % 40% volume fraction
end
if nargin < 9
    max_iter = 200;
end
if nargin < 8
    tau = 0.05;
end

% Material properties
E0 = 1.0;      % Young's modulus of solid
nu = 0.3;      % Poisson's ratio
rho_min = 1e-3;
rho_max = 1.0;
dx = 1; dy = 1; % Element size

% Boundary conditions: cantilever beam
% Fixed left edge, point load at bottom right
fixed_dofs = 1:2*(nely+1);  % Left edge fixed
load_node = (nelx+1)*(nely+1);  % Bottom right corner
load_dof = 2*load_node;         % y-direction
load_dofs = load_dof;
load_vals = -1;  % Downward load

% Initial uniform density
rho = ones(nely, nelx) * TM_init / (nelx * nely);
rho = max(rho_min, min(rho_max, rho));

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.sigma_max = [];
history.TM = [];
history.change = [];

% Target material (adjustable)
TM = TM_init;

% Main iteration loop
for iter = 1:max_iter
    fprintf('PTOs Iteration %d: TM = %.4f\n', iter, TM);
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute stresses
    sigma_vm = compute_stress(nelx, nely, rho, p, E0, nu, U);
    sigma_max = max(sigma_vm(:));
    
    % 3. Adjust target material based on stress constraint
    if sigma_max > (1 + tau) * sigma_allow
        % Too much stress → increase material
        TM = TM * 1.05;
        fprintf('  Stress %.3f > allowable band → increase TM to %.4f\n', sigma_max, TM);
    elseif sigma_max < (1 - tau) * sigma_allow
        % Too little stress → decrease material
        TM = TM * 0.95;
        fprintf('  Stress %.3f < allowable band → decrease TM to %.4f\n', sigma_max, TM);
    end
    
    % 4. Material redistribution loop
    RM = TM;  % Remaining material
    rho_opt = zeros(nely, nelx);
    
    % Inner loop: distribute material proportionally to stress
    inner_max = 20;
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOs(sigma_vm, RM, q, 1.0, rho_min, rho_max);
        
        % Sum of allocated density
        allocated = sum(rho_opt_iter(:));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate optimal density
        rho_opt = rho_opt + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM
            break;
        end
    end
    
    % 5. Density filtering
    rho_filtered = density_filter(rho_opt, r_min, nelx, nely, dx, dy);
    
    % 6. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, rho_min, rho_max);
    
    % 7. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.sigma_max(end+1) = sigma_max;
    history.TM(end+1) = TM;
    history.change(end+1) = change;
    
    % 8. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, 1e-3, 'PTOs', sigma_max, sigma_allow, tau);
    
    % 9. Plot intermediate results
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        subplot(2,3,1);
        imagesc(rho_new); axis equal tight; colorbar; title(sprintf('Density (iter %d)', iter));
        axis xy;
        subplot(2,3,2);
        imagesc(sigma_vm); axis equal tight; colorbar; title(sprintf('Stress (max=%.2f)', sigma_max));
        axis xy;
        subplot(2,3,3);
        plot(history.iteration, history.compliance, 'b-o'); grid on; title('Compliance');
        subplot(2,3,4);
        plot(history.iteration, history.volume, 'r-*'); grid on; title('Volume');
        subplot(2,3,5);
        plot(history.iteration, history.sigma_max, 'g-s'); grid on; title('Max Stress');
        yline(sigma_allow*(1-tau), '--'); yline(sigma_allow*(1+tau), '--');
        subplot(2,3,6);
        plot(history.iteration, history.change, 'm-d'); grid on; title('Density Change');
        drawnow;
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('PTOs converged after %d iterations.\n', iter);
        break;
    end
end

% Final optimized density
rho_opt = rho;

% Plot final design
if plot_flag
    figure(2);
    imagesc(rho_opt); axis equal tight; colorbar;
    axis xy;
    title(sprintf('Final PTOs Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
    xlabel('x'); ylabel('y');
end

fprintf('PTOs completed. Final volume: %.4f, Max stress: %.4f\n', ...
    sum(rho_opt(:))/(nelx*nely), max(sigma_vm(:)));
end
