function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = plate_3d_boundary(plot_flag)
%% PLATE_3D_BOUNDARY Define boundary conditions for a 3D plate/block problem.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, NELZ, DESIGNER_MASK] = PLATE_3D_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a 3D plate topology optimization problem.
%   The plate is fixed on one face and subjected to a distributed load on the opposite face.
%   This problem tests the 3D capabilities of the optimization algorithm.
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
    % Using lightweight mesh for faster testing (similar to cantilever_beam_3d_boundary)
    nelx = 12*2;                 % Number of elements in x-direction (length)
    nely = 6*2;                  % Number of elements in y-direction (height)
    nelz = 4*2;                  % Number of elements in z-direction (thickness)
    load_val = -1;               % Total downward load
    
    % Load distribution parameters
    load_area_y = 4;            % Load distributed over a height of Y elements
    load_area_z = 3;            % Load distributed over a thickness of Z elements

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % --- DEFINE DESIGN DOMAIN ---
    % For a standard plate, the entire domain is active.
    designer_mask = true(nely, nelx, nelz);

    % --- NODE AND DOF NUMBERING CONVENTION (3D) ---
    % The mesh contains (nelx+1) x (nely+1) x (nelz+1) nodes.
    % Nodes are numbered with z varying fastest, then y, then x.
    % Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
    % where i = y-index (1 to ny+1), j = x-index (1 to nx+1), k = z-index (1 to nz+1)
    % Degrees of freedom for node 'n': 3*n-2 (x), 3*n-1 (y), 3*n (z)

    % --- FIXED DOFs ---
    % Fixed face: x=0 (left face, j=1)
    [I, K] = meshgrid(1:num_nodes_y, 1:num_nodes_z); % Grid of y and z node indices
    
    % Node IDs for left face (j=1)
    left_face_nodes = (K(:)-1)*(num_nodes_y*num_nodes_x) + (1-1)*num_nodes_y + I(:);
    
    % Get all three DOFs (Ux, Uy, Uz) for each node on the face
    dof_x = 3 * left_face_nodes - 2;
    dof_y = 3 * left_face_nodes - 1;
    dof_z = 3 * left_face_nodes;
    
    fixed_dofs = sort([dof_x; dof_y; dof_z]);

    % --- LOAD APPLICATION ---
    % Distributed load on the opposite face (x=max, j=num_nodes_x)
    % Define the patch of nodes where the load is applied
    mid_y = floor(num_nodes_y / 2) + 1;
    mid_z = floor(num_nodes_z / 2) + 1;
    
    % Ensure load area does not exceed plate dimensions
    half_y = floor(min(load_area_y, nely) / 2);
    half_z = floor(min(load_area_z, nelz) / 2);
    
    load_nodes_y = (mid_y - half_y) : (mid_y + half_y);
    load_nodes_z = (mid_z - half_z) : (mid_z + half_z);

    % Create a grid of node indices for the load patch
    [I_load, K_load] = meshgrid(load_nodes_y, load_nodes_z);

    % Find node IDs on the right face (j=num_nodes_x)
    right_face_nodes = (K_load(:)-1)*(num_nodes_y*num_nodes_x) + (num_nodes_x-1)*num_nodes_y + I_load(:);
    
    % The load is applied in the y-direction (vertical, downward)
    load_dofs = 3 * right_face_nodes - 1;
    
    % Distribute the total load evenly among all loaded DOFs
    num_load_points = length(load_dofs);
    if num_load_points == 0
        error('Load application error: No nodes found for the specified load area. Check dimensions.');
    end
    load_vals = repmat(load_val / num_load_points, num_load_points, 1);
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- 3D Plate Configuration ---\n');
    fprintf('Mesh: %d x %d x %d elements\n', nelx, nely, nelz);
    fprintf('Total DOFs: %d\n', 3 * num_nodes_x * num_nodes_y * num_nodes_z);
    fprintf('Fixed DOFs count: %d (Fixed face at x=0)\n', length(fixed_dofs));
    fprintf('Load: Distributed load on opposite face (x=max)\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Load applied over %d nodes (area: %d x %d elements)\n', ...
            num_load_points, length(load_nodes_y)-1, length(load_nodes_z)-1);
    fprintf('Note: This problem tests 3D capabilities of the optimization algorithm.\n');
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
    end
end
