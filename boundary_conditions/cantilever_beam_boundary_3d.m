function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = cantilever_beam_boundary_3d(plot_flag)
%% CANTILEVER_BEAM_BOUNDARY_3D Define BCs for a 3D cantilever beam (Lightweight Version).
%   This version uses a coarse mesh for fast testing and demonstration.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of the boundary
%               conditions. Default is true.
%
% Outputs:
%   (Outputs are the same as the original function)

    % --- 1. Configuration (for a lightweight simulation) ---
    if nargin < 1
        plot_flag = true; % Default to show plot
    end

    % Problem parameters - REDUCED for a fast simulation
    nelx = 12;                 % Number of elements in x-direction (length)
    nely = 6;                  % Number of elements in y-direction (height)
    nelz = 4;                  % Number of elements in z-direction (thickness)
    load_val = -1;             % Total downward load

    % Load area is now smaller and proportional to the mesh
    load_area_y = 2;           % Load distributed over a height of Y elements
    load_area_z = 2;           % Load distributed over a thickness of Z elements

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % For a standard cantilever, the entire domain is active.
    designer_mask = true(nely, nelx, nelz);

    % --- 2. Fixed DOFs (Clamped Left Face, x=0) ---
    % Vectorized approach remains efficient for any mesh size
    [I, K] = meshgrid(1:num_nodes_y, 1:num_nodes_z); % Grid of y and z node indices
    
    % Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
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
    
    % Ensure load area does not exceed beam dimensions
    half_y = floor(min(load_area_y, nely) / 2);
    half_z = floor(min(load_area_z, nelz) / 2);
    
    load_nodes_y = (mid_y - half_y) : (mid_y + half_y);
    load_nodes_z = (mid_z - half_z) : (mid_z + half_z);

    % Create a grid of node indices for the load patch.
    [I_load, K_load] = meshgrid(load_nodes_y, load_nodes_z);

    % Find node IDs on the right face (j=nx or x-index=num_nodes_x).
    right_face_nodes = (K_load(:)-1)*(num_nodes_y*num_nodes_x) + (num_nodes_x-1)*num_nodes_y + I_load(:);
    
    % The load is applied in the y-direction (vertical).
    load_dofs = 3 * right_face_nodes - 1;
    
    % Distribute the total load evenly among all loaded DOFs.
    num_load_points = length(load_dofs);
    if num_load_points == 0
        error('Load application error: No nodes found for the specified load area. Check dimensions.');
    end
    load_vals = repmat(load_val / num_load_points, num_load_points, 1);
    
    % --- 4. Display Information & Visualization ---
    fprintf('--- 3D Cantilever Beam Configuration (Lightweight) ---\n');
    fprintf('Mesh: %d x %d x %d elements\n', nelx, nely, nelz);
    fprintf('Total DOFs: %d\n', 3 * num_nodes_x * num_nodes_y * num_nodes_z);
    fprintf('Fixed DOFs count: %d (Clamped face)\n', length(fixed_dofs));
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Load applied over %d nodes.\n', num_load_points);
    
    if plot_flag
        visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
    end
end