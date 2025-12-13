% SIMULATE_MBB_PTOC Run PTOc on MBB beam problem
%
%   This script sets up the MBB beam (half symmetry) and runs the
%   compliance minimization PTO algorithm.
%
%   Results are saved to 'MBB_PTOc_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== MBB Beam - PTOc (Compliance minimization) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOc parameters
q = 1.0;         % Compliance exponent for material distribution
r_min = 2.0;     % Filter radius (in element units)
alpha = 0.3;     % Move limit
volume_fraction = 0.4; % Target volume fraction
max_iter = 300;  % Maximum iterations
plot_flag = true; % Show plots
plot_frequency = 2;     % Frequency new plot

% Boundary conditions for MBB beam (half symmetry)
[fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(false);
fprintf('Target volume fraction: %.2f\n', volume_fraction);

% Run PTOc
tic;
[rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, plot_flag, plot_frequency);
time_elapsed = toc;

% Save results
save('MBB_PTOc_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'volume_fraction', 'time_elapsed');

% Plot final design with compliance
figure(2);
figure('Position', [100, 100, 800, 600]);
subplot(2,2,1);
imagesc(rho_opt); axis equal tight; colorbar;
axis xy;
title(sprintf('MBB PTOc Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
xlabel('x'); ylabel('y');

% Compute compliance field for final design
[U, K_global] = FEA_analysis(nelx, nely, rho_opt, p, E0, nu, load_dofs, load_vals, fixed_dofs);
C = compute_compliance(nelx, nely, rho_opt, p, E0, nu, U, K_global);
subplot(2,2,2);
imagesc(C); axis equal tight; colorbar;
axis xy;
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

sgtitle('MBB Beam - PTOc Results');

% Save figure
saveas(gcf, 'MBB_PTOc_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to MBB_PTOc_results.mat and MBB_PTOc_results.png\n');
