% SIMULATE_UBEAM_PTOC Run PTOc on U-shaped beam problem
%
%   This script sets up the U-shaped beam and runs the compliance minimization
%   PTO algorithm. It uses the modular run_ptoc_iteration function for the
%   main optimization loop.
%
%   Results are saved to 'Ubeam_PTOc_results.mat' and figures are generated.

% --- INITIALIZATION ---
clear; close all; clc;

% Add any necessary libraries to the path
% add_lib(pwd); % Uncomment if you have a lib folder

% --- MAIN SCRIPT ---
fprintf('=== C-Shaped Beam - PTOc (Compliance minimization) ===\n');

% --- MESH & MATERIAL PARAMETERS ---
dx = 1; dy = 1;      % Element size (assuming unit size)
E0 = 1.0;            % Young's modulus of solid material
nu = 0.3;            % Poisson's ratio
p = 3;               % SIMP penalty exponent

% --- PTOC ALGORITHM PARAMETERS ---
q = 2.0;                % Compliance exponent for material distribution
r_min = 1.5;            % Filter radius (in element units)
alpha = 0.5;            % Move limit
volume_fraction = 0.35; % Target volume fraction of the designable area
max_iter = 200;         % Maximum number of iterations
conv_tol = 1e-4;        % Convergence tolerance
plot_flag = true;       % Enable real-time plotting of results
plot_frequency = 5;     % Update plot every 5 iterations

% --- DENSITY BOUNDS ---
rho_min = 1e-9;         % Minimum density to avoid singularity
rho_max = 1.0;          % Maximum density (solid material)

% --- SETUP BOUNDARY CONDITIONS ---
% Get BCs and design domain from the U-beam function
[fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = c_beam_boundary(false);

% --- INITIALIZATION FOR OPTIMIZATION ---
% Create initial density with cutout (void region)
% Note: FEA_analysis expects rho to be nely x nelx
rho_init = ones(nely, nelx);
rho_init = max(rho_min, min(rho_max, rho_init));

% Target material (fixed) - adjust for cutout area
total_area = nnz(designer_mask);
TM = volume_fraction * total_area;

% Use rho_init as starting point
rho = rho_init;

% --- RUN OPTIMIZATION ---
% Use the generic iteration function to perform the optimization
[rho_opt, history, converged, final_iter] = run_ptoc_iteration(...
    rho, TM, nelx, nely, p, E0, nu, ...
    load_dofs, load_vals, fixed_dofs, ...
    q, r_min, alpha, max_iter, ...
    plot_flag, plot_frequency, dx, dy, ...
    rho_min, rho_max, conv_tol, designer_mask, 'C-Shaped Beam');

% --- POST-PROCESSING & SAVING RESULTS ---
% Compute final metrics
final_compliance = history.compliance(end);
final_volume = history.volume(end);

% Calculate volume fractions relative to both active and total areas
total_area = nelx * nely;
final_volume_fraction_active = final_volume / active_area;
final_volume_fraction_total = final_volume / total_area;

% Save results to a .mat file
save('Ubeam_PTOc_results.mat', 'rho_opt', 'history', 'nelx', 'nely', ...
    'p', 'q', 'r_min', 'alpha', 'volume_fraction', ...
    'final_compliance', 'final_volume', 'final_volume_fraction_active', ...
    'final_volume_fraction_total', 'converged', 'final_iter');

% Save the final figure
if plot_flag
    saveas(gcf, 'Ubeam_PTOc_results.png');
end

% --- DISPLAY FINAL SUMMARY ---
fprintf('\n=== Simulation Complete ===\n');
fprintf('Converged: %s (after %d iterations)\n', string(converged), final_iter);
fprintf('Final compliance: %.4f\n', final_compliance);
fprintf('Final volume: %.2f (target: %.2f)\n', final_volume, TM);
fprintf('Final volume fraction (active area): %.4f (target: %.2f)\n', final_volume_fraction_active, volume_fraction);
fprintf('Final volume fraction (total domain): %.4f\n', final_volume_fraction_total);
fprintf('Results saved to Ubeam_PTOc_results.mat and Ubeam_PTOc_results.png\n');

% Display final design in a new figure window
figure('Name', 'U-Beam Final Design', 'NumberTitle', 'off');
imagesc(1 - rho_opt); % Invert colors for better visualization (black=solid)
axis equal tight;
title(sprintf('U-Beam PTOc Final Design (Iteration %d)', final_iter));
axis off;
colormap(gray);
drawnow;