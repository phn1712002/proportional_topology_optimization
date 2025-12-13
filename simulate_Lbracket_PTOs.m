% SIMULATE_LBRACKET_PTOS Run PTOs on L-bracket problem
%
%   This script sets up the L-bracket and runs the stress-constrained PTO algorithm.
%
%   Results are saved to 'Lbracket_PTOs_results.mat' and figures are generated.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

fprintf('=== L-bracket - PTOs (Stress-constrained) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size


% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs parameters
q = 1.0;         % Stress exponent for material distribution
r_min = 2.0;     % Filter radius (in element units)
alpha = 0.3;     % Move limit
sigma_allow = 120; % Allowable von Mises stress
tau = 0.05;      % Stress tolerance band
max_iter = 300;  % Maximum iterations
plot_flag = true; % Show plots

% Boundary conditions for L-bracket
[fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(plot_flag);
TM_init = 0.3 * nelx * nely; % Initial target material (30% volume fraction due to cutout)

% Create initial density with cutout (void region)
rho_init = ones(nely, nelx);
% Set cutout region to minimum density
rho_init(1:cutout_y, 1:cutout_x) = 1e-3;

% Run PTOs with custom initial density
% We need to modify PTOs_main to accept initial density, but for simplicity
% we'll call PTOs_main and let it generate uniform density, then replace.
% Instead, we'll create a custom loop or modify. Let's use a simplified approach:
% Use PTOs_main but adjust initial TM to account for cutout.

% Since PTOs_main uses uniform initial density, we'll create a wrapper.
% For now, we'll just run with the cutout considered as void (density = rho_min).
% We'll set rho_init as the initial density and adjust TM accordingly.

% Compute actual initial volume
initial_volume = sum(rho_init(:));
TM_init = initial_volume * 0.8; % Use 80% of current volume as target

% Store rho_init for later use
rho = rho_init;

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.sigma_max = [];
history.TM = [];
history.change = [];

% Main iteration loop (simplified from PTOs_main)
for iter = 1:max_iter
    fprintf('L-bracket PTOs Iteration %d: TM = %.4f\n', iter, TM_init);
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute stresses
    sigma_vm = compute_stress(nelx, nely, rho, p, E0, nu, U);
    sigma_max = max(sigma_vm(:));
    
    % 3. Adjust target material based on stress constraint
    if sigma_max > (1 + tau) * sigma_allow
        % Too much stress → increase material
        TM_init = TM_init * 1.05;
        fprintf('  Stress %.3f > allowable band → increase TM to %.4f\n', sigma_max, TM_init);
    elseif sigma_max < (1 - tau) * sigma_allow
        % Too little stress → decrease material
        TM_init = TM_init * 0.95;
        fprintf('  Stress %.3f < allowable band → decrease TM to %.4f\n', sigma_max, TM_init);
    end
    
    % 4. Material redistribution loop
    RM = TM_init;  % Remaining material
    rho_opt = zeros(nely, nelx);
    
    % Inner loop: distribute material proportionally to stress
    inner_max = 20;
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOs(sigma_vm, RM, q, 1.0, 1e-3, 1.0);
        
        % Sum of allocated density
        allocated = sum(rho_opt_iter(:));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate optimal density
        rho_opt = rho_opt + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM_init
            break;
        end
    end
    
    % 5. Density filtering
    rho_filtered = density_filter(rho_opt, r_min, nelx, nely, dx, dy);
    
    % 6. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, 1e-3, 1.0);
    
    % 7. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.sigma_max(end+1) = sigma_max;
    history.TM(end+1) = TM_init;
    history.change(end+1) = change;
    
    % 8. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, 1e-3, 'PTOs', sigma_max, sigma_allow, tau);
    
    % 9. Plot intermediate results
    if plot_flag && (mod(iter, 20) == 0 || iter == 1 || converged)
        figure(1);
        subplot(2,3,1);
        imagesc(rho_new); axis equal tight; colorbar; title(sprintf('Density (iter %d)', iter));
        subplot(2,3,2);
        imagesc(sigma_vm); axis equal tight; colorbar; title(sprintf('Stress (max=%.2f)', sigma_max));
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
        fprintf('L-bracket PTOs converged after %d iterations.\n', iter);
        break;
    end
end

% Final optimized density
rho_opt = rho;

% Save results
save('Lbracket_PTOs_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'sigma_allow', 'tau', 'cutout_x', 'cutout_y', 'time_elapsed');

% Plot final design with stress
figure('Position', [100, 100, 800, 600]);
subplot(2,2,1);
imagesc(rho_opt); axis equal tight; colorbar;
title(sprintf('L-bracket PTOs Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
xlabel('x'); ylabel('y');

% Compute stress field for final design
[U, K_global] = FEA_analysis(nelx, nely, rho_opt, p, E0, nu, load_dofs, load_vals, fixed_dofs);
sigma_vm = compute_stress(nelx, nely, rho_opt, p, E0, nu, U);
subplot(2,2,2);
imagesc(sigma_vm); axis equal tight; colorbar;
title(sprintf('Von Mises Stress (max = %.2f)', max(sigma_vm(:))));
xlabel('x'); ylabel('y');

% Convergence history
subplot(2,2,3);
plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5);
grid on; xlabel('Iteration'); ylabel('Compliance');
title('Compliance History');

subplot(2,2,4);
yyaxis left;
plot(history.iteration, history.sigma_max, 'r-s', 'LineWidth', 1.5);
ylabel('Max Stress');
yyaxis right;
plot(history.iteration, history.volume./(nelx*nely), 'g-*', 'LineWidth', 1.5);
ylabel('Volume Fraction');
grid on; xlabel('Iteration');
title('Stress and Volume History');
legend('Max Stress', 'Volume Fraction', 'Location', 'best');

sgtitle('L-bracket - PTOs Results');

% Save figure
saveas(gcf, 'Lbracket_PTOs_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Lbracket_PTOs_results.mat and Lbracket_PTOs_results.png\n');
