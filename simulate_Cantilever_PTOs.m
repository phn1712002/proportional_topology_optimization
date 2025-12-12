% SIMULATE_CANTILEVER_PTOS Run PTOs on cantilever beam problem
%
%   This script sets up the cantilever beam and runs the
%   stress-constrained PTO algorithm.
%
%   Mesh: 120 x 60 elements
%   Boundary conditions: fixed left edge, point load at middle of right edge.
%
%   Results are saved to 'Cantilever_PTOs_results.mat' and figures are generated.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

fprintf('=== Cantilever Beam - PTOs (Stress-constrained) ===\n');

% Mesh parameters
nelx = 120;      % Number of elements in x-direction
nely = 60;       % Number of elements in y-direction
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs parameters
q = 1.0;         % Stress exponent for material distribution
r_min = 2.0;     % Filter radius (in element units)
alpha = 0.3;     % Move limit
sigma_allow = 100; % Allowable von Mises stress
tau = 0.05;      % Stress tolerance band
max_iter = 300;  % Maximum iterations
TM_init = 0.4 * nelx * nely; % Initial target material (40% volume fraction)
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

% Run PTOs
tic;
[rho_opt, history] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, plot_flag);
time_elapsed = toc;

% Save results
save('Cantilever_PTOs_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'sigma_allow', 'tau', 'time_elapsed');

% Plot final design with stress
figure('Position', [100, 100, 800, 600]);
subplot(2,2,1);
imagesc(rho_opt); axis equal tight; colorbar;
title(sprintf('Cantilever PTOs Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
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

sgtitle('Cantilever Beam - PTOs Results');

% Save figure
saveas(gcf, 'Cantilever_PTOs_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Cantilever_PTOs_results.mat and Cantilever_PTOs_results.png\n');
