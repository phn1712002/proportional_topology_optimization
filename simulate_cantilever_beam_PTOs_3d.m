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
max_iter = 50;          % Maximum iterations
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

%% 5. Results Analysis
fprintf('\n=== Optimization Results ===\n');
fprintf('Final iteration: %d\n', iter);
fprintf('Converged: %s\n', string(converged));
fprintf('Final compliance: %.4e\n', history.compliance(end));
fprintf('Final volume: %.4f (initial: %.4f)\n', history.volume(end), TM_init);
fprintf('Final volume fraction: %.4f\n', history.volume(end) / sum(design_mask(:)));
fprintf('Final max stress: %.4f (allowable: %.4f)\n', sigma_max, sigma_allow);
fprintf('Stress constraint satisfied: %s\n', string(sigma_max <= (1+tau)*sigma_allow));

% Final visualization
figure('Name', 'Final 3D Cantilever Beam PTOs Optimization Results', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);

% Subplot 1: Final density distribution (middle slice)
subplot(2,3,1);
mid_z = ceil(nelz/2);
imagesc(squeeze(rho_opt(:,:,mid_z))); axis equal tight; colorbar;
title(sprintf('Final Density (z=%d slice)', mid_z));
xlabel('x'); ylabel('y');
colormap(jet);

% Subplot 2: Final stress distribution (middle slice)
subplot(2,3,2);
imagesc(squeeze(sigma_vm(:,:,mid_z))); axis equal tight; colorbar;
title(sprintf('Final Stress (z=%d slice)', mid_z));
xlabel('x'); ylabel('y');
colormap(jet);

% Subplot 3: 3D isosurface
subplot(2,3,3);
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

% Subplot 4: Compliance history
subplot(2,3,4);
plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5);
grid on;
title('Compliance History');
xlabel('Iteration');
ylabel('Compliance');

% Subplot 5: Volume and target material history
subplot(2,3,5);
plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5);
hold on;
plot(history.iteration, history.TM, 'g--', 'LineWidth', 1.5);
grid on;
title('Volume and Target Material History');
xlabel('Iteration');
ylabel('Material Amount');
legend('Actual Volume', 'Target Material', 'Location', 'best');

% Subplot 6: Max stress history with allowable band
subplot(2,3,6);
plot(history.iteration, history.sigma_max, 'g-s', 'LineWidth', 1.5);
hold on;
yline(sigma_allow*(1-tau), 'r--', 'Lower bound', 'LineWidth', 1.5);
yline(sigma_allow*(1+tau), 'r--', 'Upper bound', 'LineWidth', 1.5);
yline(sigma_allow, 'k-', 'Allowable stress', 'LineWidth', 1.5);
grid on;
title('Max Stress History');
xlabel('Iteration');
ylabel('Max Stress');
legend('Max Stress', 'Lower bound', 'Upper bound', 'Allowable');

sgtitle('3D Cantilever Beam PTOs Optimization Results', 'FontSize', 14, 'FontWeight', 'bold');

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
