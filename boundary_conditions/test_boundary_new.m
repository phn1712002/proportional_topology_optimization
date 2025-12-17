function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = test_boundary_new(plot_flag)
%% PLATE_3D_BOUNDARY Define boundary conditions for a 3D wall-like structure.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, NELZ, DESIGNER_MASK] = PLATE_3D_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a 3D wall topology optimization problem.
%   The structure is fixed on the bottom face (z=0) and subjected to a distributed load
%   on the middle of the top-back edge (z=max, y=max).
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of the boundary conditions.
%               Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom (DOFs) that are fixed (zero displacement).
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Magnitudes of the corresponding loads.
%   nelx          - Number of elements in the x-direction.
%   nely          - Number of elements in the y-direction.
%   nelz          - Number of elements in the z-direction.
%   designer_mask - Logical matrix (nely x nelx x nelz) indicating the active design domain.

    % Set default value for plot_flag if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION ---
    % Swapping dimensions to match the "wall" visualization
    nelx = 24;                 % Number of elements in x-direction (width)
    nely = 12;                 % Number of elements in y-direction (thickness)
    nelz = 8;                  % Number of elements in z-direction (height)
    load_val = -1;             % Total downward load
    
    % Load distribution parameters (for the top edge)
    load_area_x = 4;           % Load distributed over a width of X elements

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % --- DEFINE DESIGN DOMAIN ---
    designer_mask = true(nely, nelx, nelz);

    % --- NODE AND DOF NUMBERING CONVENTION (3D) ---
    % Based on the original code's formula, the numbering is:
    % y-index (i) varies fastest, then x-index (j), then z-index (k).
    % Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
    % Degrees of freedom for node 'n': 3*n-2 (x), 3*n-1 (y), 3*n (z)

    % --- FIXED DOFs (MODIFIED) ---
    % Fixed face: z=0 (bottom face, k=1)
    [I, J] = meshgrid(1:num_nodes_y, 1:num_nodes_x); % Grid of y and x node indices
    
    % Node IDs for the bottom face (k=1)
    k_index = 1;
    bottom_face_nodes = (k_index-1)*(num_nodes_y*num_nodes_x) + (J(:)-1)*num_nodes_y + I(:);
    
    % Get all three DOFs (Ux, Uy, Uz) for each node on the face
    dof_x = 3 * bottom_face_nodes - 2;
    dof_y = 3 * bottom_face_nodes - 1;
    dof_z = 3 * bottom_face_nodes;
    
    fixed_dofs = sort([dof_x; dof_y; dof_z]);

    % --- LOAD APPLICATION (MODIFIED) ---
    % Distributed load on the center of the top-back edge (z=max, y=max)
    mid_x = floor(num_nodes_x / 2) + 1;
    
    % Ensure load area does not exceed plate dimensions
    half_x = floor(min(load_area_x, nelx) / 2);
    
    load_nodes_x = (mid_x - half_x) : (mid_x + half_x); % Range of node indices in x-dir

    % Fixed indices for the top-back edge
    y_index = num_nodes_y; % y=max (back edge)
    z_index = num_nodes_z; % z=max (top edge)

    % Find node IDs along this edge
    top_edge_nodes = (z_index-1)*(num_nodes_y*num_nodes_x) + (load_nodes_x-1)*num_nodes_y + y_index;
    
    % The load is applied in the z-direction (vertical, downward)
    load_dofs = 3 * top_edge_nodes;
    
    % Distribute the total load evenly among all loaded DOFs
    num_load_points = length(load_dofs);
    if num_load_points == 0
        error('Load application error: No nodes found for the specified load area. Check dimensions.');
    end
    load_vals = repmat(load_val / num_load_points, 1, num_load_points); % Ensure row vector
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- 3D Wall Configuration ---\n');
    fprintf('Mesh: %d (width) x %d (thick) x %d (height) elements\n', nelx, nely, nelz);
    fprintf('Total DOFs: %d\n', 3 * num_nodes_x * num_nodes_y * num_nodes_z);
    fprintf('Fixed DOFs count: %d (Fixed face at z=0)\n', length(fixed_dofs));
    fprintf('Load: Distributed load on top-back edge (z=max, y=max)\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Load applied over %d nodes (width: %d elements)\n', ...
            num_load_points, length(load_nodes_x)-1);
    
    % Visualize boundary conditions if requested
    if plot_flag
        % NOTE: The visualization function might swap axes for better viewing.
        % The labels on the plot (X, Y, Z) correspond to the node indices.
        visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
    end
end