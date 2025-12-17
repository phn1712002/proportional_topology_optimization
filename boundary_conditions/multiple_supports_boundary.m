function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = multiple_supports_boundary(plot_flag)
%% MULTIPLE_SUPPORTS_BOUNDARY Define boundary conditions for a beam with multiple supports.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = MULTIPLE_SUPPORTS_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a beam with multiple discrete supports.
%   This configuration helps avoid local minima and tests algorithm stability.
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
%   designer_mask - Logical matrix (nely x nelx) indicating the active design domain.

    % Set default value for plot_flag if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION ---
    NELX = 120;                 % Number of elements in the x-direction
    NELY = 60;                  % Number of elements in the y-direction
    LOAD_VAL = -1;              % Normalized load magnitude (downward direction)
    
    % Support configuration: 3 discrete supports at bottom
    support_positions = [0.2, 0.5, 0.8];  % Fractional positions along x-axis
    
    % Assign output variables
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN ---
    % For a standard beam with multiple supports, the entire domain is active.
    designer_mask = true(nely, nelx);

    % --- NODE AND DOF NUMBERING CONVENTION ---
    % The mesh contains (nelx+1) x (nely+1) nodes.
    % Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
    % Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
    % Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)

    % --- FIXED DOFs ---
    % Create discrete supports at specified positions along the bottom edge
    
    fixed_dofs = [];
    
    for i = 1:length(support_positions)
        % Calculate column index for support (1-based)
        support_col = round(support_positions(i) * nelx) + 1;
        
        % Ensure support column is within bounds
        support_col = max(1, min(support_col, nelx + 1));
        
        % Bottom row node at this column
        support_node_row = 1;  % Bottom row
        support_node_id = (support_col - 1) * (nely + 1) + support_node_row;
        
        % Both x and y DOFs are fixed for pinned supports
        support_dofs = [2*support_node_id-1, 2*support_node_id];
        
        fixed_dofs = [fixed_dofs, support_dofs];
    end
    
    % Remove duplicates and sort
    fixed_dofs = sort(unique(fixed_dofs));
    
    % --- LOAD APPLICATION ---
    % Multiple point loads along the top edge
    load_positions = [0.3, 0.7];  % Fractional positions along x-axis
    load_magnitudes = [-0.5, -0.5];  % Equal loads, total = LOAD_VAL
    
    load_dofs = [];
    load_vals = [];
    
    for i = 1:length(load_positions)
        % Calculate column index for load (1-based)
        load_col = round(load_positions(i) * nelx) + 1;
        
        % Ensure load column is within bounds
        load_col = max(1, min(load_col, nelx + 1));
        
        % Top row node at this column
        load_node_row = nely + 1;  % Top row
        load_node_id = (load_col - 1) * (nely + 1) + load_node_row;
        
        % Load acts in the y-direction (downward)
        load_dofs = [load_dofs, 2 * load_node_id];
        load_vals = [load_vals, load_magnitudes(i)];
    end
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- Multiple Supports Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d (%d discrete supports)\n', length(fixed_dofs), length(support_positions));
    fprintf('Support positions (x-fraction): [');
    fprintf('%.2f ', support_positions);
    fprintf(']\n');
    fprintf('Load positions (x-fraction): [');
    fprintf('%.2f ', load_positions);
    fprintf(']\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Note: Multiple supports help avoid local minima and test algorithm stability.\n');
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Multiple Supports Beam', designer_mask);
    end
end
