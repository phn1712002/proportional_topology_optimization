clear; close all; clc;

% Add all subdirectories to MATLAB path
add_lib(pwd);

%% 1. Problem Setup
fprintf('=== simulate_PTOc Optimization ===\n');

% Get boundary conditions for simulate_PTOc
[fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, design_mask] = l_bracket_3d_boundary(false); % Select the desired load model.

% Display problem information
fprintf('Mesh dimensions: %d x %d x %d elements\n', nelx, nely, nelz);
fprintf('Total elements: %d\n', nelx * nely * nelz);
fprintf('Design elements: %d\n', sum(design_mask(:)));

%% 2. Optimization Parameters
% Material properties
p = 3.0;        % SIMP penalty exponent
E0 = 1.0;       % Young's modulus of solid material
nu = 0.3;       % Poisson's ratio

% PTOc parameters
q = 1.5;        % Compliance exponent for material distribution
r_min = 1.5;    % Filter radius (in element units)
alpha = 0.3;    % Move limit (history coefficient)
max_iter = 50;  % Maximum iterations
conv_tol = 1e-3; % Convergence tolerance

% Volume fraction (target material amount)
volume_fraction = 0.3;  % 30% volume fraction
TM = volume_fraction * sum(design_mask(:));  % Target material amount

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
problem_name = 'simulate_PTOc';

%% 3. Initial Density Field
% Uniform initial density matching volume fraction
rho_init = volume_fraction * ones(nely, nelx, nelz);
% Apply design mask (set non-design regions to zero)
rho_init(design_mask == 0) = 0;

fprintf('Initial volume fraction: %.2f\n', volume_fraction);
fprintf('Target material amount: %.2f\n', TM);

%% 4. Run PTOc Optimization
fprintf('\n--- Starting 3D PTOc Optimization ---\n');
tic;

[rho_opt, history, converged, iter] = run_ptoc_iteration_3d(...
    rho_init, TM, nelx, nely, nelz, p, E0, nu, ...
    load_dofs, load_vals, fixed_dofs, ...
    q, r_min, alpha, max_iter, ...
    plot_flag, plot_frequency, dx, dy, dz, ...
    rho_min, rho_max, conv_tol, design_mask, problem_name);

elapsed_time = toc;
fprintf('Optimization completed in %.2f seconds\n', elapsed_time);

%% 5. Results Analysis
fprintf('\n=== Optimization Results ===\n');
fprintf('Final iteration: %d\n', iter);
fprintf('Converged: %s\n', string(converged));
fprintf('Final compliance: %.4e\n', history.compliance(end));
fprintf('Final volume: %.4f (target: %.4f)\n', history.volume(end), TM);
fprintf('Final volume fraction: %.4f\n', history.volume(end) / sum(design_mask(:)));

%% 6. Save Results
% Create results directory if it doesn't exist
if ~exist('results', 'dir')
    mkdir('results');
end

% Save optimization results
results_file = sprintf('results/ptoc_3d_%dx%dx%d_%.2fvol.mat', nelx, nely, nelz, volume_fraction);
save(results_file, 'rho_opt', 'history', 'converged', 'iter', 'nelx', 'nely', 'nelz', ...
    'volume_fraction', 'TM', 'p', 'E0', 'nu', 'q', 'r_min', 'alpha', 'elapsed_time');

fprintf('Results saved to: %s\n', results_file);

