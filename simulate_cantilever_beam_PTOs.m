% SIMULATE_CANTILEVER_BEAM_PTOS Run PTOs on cantilever beam problem
%
%   This script sets up the cantilever beam and runs the stress-constrained PTO algorithm.
%   Uses the modular run_ptoc_iteration function for the main optimization loop.
%
%   Results are saved to 'cantilever_beam_PTOs_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== 3D Plate - PTOs (Stress-constrained) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs parameters
q = 2.0;            % Stress exponent for material distribution
r_min = 1.5;        % Filter radius (in element units)
alpha = 0.5;        % Move limit
sigma_allow = 0.35; % Allowable von Mises stress 
tau = 0.05;         % Stress tolerance band
coef_inc_dec = 0.05;% Material increase/decrease coefficient (0->1)
max_iter = 200;     % Maximum iterations 
conv_tol = 1e-4; % Convergence error
plot_flag = true;   % Show plots
plot_frequency = 2; % Frequency new plot

% Boundary conditions for cantilever beam
[fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = cantilever_beam_boundary(false);

% Create initial density
% Start with uniform density at target volume fraction
TM_init = nnz(designer_mask);
rho_init = ones(nely, nelx);

% Apply density bounds
rho_min = 1e-9;
rho_max = 1.0;
rho_init = max(rho_min, min(rho_max, rho_init));

% Use rho_init as starting point
rho = rho_init;

% Run PTOs iteration using the reusable function
[rho_opt, history, sigma_vm, sigma_max, converged, iter] = ...
    run_ptos_iteration(rho, TM_init, nelx, nely, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, sigma_allow, tau, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, ...
                       rho_min, rho_max, coef_inc_dec, conv_tol, designer_mask, '3D Plate');

% Save results
save('cantilever_beam_PTOs_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'sigma_allow', 'tau');

% Save figure
if plot_flag
    saveas(gcf, 'cantilever_beam_PTOs_results.png');
end

fprintf('\n=== Simulation Complete ===\n');
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to cantilever_beam_PTOs_results.mat and cantilever_beam_PTOs_results.png\n');

% Display summary
fprintf('\n=== Problem Summary ===\n');
fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Material: E0=%.1f, nu=%.1f, p=%.1f\n', E0, nu, p);
fprintf('PTOs parameters: q=%.1f, r_min=%.1f, alpha=%.1f\n', q, r_min, alpha);
fprintf('Stress constraint: sigma_allow=%.1f, tau=%.1f\n', sigma_allow, tau);
