function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = l_bracket_3d_boundary(plot_flag)
%% L_BRACKET_3D_BOUNDARY Define boundary conditions for a 3D L-bracket problem.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, NELZ, DESIGNER_MASK] = L_BRACKET_3D_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a 3D L-bracket topology optimization problem.
%   This is the 3D extension of the 2D L-bracket problem.
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
%   nelz          - Number of elements in the z-direction (thickness).
%   designer_mask - Logical matrix (nely x nelx x nelz) indicating the active design domain.

    % Set default value for plot_flag if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION ---
    % Using a coarser mesh for faster simulation
    nelx = 20;                 % Number of elements in x-direction (was 30)
    nely = 20;                 % Number of elements in y-direction (was 30)
    nelz = 4;                  % Number of elements in z-direction (was 6)
    
    % Cutout dimensions (scaled down proportionally with the mesh)
    CUTOUT_X = 12;             % Width of the top-right cutout (was 18)
    CUTOUT_Y = 12;             % Height of the top-right cutout (was 18)
    
    % Load configuration
    load_val = -1;             % Total downward load (negative y-direction)
    load_area_z = 2;           % Load distributed over thickness of Z elements (was 3)

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % --- DEFINE DESIGN DOMAIN (3D L-BRACKET) ---
    designer_mask = true(nely, nelx, nelz);
    void_rows = (nely - CUTOUT_Y + 1):nely;
    void_cols = (nelx - CUTOUT_X + 1):nelx;
    designer_mask(void_rows, void_cols, :) = false;

    % --- NODE AND DOF NUMBERING CONVENTION (3D) ---
    % ... (No changes here)

    % --- FIXED DOFs ---
    fixed_width_in_elements = nelx - CUTOUT_X;
    fixed_nodes = [];
    for z_idx = 1:num_nodes_z
        for x_idx = 1:(fixed_width_in_elements + 1)
            y_idx = num_nodes_y;
            node_id = (z_idx-1)*(num_nodes_y*num_nodes_x) + (x_idx-1)*num_nodes_y + y_idx;
            fixed_nodes = [fixed_nodes; node_id];
        end
    end
    dof_x = 3 * fixed_nodes - 2;
    dof_y = 3 * fixed_nodes - 1;
    dof_z = 3 * fixed_nodes;
    fixed_dofs = sort([dof_x; dof_y; dof_z]);

    % --- LOAD APPLICATION ---
    % Load is applied at the outer-most edge of the horizontal arm
    
    % CORRECTED: Center of the load in y-direction (middle of the horizontal arm's free edge)
    load_center_y = floor((nely - CUTOUT_Y) / 2) + 1;
    
    % Define load distribution in z-direction (centered)
    mid_z = floor(num_nodes_z / 2) + 1;
    half_z = floor(min(load_area_z, nelz) / 2);
    load_nodes_z = (mid_z - half_z) : (mid_z + half_z);
    
    % Create grid of load nodes
    load_nodes = [];
    for z_idx = load_nodes_z
        x_idx = num_nodes_x; % Rightmost edge
        for y_offset = -1:1
            y_idx = load_center_y + y_offset;
            if y_idx >= 1 && y_idx <= num_nodes_y
                node_id = (z_idx-1)*(num_nodes_y*num_nodes_x) + (x_idx-1)*num_nodes_y + y_idx;
                load_nodes = [load_nodes; node_id];
            end
        end
    end
    
    load_dofs = 3 * load_nodes - 1;
    
    num_load_points = length(load_dofs);
    if num_load_points == 0
        error('Load application error: No nodes found for the specified load area. Check dimensions.');
    end
    load_vals = repmat(load_val / num_load_points, num_load_points, 1);
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- 3D L-Bracket Configuration ---\n');
    fprintf('Mesh: %d x %d x %d elements\n', nelx, nely, nelz);
    fprintf('Cutout from top-right: %d x %d elements\n', CUTOUT_X, CUTOUT_Y);
    fprintf('Total DOFs: %d\n', 3 * num_nodes_x * num_nodes_y * num_nodes_z);
    fprintf('Fixed DOFs count: %d (Top edge of vertical arm)\n', length(fixed_dofs));
    fprintf('Load: Distributed load on outer face of horizontal arm\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Load applied over %d nodes\n', num_load_points);
    fprintf('Note: This is the 3D extension of the L-bracket problem.\n');
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
    end
end