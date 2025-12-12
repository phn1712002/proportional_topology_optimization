% SIMULATE_CANTILEVER_PTOC Run PTOc on cantilever beam problem
%
%   This script sets up the cantilever beam and runs the
%   compliance minimization PTO algorithm.
%
%   Mesh: 120 x 60 elements
%   Boundary conditions: fixed left edge, point load at middle of right edge.
%
%   Results are saved to 'Cantilever_PTOc_results.mat' and figures are generated.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

fprintf('=== Cantilever Beam - PTOc (Compliance minimization) ===\n');

% Mesh parameters
nelx = 120;      % Number of elements in x-direction
nely = 60;       % Number of elements in y-direction
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

% Boundary conditions for cantilever beam
% Left edge: fixed (both x and y directions)
% Load: point load at middle of right edge (downward)

% Fixed DOFs: left edge all DOFs
fixed_dofs = 1:2*(nely+1); % All DOFs of left edge nodes

% Load: point load at middle of right edge (downward)
mid_right_node = (nelx+1)*(nely+1) - floor(nely/2); % middle of right edge
load_dof = 2*mid_right_node; % y-direction
load_dofs = load_dof;
load_vals = -1; % Downward load

fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Fixed DOFs: %d (left edge)\n', length(fixed_dofs));
fprintf('Load at node %d (dof %d) = %.2f\n', mid_right_node, load_dof, load_vals);
fprintf('Target volume fraction: %.2f\n', volume_fraction);

% Run PTOc
tic;
[rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, plot_flag);
time_elapsed = toc;

% Save results
save('Cantilever_PTOc_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'volume_fraction', 'time_elapsed');

% Plot final design with compliance
figure('Position', [100, 100, 800, 600]);
subplot(2,2,1);
imagesc(rho_opt); axis equal tight; colorbar;
title(sprintf('Cantilever PTOc Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
xlabel('x'); ylabel('y');

% Compute compliance field for final design
[U, K_global] = FEA_analysis(nelx, nely, rho_opt, p, E0, nu, load_dofs, load_vals, fixed_dofs);
C = compute_compliance(nelx, nely, rho_opt, p, E0, nu, U, K_global);
subplot(2,2,2);
imagesc(C); axis equal tight; colorbar;
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

sgtitle('Cantilever Beam - PTOc Results');

% Save figure
saveas(gcf, 'Cantilever_PTOc_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Cantilever_PTOc_results.mat and Cantilever_PTOc_results.png\n');
