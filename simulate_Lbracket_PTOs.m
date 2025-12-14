% SIMULATE_LBRACKET_PTOS Run PTOs on L-bracket problem
%
%   This script sets up the L-bracket and runs the stress-constrained PTO algorithm.
%
%   Results are saved to 'Lbracket_PTOs_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== L-bracket - PTOs (Stress-constrained) ===\n');

% Mesh parameters
dx = 1; dy = 1;  % Element size

% Material properties
E0 = 1.0;        % Young's modulus of solid
nu = 0.3;        % Poisson's ratio
p = 3;           % SIMP penalty exponent

% PTOs parameters
q = 2.0;                % Stress exponent for material distribution
r_min = 1.25;           % Filter radius (in element units)
alpha = 0.5;            % Move limit
sigma_allow = 2.5;     % Allowable von Mises stress
tau = 0.05;             % Stress tolerance band
coef_inc_dec = 0.05;    % Material increase/decrease coefficient (0->1)
max_iter = 300;         % Maximum iterations
conv_tol = 1e-4; % Convergence error
plot_flag = true;       % Show plots
plot_frequency = 2;     % Frequency new plot

% Density bounds
rho_min = 1e-9;
rho_max = 1.0;

% Boundary conditions for L-bracket
[fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(false);

% Create initial density with cutout (void region)
% Note: FEA_analysis expects rho to be nely x nelx
rho_init = ones(nely, nelx);
rho_init = max(rho_min, min(rho_max, rho_init));
% Set cutout region
design_mask = ones(nely, nelx);
cutout_x_start = nelx - cutout_x + 1;
cutout_y_start = nely - cutout_y + 1;
design_mask(cutout_y_start:nely, cutout_x_start:nelx) = 0;
rho_init(design_mask == 0) = 0;

% Target material (adjustable) - adjust for cutout area
total_area = nelx * nely;
cutout_area = cutout_x * cutout_y;
active_area = total_area - cutout_area;
TM_init = active_area;

% Use rho_init as starting point
rho = rho_init;

% Run PTOs iteration using the reusable function
[rho_opt, history, sigma_vm, sigma_max, converged, iter] = ...
    run_ptos_iteration(rho, TM_init, nelx, nely, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, sigma_allow, tau, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, ...
                       rho_min, rho_max, coef_inc_dec, conv_tol, 'L-bracket');

% Save results
save('Lbracket_PTOs_results.mat', 'rho_opt', 'history', 'nelx', 'nely', 'p', 'q', 'r_min', 'alpha', 'sigma_allow', 'tau', 'cutout_x', 'cutout_y');

% Save figure
saveas(gcf, 'Lbracket_PTOs_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to Lbracket_PTOs_results.mat and Lbracket_PTOs_results.png\n');

% Display summary
fprintf('\n=== Problem Summary ===\n');
fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Cutout: %d x %d elements (top-right corner)\n', cutout_x, cutout_y);
fprintf('Active area: %d elements\n', active_area);
fprintf('Material: E0=%.1f, nu=%.1f, p=%.1f\n', E0, nu, p);
fprintf('PTOs parameters: q=%.1f, r_min=%.1f, alpha=%.1f\n', q, r_min, alpha);
fprintf('Stress constraint: sigma_allow=%.1f, tau=%.1f\n', sigma_allow, tau);
