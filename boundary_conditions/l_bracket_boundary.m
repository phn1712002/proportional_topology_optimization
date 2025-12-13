function [fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary_specific(plot_flag)
%% L_BRACKET_BOUNDARY_SPECIFIC Define BCs for a specific L-bracket geometry.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, CUTOUT_X, CUTOUT_Y] = L_BRACKET_BOUNDARY_SPECIFIC(PLOT_FLAG)
%   returns the boundary conditions for an L-bracket of size 100x40 with a
%   50x20 cutout from the top-right corner.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of boundary
%               conditions. Default is false.
%
% Outputs:
%   fixed_dofs - Degrees of freedom with fixed (zero) displacement
%   load_dofs  - Degrees of freedom where loads are applied
%   load_vals  - Corresponding load values
%   nelx       - Number of elements in x-direction (100)
%   nely       - Number of elements in y-direction (40)
%   cutout_x   - Width of cutout region (50)
%   cutout_y   - Height of cutout region (20)
%
% Description:
%   - Geometry: 100x40 element domain with a 50x20 element cutout from the top-right.
%   - Fixed boundary: The top edge of the vertical arm.
%   - Load: A vertical downward force distributed over 3 nodes at the
%           outer corner of the horizontal arm.

    % Set default plot_flag to false if not provided
    if nargin < 1
        plot_flag = false;
    end

    % --- CONSTANTS: SPECIFIC DIMENSIONS ---
    NELX = 100;           % Number of elements in x-direction
    NELY = 40;            % Number of elements in y-direction
    CUTOUT_X = 50;        % Width of the top-right cutout
    CUTOUT_Y = 20;        % Height of the top-right cutout
    TOTAL_LOAD = -1;      % Total downward load (negative y-direction)

    % Assign to output variables
    nelx = NELX;
    nely = NELY;
    cutout_x = CUTOUT_X;
    cutout_y = CUTOUT_Y;

    % --- FIXED DOFs: Top edge of the vertical arm ---
    % The vertical arm has a width of (NELX - CUTOUT_X) elements.
    fixed_width_in_elements = NELX - CUTOUT_X;
    
    % Vectorized calculation of fixed nodes on the top edge
    % Node columns range from 1 to (fixed_width_in_elements + 1)
    % All nodes are on the top row of the grid (nely + 1)
    node_cols = 1:(fixed_width_in_elements + 1);
    fixed_nodes = (node_cols - 1) * (nely + 1) + (nely + 1);
    
    % Convert node IDs to DOFs (both x and y directions are fixed)
    fixed_dofs = sort([2 * fixed_nodes - 1, 2 * fixed_nodes]);
    
    % --- LOAD APPLICATION: Distributed over 3 nodes at the outer corner ---
    % The load is applied at the outer-most edge of the horizontal arm,
    % centered around the corner.
    
    load_node_x_idx = nelx + 1;
    center_node_y_idx = (nely - cutout_y) + 1; % y-index is (40-20)+1 = 21

    % Define the 3 nodes: center point and its two vertical neighbors
    load_node_y_indices = [center_node_y_idx - 1; center_node_y_idx; center_node_y_idx + 1];
    
    % Calculate node IDs for the 3 load points
    load_nodes = (load_node_x_idx - 1) * (nely + 1) + load_node_y_indices;
    
    % Distribute the total load over the 3 nodes (1/4, 1/2, 1/4 distribution)
    load_distribution = [0.25; 0.5; 0.25];
    
    % Apply vertical forces, so we target the y-DOFs
    load_dofs = 2 * load_nodes;       % y-direction DOFs for the 3 nodes
    load_vals = TOTAL_LOAD * load_distribution;

    % --- Display configuration information for verification ---
    fprintf('--- L-Bracket Configuration (Specific Dimensions) ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Cutout from top-right: %d x %d elements\n', cutout_x, cutout_y);
    fprintf('Fixed DOFs on top of vertical arm (width: %d elements)\n', fixed_width_in_elements);
    fprintf('Load: Distributed vertical force at nodes [%d, %d, %d]\n', load_nodes(1), load_nodes(2), load_nodes(3));
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'L-Bracket (100x40)', cutout_x, cutout_y);
    end
end