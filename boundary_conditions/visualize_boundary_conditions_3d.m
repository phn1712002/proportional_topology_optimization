function fig_handle = visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask)
% VISUALIZE_BOUNDARY_CONDITIONS_3D Plot the 3D design domain and boundary conditions.
%
%   Creates a 3D scatter plot showing the active elements of the design
%   domain, the nodes with fixed DOFs, and the nodes where loads are applied.
%
% Inputs:
%   nelx, nely, nelz - Number of elements in x, y, z directions
%   fixed_dofs     - Vector of global DOFs that are fixed
%   load_dofs      - Vector of global DOFs where loads are applied
%   designer_mask  - (Optional) A 3D logical array of size (nely x nelx x nelz).
%                    'true' or 1 indicates an active element that can be optimized.
%                    'false' or 0 indicates a passive/void element.
%                    If not provided, the entire domain is assumed active.
%
% Outputs:
%   fig_handle     - Handle to the created figure (optional)
%
% Example:
%   % 1. Full domain
%   visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs);
%
%   % 2. With a custom mask (e.g., a hollow box)
%   mask = ones(nely, nelx, nelz);
%   mask(5:end-5, 5:end-5, :) = 0; % Create a hole
%   visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, mask);

% --- 1. Handle optional designer_mask ---
if nargin < 6 || isempty(designer_mask)
    % If mask is not provided or is empty, assume the entire domain is active.
    designer_mask = true(nely, nelx, nelz);
end

% Ensure mask is logical for indexing
active_mask = logical(designer_mask);

% --- 2. Create a new figure ---
fig_handle = figure('Name', '3D Boundary Conditions', 'NumberTitle', 'off');
hold on;

% --- 3. Plot Active Design Domain ---
% Create a full grid of element center coordinates
[X, Y, Z] = meshgrid(1.5:(nelx+0.5), 1.5:(nely+0.5), 1.5:(nelz+0.5));

% Use the mask to select only the coordinates of active elements
X_active = X(active_mask);
Y_active = Y(active_mask);
Z_active = Z(active_mask);

% Plot only the active elements
scatter3(X_active, Y_active, Z_active, 10, 'b', 'filled', 'DisplayName', 'Active Design Domain');

% --- 4. Identify and Plot Fixed Nodes ---
fixed_nodes = unique(ceil(fixed_dofs / 3));
node_grid_size = [nely + 1, nelx + 1, nelz + 1];

% Convert linear node indices to 3D subscript coordinates.
% Note: ind2sub returns I for 1st dim (y), J for 2nd (x), K for 3rd (z).
[I_fixed, J_fixed, K_fixed] = ind2sub(node_grid_size, fixed_nodes);
scatter3(J_fixed, I_fixed, K_fixed, 60, 'g', 'filled', 'DisplayName', 'Fixed Nodes');

% --- 5. Identify and Plot Load Nodes ---
load_nodes = unique(ceil(load_dofs / 3));
[I_load, J_load, K_load] = ind2sub(node_grid_size, load_nodes);
scatter3(J_load, I_load, K_load, 60, 'r', 'filled', 'DisplayName', 'Load Nodes');

% --- 6. Finalize Plot Appearance ---
xlabel('X-direction (node index)');
ylabel('Y-direction (node index)');
zlabel('Z-direction (node index)');
title('3D Design Domain and Boundary Conditions');
legend('show', 'Location', 'northeast');
axis equal;
grid on;
view(3);
hold off;

% Set axes limits to be slightly larger than the node grid
xlim([0, nelx + 2]);
ylim([0, nely + 2]);
zlim([0, nelz + 2]);

end