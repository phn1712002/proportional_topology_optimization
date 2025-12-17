function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = simply_supported_beam_boundary(plot_flag)
%% SIMPLY_SUPPORTED_BEAM_BOUNDARY Define boundary conditions for a simply supported beam problem.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = SIMPLY_SUPPORTED_BEAM_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a simply supported beam topology optimization problem.
%   The beam has a fixed support at the left edge and a roller support at the right edge.
%   A vertical point load is applied at the center of the top edge.
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
    NELY = 40;                  % Number of elements in the y-direction
    LOAD_VAL = -1;              % Normalized load magnitude (downward direction)
    
    % Assign output variables
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN ---
    % For a standard simply supported beam, the entire domain is active.
    designer_mask = true(nely, nelx);

    % --- NODE AND DOF NUMBERING CONVENTION ---
    % The mesh contains (nelx+1) x (nely+1) nodes.
    % Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
    % Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
    % Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)

    % --- FIXED DOFs ---
    % 1. Fixed support at left edge (column 1): Both x and y DOFs fixed
    left_edge_nodes = 1:(nely+1);
    fixed_left_dofs = sort([2*left_edge_nodes-1, 2*left_edge_nodes]);
    
    % 2. Roller support at right edge (column nelx+1): Only y DOF fixed
    right_col_nodes = (nelx)*(nely+1) + (1:(nely+1));
    roller_dofs = 2 * right_col_nodes;  % Only y-direction DOFs
    
    % Combine all fixed DOFs
    fixed_dofs = sort(unique([fixed_left_dofs, roller_dofs]));
    
    % --- LOAD APPLICATION ---
    % Point load at the center of the top edge
    load_node_col = floor(nelx/2) + 1;  % Center column
    load_node_row = nely + 1;           % Top row
    
    % Calculate node ID
    load_node_id = (load_node_col - 1) * (nely + 1) + load_node_row;
    
    % Load acts in the y-direction (downward)
    load_dofs = 2 * load_node_id;
    load_vals = LOAD_VAL;
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- Simply Supported Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('Fixed support: Left edge (both x and y fixed)\n');
    fprintf('Roller support: Right edge (only y fixed)\n');
    fprintf('Load: Point load at center of top edge\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Simply Supported Beam', designer_mask);
    end
end
