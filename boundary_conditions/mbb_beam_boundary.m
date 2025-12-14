function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = mbb_beam_boundary(plot_flag)
%% MBB_BEAM_BOUNDARY Define BCs and design domain for an MBB beam (half symmetry).
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = MBB_BEAM_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions and design domain for a half-symmetry
%   MBB beam problem.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of boundary
%               conditions. Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom with fixed (zero) displacement.
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Corresponding load values.
%   nelx          - Number of elements in x-direction.
%   nely          - Number of elements in y-direction.
%   designer_mask - Logical matrix (nely x nelx) where `true` indicates a
%                   design element. For MBB beam, this is the full domain.
%
% Description:
%   - Symmetry boundary: Left edge (x=0) is fixed in the x-direction (Ux=0).
%   - Roller support: Bottom-right corner is fixed in the y-direction (Uy=0).
%   - Load: A vertical load distributed over 3 nodes at the top-left edge.

    % Set default plot_flag to true if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION ---
    NELX = 120;             % Number of elements in x-direction
    NELY = 40;              % Number of elements in y-direction
    LOAD_VAL = -1;          % Total downward load (negative y-direction)
    NUM_LOAD_POINTS = 3;    % Number of nodes to distribute the load over

    % Assign output variables
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN (REVISED) ---
    % For a standard MBB beam, the entire rectangular domain is the design area.
    % We define this explicitly for consistency.
    designer_mask = true(nely, nelx);

    % --- FIXED DOFs ---
    % Node ID formula: node_id = (col - 1) * (nely + 1) + row
    
    % 1. Symmetry Condition: Left edge fixed in x-direction (Ux = 0)
    symmetry_dofs = 1:2:2*(nely + 1);
    
    % 2. Roller Support: Bottom-right corner fixed in y-direction (Uy = 0)
    roller_node_col = nelx + 1;
    roller_node_row = 1;
    roller_node_id = (roller_node_col - 1) * (nely + 1) + roller_node_row;
    roller_dof = 2 * roller_node_id; % y-direction DOF
    
    % Combine all fixed DOFs
    fixed_dofs = sort(unique([symmetry_dofs, roller_dof]));
    
    % --- LOAD APPLICATION ---
    % A vertical load distributed over the first NUM_LOAD_POINTS nodes at the top-left.
    load_node_cols = 1:NUM_LOAD_POINTS;
    load_node_row = nely + 1;
    
    load_node_ids = (load_node_cols - 1) * (nely + 1) + load_node_row;
    
    % The load acts in the vertical (y) direction (even-numbered DOFs)
    load_dofs = 2 * load_node_ids;
    
    % Distribute the total load evenly across the load points
    % NOTE: Corrected to divide total load by the number of points.
    load_vals = repmat(LOAD_VAL, NUM_LOAD_POINTS, 1);
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- MBB Beam Configuration (Half Symmetry) ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('  - Left edge fixed in x-direction (Symmetry)\n');
    fprintf('  - Bottom-right corner fixed in y-direction (Node ID: %d)\n', roller_node_id);
    fprintf('Load: Distributed force over %d nodes at top-left edge\n', NUM_LOAD_POINTS);
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    
    % Visualize boundary conditions if requested (REVISED)
    if plot_flag
        % Use the new visualization function, passing the designer_mask
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'MBB Beam (Half Symmetry)', designer_mask);
    end
end