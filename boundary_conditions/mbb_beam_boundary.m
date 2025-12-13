function [fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(plot_flag)
%% MBB_BEAM_BOUNDARY Define boundary conditions for an MBB beam problem (half symmetry)
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY] = MBB_BEAM_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions for a half-symmetry MBB beam problem.
%   The beam has a symmetry boundary on the left edge, a roller support
%   at the bottom-right corner, and a distributed point load at the top-left edge.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of boundary
%               conditions. Default is false.
%
% Outputs:
%   fixed_dofs - Degrees of freedom with fixed (zero) displacement.
%   load_dofs  - Degrees of freedom where loads are applied.
%   load_vals  - Corresponding load values.
%   nelx       - Number of elements in x-direction.
%   nely       - Number of elements in y-direction.
%
% Description based on the standard MBB beam diagram:
%   - Symmetry boundary: Left edge (x=0) is fixed in the x-direction (Ux=0).
%   - Roller support: Bottom-right corner is fixed in the y-direction (Uy=0).
%   - Load: A vertical load distributed over 3 nodes at the top-left edge.

    % Set default plot_flag to false if not provided
    if nargin < 1
        plot_flag = false;
    end

%% PROBLEM CONFIGURATION
    NELX = 120;             % Number of elements in x-direction
    NELY = 40;              % Number of elements in y-direction
    LOAD_VAL = -1;          % Total downward load (negative y-direction)
    NUM_LOAD_POINTS = 3;    % Number of nodes to distribute the load over

    % Assign output variables
    nelx = NELX;
    nely = NELY;

%% FIXED DOFs
    % Node ID formula: node_id = (col - 1) * (nely + 1) + row
    
    % 1. Symmetry Condition: Left edge fixed in x-direction (Ux = 0)
    % Affects all nodes in the first column (col=1).
    % DOFs are odd-numbered: 1, 3, 5, ..., 2*(nely+1)-1
    symmetry_dofs = 1:2:2*(nely + 1);
    
    % 2. Roller Support: Bottom-right corner fixed in y-direction (Uy = 0)
    roller_node_col = nelx + 1;
    roller_node_row = 1;
    roller_node_id = (roller_node_col - 1) * (nely + 1) + roller_node_row;
    
    % The y-direction DOF is the even-numbered one
    roller_dof = 2 * roller_node_id; 
    
    % Combine all fixed DOFs, sort, and ensure uniqueness
    fixed_dofs = sort(unique([symmetry_dofs, roller_dof]));
    
%% LOAD APPLICATION
    % A vertical load distributed over the first NUM_LOAD_POINTS nodes
    % at the top-left edge.
    load_node_cols = 1:NUM_LOAD_POINTS;
    load_node_row = nely + 1;
    
    % Vectorized calculation of node IDs
    load_node_ids = (load_node_cols - 1) * (nely + 1) + load_node_row;
    
    % The load acts in the vertical (y) direction (even-numbered DOFs)
    load_dofs = 2 * load_node_ids;
    
    % Distribute the total load evenly across the load points
    load_vals = repmat(LOAD_VAL / NUM_LOAD_POINTS, 1, NUM_LOAD_POINTS);
    
%% DISPLAY & VISUALIZATION
    fprintf('--- MBB Beam Configuration (Half Symmetry) ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('  - Left edge fixed in x-direction (Symmetry)\n');
    fprintf('  - Bottom-right corner fixed in y-direction (Node ID: %d)\n', roller_node_id);
    fprintf('Load: Distributed force over %d nodes at top-left edge\n', NUM_LOAD_POINTS);
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'MBB Beam (Half Symmetry)');
    end
end