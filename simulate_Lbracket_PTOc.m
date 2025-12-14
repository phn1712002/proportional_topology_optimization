% SIMULATE_LBRACKET_PTOC Run PTOc on L-bracket problem
%
%   This script sets up the L-bracket and runs the compliance minimization PTO algorithm.
%   Uses the modular run_ptoc_iteration function for the main optimization loop.
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
q = 2.0;                % Compliance exponent for material distribution
r_min = 1.25;            % Filter radius (in element units)
alpha = 0.5;            % Move limit
volume_fraction = 0.4;  % Target volume fraction (adjusted for cutout)
max_iter = 300;         % Maximum iterations
conv_tol = 1e-4; % Convergence error
plot_flag = true;       % Show plots
plot_frequency =10;     % Frequency of new plots

% Density bounds (consistent with PTOc documentation)
rho_min = 1e-9;
rho_max = 1.0;

% Boundary conditions for L-bracket
[fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(false);
fprintf('Target volume fraction: %.2f\n', volume_fraction);

% Create initial density with cutout (void region)
% Note: FEA_analysis expects rho to be nely x nelx
rho_init = ones(nely, nelx);
% Set cutout region to minimum density (top-right corner)
% The cutout is from (nelx-cutout_x+1):nelx in x-direction
% and (nely-cutout_y+1):nely in y-direction
cutout_x_start = nelx - cutout_x + 1;
cutout_y_start = nely - cutout_y + 1;
rho_init(cutout_y_start:nely, cutout_x_start:nelx) = rho_min;

% Target material (fixed) - adjust for cutout area
total_area = nelx * nely;
cutout_area = cutout_x * cutout_y;
active_area = total_area - cutout_area;
TM = volume_fraction * active_area;

fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Cutout: %d x %d elements (top-right corner)\n', cutout_x, cutout_y);
fprintf('Active area: %d elements (excluding cutout)\n', active_area);
fprintf('Target material (TM): %.2f (%.1f%% of active area)\n', TM, volume_fraction*100);

% Use rho_init as starting point
rho = rho_init;

% Run PTOc optimization using modular function
[rho_opt, history, converged, final_iter] = run_ptoc_iteration(...
    rho, TM, nelx, nely, p, E0, nu, ...
    load_dofs, load_vals, fixed_dofs, ...
    q, r_min, alpha, max_iter, ...
    plot_flag, plot_frequency, dx, dy, ...
    rho_min, rho_max, conv_tol, 'L-Bracket');

% Compute final metrics
final_compliance = history.compliance(end);
final_volume = history.volume(end);
final_volume_fraction = final_volume / active_area;  % Volume fraction relative to active area
total_volume_fraction = final_volume / total_area;   % Volume fraction relative to total domain

% Save results (save the final optimized density, not intermediate rho_opt)
save('Lbracket_PTOc_results.mat', 'rho_opt', 'history', 'nelx', 'nely', ...
    'p', 'q', 'r_min', 'alpha', 'volume_fraction', 'cutout_x', 'cutout_y', ...
    'final_compliance', 'final_volume', 'final_volume_fraction', 'total_volume_fraction', ...
    'converged', 'final_iter');

% Save figure
if plot_flag
    saveas(gcf, 'Lbracket_PTOc_results.png');
end

fprintf('\n=== Simulation Complete ===\n');
fprintf('Converged: %s (after %d iterations)\n', string(converged), final_iter);
fprintf('Final compliance: %.4f\n', final_compliance);
fprintf('Final volume: %.2f (target: %.2f)\n', final_volume, TM);
fprintf('Final volume fraction (active area): %.4f (target: %.2f)\n', final_volume_fraction, volume_fraction);
fprintf('Final volume fraction (total domain): %.4f\n', total_volume_fraction);
fprintf('Results saved to Lbracket_PTOc_results.mat and Lbracket_PTOc_results.png\n');

% Display final design
figure(2);
clf;
imagesc(rho_opt); axis equal tight; colorbar;
title(sprintf('L-Bracket PTOc Final Design (Iteration %d)', final_iter));
axis xy;
xlabel('x'); ylabel('y');
colormap(gray);
drawnow;
