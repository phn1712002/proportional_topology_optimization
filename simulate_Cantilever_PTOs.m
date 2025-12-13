% SIMULATE_CANTILEVER_PTOS Run PTOs on cantilever beam problem
%
%   This script sets up the cantilever beam and runs the
%   stress-constrained PTO algorithm.
%
%   Results are saved to 'Cantilever_PTOs_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== Cantilever Beam - PTOs (Stress-constrained) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs parameters
q = 1.0;            % Stress exponent for material distribution
r_min = 2.0;        % Filter radius (in element units)
alpha = 0.3;        % Move limit
sigma_allow = 100;  % Allowable von Mises stress
tau = 0.05;         % Stress tolerance band
max_iter = 300;     % Maximum iterations
plot_flag = true;   % Show plots
plot_frequency = 2; % Frequency new plot

% Boundary conditions for cantilever beam
[fixed_dofs, load_dofs, load_vals, nelx, nely] = cantilever_beam_boundary(false);
TM_init = 0.4 * nelx * nely; % Initial target material (40% volume fraction)

% ======================================================================
% PTOs ALGORITHM IMPLEMENTATION (based on docs/docs-ptos.md and PTOs_main.m)
% ======================================================================

% Additional material parameters
rho_min = 1e-3;
rho_max = 1.0;

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

% Start timer
tic;

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
    
    % 9. Plot intermediate results (optional)
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

% End timer
time_elapsed = toc;

% ======================================================================
% END OF PTOs ALGORITHM
% ======================================================================

% Save results
save('Cantilever_PTOs_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'sigma_allow', 'tau', 'time_elapsed');

% Save figure
saveas(gcf, 'Cantilever_PTOs_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Cantilever_PTOs_results.mat and Cantilever_PTOs_results.png\n');
