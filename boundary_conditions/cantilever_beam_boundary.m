function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = cantilever_beam_boundary(plot_flag)
%% CANTILEVER_BEAM_BOUNDARY Define boundary conditions for a cantilever beam problem.
%   [FIXED_DOFS, ..., NELY, DESIGNER_MASK] = CANTILEVER_BEAM_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a cantilever beam topology optimization problem.
%   The beam is fully fixed (clamped) along the left edge and subjected to a vertical
%   shear force applied at the midpoint of the right edge, distributed evenly over 3 elements.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of the boundary conditions.
%               Default is false.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom (DOFs) that are fixed (zero displacement).
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Magnitudes of the corresponding loads.
%   nelx          - Number of elements in the x-direction.
%   nely          - Number of elements in the y-direction.
%   designer_mask - Logical matrix (nelx x nely) indicating the active design domain.

    % Set default value for plot_flag if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION ---
    NELX = 120;                 % Number of elements in the x-direction
    NELY = 60;                  % Number of elements in the y-direction
    LOAD_VAL = -1;              % Normalized load magnitude (downward direction)
    LOAD_DIST_ELEMENTS = 3;     % Load distributed over 3 elements
    
    % Assign output variables
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN (REVISED) ---
    % For a standard cantilever, the entire domain is active.
    designer_mask = true(nely, nelx);

    % --- NODE AND DOF NUMBERING CONVENTION ---
    % The mesh contains (nelx+1) x (nely+1) nodes.
    % Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
    % Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
    % Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)

    % --- FIXED DOFs ---
    % The left edge corresponds to column 1, containing nodes 1 through (nely+1).
    % All DOFs (both x and y) along this edge are fixed.
    fixed_dofs = 1:2*(nely+1);
    
    % --- LOAD APPLICATION ---
    % To distribute the load over 3 elements, forces are applied to 4 nodes.
    num_load_nodes = LOAD_DIST_ELEMENTS + 1;
    
    % Determine the row indices of these 4 nodes, symmetric about the mid-height.
    start_row = (nely / 2 + 1) - (num_load_nodes / 2);
    end_row   = (nely / 2) + (num_load_nodes / 2);
    
    % Row indices of the loaded nodes
    load_rows = start_row:end_row;
    
    % Rightmost column index
    right_col_index = nelx + 1;
    
    % Compute node IDs using column-wise numbering
    load_node_ids = (right_col_index - 1) * (nely + 1) + load_rows;
    
    % Load acts in the y-direction (downward), so we take only y-DOFs.
    load_dofs = 2 * load_node_ids;
    
    % Distribute the load uniformly among all loaded nodes.
    load_vals = (LOAD_VAL) * ones(1, num_load_nodes);
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- Cantilever Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d (entire left edge)\n', length(fixed_dofs));
    fprintf('Load: Vertical shear force at midpoint of right edge\n');
    fprintf('Load distributed over %d elements (applied to %d nodes):\n', ...
            LOAD_DIST_ELEMENTS, num_load_nodes);
    fprintf('  - Loaded node IDs: ');
    fprintf('%d ', load_node_ids);
    fprintf('\n  - Total load magnitude: %.2f\n', abs(LOAD_VAL));
    
    % Visualize boundary conditions if requested
    if plot_flag
        % <<< THÊM VÀO: Truyền designer_mask vào hàm visualize >>>
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Cantilever Beam', designer_mask);
    end
end