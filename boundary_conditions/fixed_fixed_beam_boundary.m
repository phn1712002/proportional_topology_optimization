function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = fixed_fixed_beam_boundary(plot_flag)
%% FIXED_FIXED_BEAM_BOUNDARY Define boundary conditions for a fixed-fixed beam problem.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = FIXED_FIXED_BEAM_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a fixed-fixed beam topology optimization problem.
%   Both ends of the beam are fully fixed (clamped), creating a statically indeterminate structure.
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
    % For a standard fixed-fixed beam, the entire domain is active.
    designer_mask = true(nely, nelx);

    % --- NODE AND DOF NUMBERING CONVENTION ---
    % The mesh contains (nelx+1) x (nely+1) nodes.
    % Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
    % Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
    % Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)

    % --- FIXED DOFs ---
    % Both left and right edges are fully fixed (both x and y DOFs)
    
    % 1. Left edge (column 1)
    left_nodes = 1:(nely+1);
    left_dofs = sort([2*left_nodes-1, 2*left_nodes]);
    
    % 2. Right edge (column nelx+1)
    right_nodes = (nelx)*(nely+1) + (1:(nely+1));
    right_dofs = sort([2*right_nodes-1, 2*right_nodes]);
    
    % Combine all fixed DOFs
    fixed_dofs = sort(unique([left_dofs, right_dofs]));
    
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
    fprintf('--- Fixed-Fixed Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('Both ends fully fixed (clamped)\n');
    fprintf('Load: Point load at center of top edge\n');
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    fprintf('Note: This problem is statically indeterminate and sensitive to checkerboard patterns.\n');
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Fixed-Fixed Beam', designer_mask);
    end
end
