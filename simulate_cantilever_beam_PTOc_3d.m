%% SIMULATE_MBB_BEAM_PTOC_3D Run 3D PTOc optimization on MBB beam problem
%
% This script demonstrates the 3D Proportional Topology Optimization for
% compliance minimization (PTOc) on a 3D MBB beam problem.

clear; close all; clc;

% Add all subdirectories to MATLAB path
add_lib(pwd);

%% 1. Problem Setup
fprintf('=== 3D MBB Beam PTOc Optimization ===\n');

% Get boundary conditions for 3D MBB beam
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
dx = 10;
dy = 10;
dz = 10;

% Visualization settings
plot_flag = true;
plot_frequency = 5;

% Problem name for display
problem_name = '3D Cantilever Beam';

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

% Final visualization
figure('Name', 'Final 3D Cantilever Beam Optimization Results', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);

% Subplot 1: Final density distribution (middle slice)
subplot(2,3,1);
mid_z = ceil(nelz/2);
imagesc(squeeze(rho_opt(:,:,mid_z))); axis equal tight; colorbar;
title(sprintf('Final Density (z=%d slice)', mid_z));
xlabel('x'); ylabel('y');
colormap(jet);

% Subplot 2: 3D isosurface
subplot(2,3,2);
if nelz > 1
    [X,Y,Z] = meshgrid(1:nelx, 1:nely, 1:nelz);
    p = patch(isosurface(X, Y, Z, rho_opt, 0.5));
    isonormals(X, Y, Z, rho_opt, p);
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    daspect([1 1 1]);
    view(3); axis tight;
    camlight; lighting gouraud;
    title('3D Isosurface (density=0.5)');
    xlabel('x'); ylabel('y'); zlabel('z');
else
    imagesc(rho_opt(:,:,1)); axis equal tight; colorbar;
    title('Final Density');
    xlabel('x'); ylabel('y');
end

% Subplot 3: Compliance history
subplot(2,3,3);
plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5);
grid on;
title('Compliance History');
xlabel('Iteration');
ylabel('Compliance');

% Subplot 4: Volume history
subplot(2,3,4);
plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5);
hold on;
yline(TM, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Target');
grid on;
title('Volume History');
xlabel('Iteration');
ylabel('Volume');
legend('Volume', 'Target');

% Subplot 5: Density change history
subplot(2,3,5);
semilogy(history.iteration, history.change, 'm-d', 'LineWidth', 1.5);
hold on;
yline(conv_tol, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Tolerance');
grid on;
title('Density Change History (log scale)');
xlabel('Iteration');
ylabel('Max Density Change');
legend('Change', 'Tolerance');

% Subplot 6: Volume fraction vs compliance
subplot(2,3,6);
volume_fraction_history = history.volume / sum(design_mask(:));
plot(volume_fraction_history, history.compliance, 'g-s', 'LineWidth', 1.5);
grid on;
title('Volume Fraction vs Compliance');
xlabel('Volume Fraction');
ylabel('Compliance');
xlim([0, 1]);

sgtitle('3D MBB Beam PTOc Optimization Results', 'FontSize', 14, 'FontWeight', 'bold');

%% 6. Save Results
% Create results directory if it doesn't exist
if ~exist('results', 'dir')
    mkdir('results');
end

% Save optimization results
results_file = sprintf('results/cantilever_beam_ptoc_3d_%dx%dx%d_%.2fvol.mat', nelx, nely, nelz, volume_fraction);
save(results_file, 'rho_opt', 'history', 'converged', 'iter', 'nelx', 'nely', 'nelz', ...
    'volume_fraction', 'TM', 'p', 'E0', 'nu', 'q', 'r_min', 'alpha', 'elapsed_time');

fprintf('Results saved to: %s\n', results_file);

%% 7. Export STL file for 3D printing (optional)
% Define parameters for the STL export
stl_filename = sprintf('results/cantilever_3d_%dx%dx%d_vol%.2f.stl', ...
                       nelx, nely, nelz, volume_fraction);
element_dims = [dx, dy, dz]; % Assuming unit element size, e.g., [dx, dy, dz]
iso_threshold = 0.5;

% Call the dedicated export function
export_to_stl_from_density(rho_final, stl_filename, ...
                           'Threshold', iso_threshold, ...
                           'ElementSize', element_dims);

fprintf('\n=== 3D Cantilever Beam Optimization Complete ===\n');