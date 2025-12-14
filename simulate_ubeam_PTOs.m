%% SIMULATE_UBEAM_PTOS Run PTOs on U-shaped beam problem
%
%   This script sets up the U-shaped beam and runs the stress-constrained
%   PTO algorithm.
%
%   Results are saved to 'Ubeam_PTOs_results.mat' and figures are generated.

% --- INITIALIZATION ---
clear; close all; clc;

% Add any necessary libraries to path
% add_lib(pwd); % Uncomment if you have a custom library function

% --- MAIN SCRIPT ---
fprintf('=== U-Shaped Beam - PTOs (Stress-constrained) ===\n');

% --- SIMULATION PARAMETERS ---

% Mesh element size (assuming unit dimensions for FEA)
dx = 1; dy = 1;

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs algorithm parameters
q = 2.0;                % Stress exponent for material distribution
r_min = 1.5;            % Filter radius (in element units)
alpha = 0.5;            % Move limit
sigma_allow = 1.5;      % Allowable von Mises stress
tau = 0.05;             % Stress tolerance band
coef_inc_dec = 0.05;    % Material increase/decrease coefficient (0->1)
max_iter = 300;         % Maximum iterations
conv_tol = 1e-4;        % Convergence tolerance
plot_flag = true;       % Show plots during iteration
plot_frequency = 5;     % Frequency of plot updates

% Density bounds
rho_min = 1e-9;
rho_max = 1.0;

% --- PROBLEM SETUP ---

% Load boundary conditions and design domain for U-beam
% Pass 'false' to prevent the BC function from plotting its own figure
[fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = u_beam_boundary(false);

% --- INITIALIZATION FOR OPTIMIZATION ---
% Create initial density
% Start with uniform density at target volume fraction
TM_init = nnz(designer_mask);
rho_init = ones(nely, nelx);

% Use rho_init as starting point
rho = rho_init;

% --- RUN OPTIMIZATION ---
% Run PTOs iteration using the reusable function
fprintf('\nStarting PTOs optimization...\n');
[rho_opt, history, sigma_vm, ~, ~, iter] = ...
    run_ptos_iteration(rho, TM_init, nelx, nely, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, sigma_allow, tau, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, ...
                       rho_min, rho_max, coef_inc_dec, conv_tol, designer_mask, 'U-beam');

% --- SAVE AND DISPLAY RESULTS ---

% Save results to a .mat file
results_filename_mat = 'Ubeam_PTOs_results.mat';
save(results_filename_mat, 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', ...
     'r_min', 'alpha', 'sigma_allow', 'tau', 'designer_mask');

% Save the final figure
results_filename_png = 'Ubeam_PTOs_results.png';
saveas(gcf, results_filename_png);

% Calculate final metrics
num_design_elements = sum(designer_mask(:));
final_volume_fraction = sum(rho_opt(designer_mask)) / num_design_elements;
final_max_stress = max(sigma_vm(:));
final_compliance = history.compliance(end);

fprintf('\n=== Simulation Complete (Converged in %d iterations) ===\n', iter);
fprintf('Final volume fraction (in design domain): %.4f\n', final_volume_fraction);
fprintf('Final max von Mises stress: %.4f\n', final_max_stress);
fprintf('Final compliance: %.4f\n', final_compliance);
fprintf('Results saved to %s and %s\n', results_filename_mat, results_filename_png);

% Display a summary of the problem setup
fprintf('\n=== Problem Summary ===\n');
fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Total designable elements: %d\n', num_design_elements);
fprintf('Material: E0=%.1f, nu=%.1f, p=%.1f\n', E0, nu, p);
fprintf('PTOs parameters: q=%.1f, r_min=%.2f, alpha=%.1f\n', q, r_min, alpha);
fprintf('Stress constraint: sigma_allow=%.2f, tau=%.2f\n', sigma_allow, tau);