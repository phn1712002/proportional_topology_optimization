function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = cantilever_beam_boundary_3d(plot_flag)
%% CANTILEVER_BEAM_BOUNDARY_3D Define BCs for a 3D cantilever beam.
%   [FIXED_DOFS, ..., NELZ, DESIGNER_MASK] = CANTILEVER_BEAM_BOUNDARY_3D(PLOT_FLAG)
%   returns boundary conditions for a 3D cantilever beam problem. The beam is fully
%   clamped on the left face (x=0) and loaded with a vertical force on the
%   center of the right face (x=max).
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of the boundary
%               conditions. Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom with fixed (zero) displacement.
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Corresponding load values.
%   nelx, nely, nelz - Number of elements in each direction.
%   designer_mask  - Logical array indicating the active design domain.

    % --- 1. Configuration ---
    if nargin < 1
        plot_flag = true; % Default to show plot
    end

    % Problem parameters
    nelx = 80;                 % Number of elements in x-direction (length)
    nely = 40;                 % Number of elements in y-direction (height)
    nelz = 20;                 % Number of elements in z-direction (thickness)
    load_val = -1;             % Total downward load
    load_area_y = 4;           % Load distributed over a height of Y elements
    load_area_z = 4;           % Load distributed over a thickness of Z elements

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % For a standard cantilever, the entire domain is active.
    designer_mask = true(nely, nelx, nelz);

    % --- 2. Fixed DOFs (Clamped Left Face, x=0) ---
    % Vectorized approach to find all nodes on the left face (j=1 or x-index=1).
    % We create a grid of node indices for the face and then flatten it.
    [I, K] = meshgrid(1:num_nodes_y, 1:num_nodes_z); % Grid of y and z node indices
    
    % Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
    % Here, j=1 for the left face.
    left_face_nodes = (K(:)-1)*(num_nodes_y*num_nodes_x) + (1-1)*num_nodes_y + I(:);
    
    % Get all three DOFs (Ux, Uy, Uz) for each node on the face.
    dof_x = 3 * left_face_nodes - 2;
    dof_y = 3 * left_face_nodes - 1;
    dof_z = 3 * left_face_nodes;
    
    fixed_dofs = sort([dof_x; dof_y; dof_z]);

    % --- 3. Load Application (Center of Right Face, x=max) ---
    % Define the patch of nodes where the load is applied.
    mid_y = floor(num_nodes_y / 2) + 1;
    mid_z = floor(num_nodes_z / 2) + 1;
    
    load_nodes_y = (mid_y - floor(load_area_y/2)) : (mid_y + floor(load_area_y/2));
    load_nodes_z = (mid_z - floor(load_area_z/2)) : (mid_z + floor(load_area_z/2));

    % Create a grid of node indices for the load patch.
    [I_load, K_load] = meshgrid(load_nodes_y, load_nodes_z);

    % Find node IDs on the right face (j=nx or x-index=num_nodes_x).
    right_face_nodes = (K_load(:)-1)*(num_nodes_y*num_nodes_x) + (num_nodes_x-1)*num_nodes_y + I_load(:);
    
    % The load is applied in the y-direction (vertical).
    load_dofs = 3 * right_face_nodes - 1;
    
    % Distribute the total load evenly among all loaded DOFs.
    num_load_points = length(load_dofs);
    load_vals = repmat(load_val / num_load_points, num_load_points, 1);
    
    % --- 4. Display Information & Visualization ---
    fprintf('--- 3D Cantilever Beam Configuration ---\n');
    fprintf('Mesh: %d x %d x %d elements\n', nelx, nely, nelz);
    fprintf('Fixed DOFs count: %d (Clamped face)\n', length(fixed_dofs));
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Load applied over %d nodes.\n', num_load_points);
    
    if plot_flag
        visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
    end
end