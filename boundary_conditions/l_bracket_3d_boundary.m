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
    % Using moderate mesh size for 3D L-bracket (similar to 2D but with thickness)
    nelx = 30;                 % Number of elements in x-direction (width)
    nely = 30;                 % Number of elements in y-direction (height)
    nelz = 6;                  % Number of elements in z-direction (thickness)
    
    % Cutout dimensions (similar to 2D version but scaled down for 3D)
    CUTOUT_X = 18;            % Width of the top-right cutout in elements
    CUTOUT_Y = 18;            % Height of the top-right cutout in elements
    
    % Load configuration
    load_val = -1;            % Total downward load (negative y-direction)
    load_area_z = 3;          % Load distributed over thickness of Z elements

    % Node grid dimensions
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;
    num_nodes_z = nelz + 1;

    % --- DEFINE DESIGN DOMAIN (3D L-BRACKET) ---
    % Create a 3D mask where 'true' is the design area and 'false' is the void area.
    % The L-bracket shape is extruded in the z-direction.
    designer_mask = true(nely, nelx, nelz);
    
    % Apply cutout to all layers in z-direction
    void_rows = (nely - CUTOUT_Y + 1):nely;
    void_cols = (nelx - CUTOUT_X + 1):nelx;
    
    for z = 1:nelz
        designer_mask(void_rows, void_cols, z) = false;
    end

    % --- NODE AND DOF NUMBERING CONVENTION (3D) ---
    % The mesh contains (nelx+1) x (nely+1) x (nelz+1) nodes.
    % Nodes are numbered with z varying fastest, then y, then x.
    % Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
    % where i = y-index (1 to ny+1), j = x-index (1 to nx+1), k = z-index (1 to nz+1)
    % Degrees of freedom for node 'n': 3*n-2 (x), 3*n-1 (y), 3*n (z)

    % --- FIXED DOFs ---
    % Fixed boundary: The top edge of the vertical arm (similar to 2D but extended in z)
    % The vertical arm has a width of (nelx - CUTOUT_X) elements.
    fixed_width_in_elements = nelx - CUTOUT_X;
    
    % Create grid of fixed nodes on the top edge for all z-layers
    fixed_nodes = [];
    
    for z_idx = 1:num_nodes_z
        % Node columns for the fixed edge (x-direction)
        for x_idx = 1:(fixed_width_in_elements + 1)
            % Node is at top edge (y = nely + 1)
            y_idx = num_nodes_y;
            
            % Calculate node ID
            node_id = (z_idx-1)*(num_nodes_y*num_nodes_x) + (x_idx-1)*num_nodes_y + y_idx;
            fixed_nodes = [fixed_nodes; node_id];
        end
    end
    
    % Get all three DOFs (Ux, Uy, Uz) for each fixed node
    dof_x = 3 * fixed_nodes - 2;
    dof_y = 3 * fixed_nodes - 1;
    dof_z = 3 * fixed_nodes;
    
    fixed_dofs = sort([dof_x; dof_y; dof_z]);

    % --- LOAD APPLICATION ---
    % Load is applied at the outer-most edge of the horizontal arm (x = nelx + 1)
    % Distributed over the thickness (z-direction) and centered in y
    
    % Center of the load in y-direction (at the corner of the horizontal arm)
    load_center_y = (nely - CUTOUT_Y) + 1;
    
    % Define load distribution in z-direction (centered)
    mid_z = floor(num_nodes_z / 2) + 1;
    half_z = floor(min(load_area_z, nelz) / 2);
    load_nodes_z = (mid_z - half_z) : (mid_z + half_z);
    
    % Create grid of load nodes
    load_nodes = [];
    
    for z_idx = load_nodes_z
        % Load is applied at the rightmost edge (x = num_nodes_x)
        x_idx = num_nodes_x;
        
        % Apply load at 3 points in y-direction (similar to 2D)
        for y_offset = -1:1
            y_idx = load_center_y + y_offset;
            
            % Check if y_idx is within bounds
            if y_idx >= 1 && y_idx <= num_nodes_y
                % Calculate node ID
                node_id = (z_idx-1)*(num_nodes_y*num_nodes_x) + (x_idx-1)*num_nodes_y + y_idx;
                load_nodes = [load_nodes; node_id];
            end
        end
    end
    
    % The load is applied in the y-direction (vertical, downward)
    load_dofs = 3 * load_nodes - 1;
    
    % Distribute the total load evenly among all loaded DOFs
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
