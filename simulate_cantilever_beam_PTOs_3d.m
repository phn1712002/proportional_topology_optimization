%% SIMULATE_CANTILEVER_BEAM_PTOS_3D Run 3D PTOs optimization on cantilever beam problem
%
% This script demonstrates the 3D Proportional Topology Optimization for
% stress-constrained minimization (PTOs) on a 3D cantilever beam problem.

clear; close all; clc;

% Add all subdirectories to MATLAB path
add_lib(pwd);

%% 1. Problem Setup
fprintf('=== 3D Cantilever Beam PTOs Optimization ===\n');

% Get boundary conditions for 3D cantilever beam
[fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, design_mask] = cantilever_beam_boundary_3d(false);

% Display problem information
fprintf('Mesh dimensions: %d x %d x %d elements\n', nelx, nely, nelz);
fprintf('Total elements: %d\n', nelx * nely * nelz);
fprintf('Design elements: %d\n', sum(design_mask(:)));

%% 2. Optimization Parameters
% Material properties
p = 3.0;        % SIMP penalty exponent
E0 = 1.0;       % Young's modulus of solid material
nu = 0.3;       % Poisson's ratio

% PTOs parameters
q = 2.0;                % Stress exponent for material distribution
r_min = 1.5;            % Filter radius (in element units)
alpha = 0.3;            % Move limit (history coefficient)
sigma_allow = 0.35;     % Allowable von Mises stress
tau = 0.05;             % Stress tolerance band
coef_inc_dec = 0.05;    % Material increase/decrease coefficient
max_iter = 500;          % Maximum iterations
conv_tol = 1e-3;        % Convergence tolerance

% Initial target material amount (start with full design domain)
TM_init = sum(design_mask(:));  % Start with 100% volume

% Density bounds
rho_min = 1e-3;
rho_max = 1.0;

% Element size (assumed unit cube elements)
dx = 1;
dy = 1;
dz = 1;

% Visualization settings
plot_flag = true;
plot_frequency = 5;

% Problem name for display
problem_name = '3D Cantilever Beam';

%% 3. Initial Density Field
% Uniform initial density (full material)
rho_init = ones(nely, nelx, nelz);
% Apply design mask (set non-design regions to zero)
rho_init(design_mask == 0) = 0;

fprintf('Initial target material amount: %.2f\n', TM_init);
fprintf('Allowable stress: %.3f ± %.1f%%\n', sigma_allow, tau*100);

%% 4. Run PTOs Optimization
fprintf('\n--- Starting 3D PTOs Optimization ---\n');
tic;

[rho_opt, history, sigma_vm, sigma_max, converged, iter] = run_ptos_iteration_3d(...
    rho_init, TM_init, nelx, nely, nelz, p, E0, nu, ...
    load_dofs, load_vals, fixed_dofs, ...
    q, r_min, alpha, sigma_allow, tau, max_iter, ...
    plot_flag, plot_frequency, dx, dy, dz, ...
    rho_min, rho_max, coef_inc_dec, conv_tol, design_mask, problem_name);

elapsed_time = toc;
fprintf('Optimization completed in %.2f seconds\n', elapsed_time);

%% 6. Save Results
% Create results directory if it doesn't exist
if ~exist('results', 'dir')
    mkdir('results');
end

% Save optimization results
results_file = sprintf('results/cantilever_beam_ptos_3d_%dx%dx%d_%.2fstress.mat', nelx, nely, nelz, sigma_allow);
save(results_file, 'rho_opt', 'history', 'sigma_vm', 'sigma_max', 'converged', 'iter', 'nelx', 'nely', 'nelz', ...
    'sigma_allow', 'tau', 'p', 'E0', 'nu', 'q', 'r_min', 'alpha', 'coef_inc_dec', 'elapsed_time');

fprintf('Results saved to: %s\n', results_file);
