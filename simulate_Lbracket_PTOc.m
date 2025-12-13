% SIMULATE_LBRACKET_PTOC Run PTOc on L-bracket problem
%
%   This script sets up the L-bracket and runs the compliance minimization PTO algorithm.
%
%   Results are saved to 'Lbracket_PTOc_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== L-bracket - PTOc (Compliance minimization) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOc parameters
q = 1.0;                % Compliance exponent for material distribution
r_min = 2.0;            % Filter radius (in element units)
alpha = 0.3;            % Move limit
volume_fraction = 0.3;  % Target volume fraction (adjusted for cutout)
max_iter = 300;         % Maximum iterations
plot_flag = true;       % Show plots
plot_frequency = 2;     % Frequency new plot

% Boundary conditions for L-bracket
[fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(false);
fprintf('Target volume fraction: %.2f\n', volume_fraction);

% Create initial density with cutout (void region)
% Note: FEA_analysis expects rho to be nely x nelx
rho_init = ones(nely, nelx) * volume_fraction;
% Set cutout region to minimum density (top-right corner)
% The cutout is from (nelx-cutout_x+1):nelx in x-direction
% and (nely-cutout_y+1):nely in y-direction
cutout_x_start = nelx - cutout_x + 1;
cutout_y_start = nely - cutout_y + 1;
rho_init(cutout_y_start:nely, cutout_x_start:nelx) = 1e-3;

% Target material (fixed) - adjust for cutout area
total_area = nelx * nely;
cutout_area = cutout_x * cutout_y;
active_area = total_area - cutout_area;
TM = volume_fraction * active_area;

% Use rho_init as starting point
rho = rho_init;

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.change = [];

% Main iteration loop
for iter = 1:max_iter
    fprintf('L-bracket PTOc Iteration %d\n', iter);
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute element compliance
    C = compute_compliance(nelx, nely, rho, p, E0, nu, U, K_global);
    
    % 3. Material redistribution loop
    RM = TM;  % Remaining material
    rho_opt = zeros(nely, nelx);
    
    % Inner loop: distribute material proportionally to compliance
    inner_max = 20;
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOc(C, RM, q, 1e-3, 1.0);
        
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
    
    % 4. Density filtering
    rho_filtered = density_filter(rho_opt, r_min, nelx, nely, dx, dy);
    
    % 5. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, 1e-3, 1.0);
    
    % 6. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.change(end+1) = change;
    
    % 7. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, 1e-3, 'PTOc');
    
        % 8. Plot intermediate results
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        subplot(2,3,1);
        imagesc(rho_new'); axis equal tight; axis xy; colorbar; title(sprintf('Density (iter %d)', iter));
        subplot(2,3,2);
        imagesc(C'); axis equal tight; axis xy; colorbar; title('Element Compliance');
        subplot(2,3,3);
        plot(history.iteration, history.compliance, 'b-o'); grid on; title('Total Compliance');
        subplot(2,3,4);
        plot(history.iteration, history.volume, 'r-*'); grid on; title('Volume');
        subplot(2,3,5);
        semilogy(history.iteration, history.change, 'm-d'); grid on; title('Density Change (log)');
        subplot(2,3,6);
        imagesc(rho_filtered'); axis equal tight; axis xy; colorbar; title('Filtered Density');
        drawnow;
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('L-bracket PTOc converged after %d iterations.\n', iter);
        break;
    end
end

% Final optimized density
rho_opt = rho;

% Save results
save('Lbracket_PTOc_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'volume_fraction', 'cutout_x', 'cutout_y');

% Plot final design with compliance
figure(2);
figure('Position', [100, 100, 800, 600]);
subplot(2,2,1);
imagesc(rho_opt'); axis equal tight; axis xy; colorbar;
title(sprintf('L-bracket PTOc Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
xlabel('x'); ylabel('y');

% Compute compliance field for final design
[U, K_global] = FEA_analysis(nelx, nely, rho_opt, p, E0, nu, load_dofs, load_vals, fixed_dofs);
C = compute_compliance(nelx, nely, rho_opt, p, E0, nu, U, K_global);
subplot(2,2,2);
imagesc(C'); axis equal tight; axis xy; colorbar;
title('Element Compliance');
xlabel('x'); ylabel('y');

% Convergence history
subplot(2,2,3);
plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5);
grid on; xlabel('Iteration'); ylabel('Total Compliance');
title('Compliance History');

subplot(2,2,4);
yyaxis left;
plot(history.iteration, history.volume./(nelx*nely), 'r-*', 'LineWidth', 1.5);
ylabel('Volume Fraction');
yyaxis right;
semilogy(history.iteration, history.change, 'g-s', 'LineWidth', 1.5);
ylabel('Density Change (log)');
grid on; xlabel('Iteration');
title('Volume and Change History');
legend('Volume Fraction', 'Density Change', 'Location', 'best');

sgtitle('L-bracket - PTOc Results');

% Save figure
saveas(gcf, 'Lbracket_PTOc_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Lbracket_PTOc_results.mat and Lbracket_PTOc_results.png\n');
