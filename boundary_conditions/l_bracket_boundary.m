function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = l_bracket_boundary(plot_flag)
%% L_BRACKET_BOUNDARY Define BCs and design domain for an L-bracket geometry.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = L_BRACKET_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions and design domain for an L-bracket.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of boundary
%               conditions. Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom with fixed (zero) displacement.
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Corresponding load values.
%   nelx          - Number of elements in x-direction (100).
%   nely          - Number of elements in y-direction (100).
%   designer_mask - Logical matrix (nely x nelx) where `true` indicates a
%                   design element and `false` indicates a void element.
%
% Description:
%   - Geometry: 100x100 element domain with a 60x60 element cutout from the top-right.
%   - Fixed boundary: The top edge of the vertical arm.
%   - Load: A vertical downward force distributed over 3 nodes at the
%           outer corner of the horizontal arm.

    % Set default plot_flag to true if not provided
    if nargin < 1
        plot_flag = true;
    end

    % --- PROBLEM CONFIGURATION (Constants) ---
    NELX = 100;           % Number of elements in x-direction
    NELY = 100;           % Number of elements in y-direction
    CUTOUT_X = 60;        % Width of the top-right cutout
    CUTOUT_Y = 60;        % Height of the top-right cutout
    LOAD_VAL = -1;        % Total downward load (negative y-direction)
    NUM_LOAD_POINTS = 3;  % Number of nodes to distribute the load over

    % --- ASSIGN OUTPUTS ---
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN (REVISED) ---
    % Create a mask where 'true' is the design area and 'false' is the void area.
    % This explicitly defines the L-bracket shape.
    designer_mask = true(nely, nelx);
    void_rows = (nely - CUTOUT_Y + 1):nely;
    void_cols = (nelx - CUTOUT_X + 1):nelx;
    designer_mask(void_rows, void_cols) = false; % Set the cutout region to false

    % --- FIXED DOFs ---
    % The vertical arm has a width of (NELX - CUTOUT_X) elements.
    fixed_width_in_elements = NELX - CUTOUT_X;
    
    % Vectorized calculation of fixed nodes on the top edge
    node_cols = 1:(fixed_width_in_elements + 1);
    fixed_nodes = (node_cols - 1) * (nely + 1) + (nely + 1);
    
    % Convert node IDs to DOFs (both x and y directions are fixed)
    fixed_dofs = sort([2 * fixed_nodes - 1, 2 * fixed_nodes]);
    
    % --- LOAD APPLICATION ---
    % The load is applied at the outer-most edge of the horizontal arm.
    load_node_x_idx = nelx + 1;
    center_node_y_idx = (nely - CUTOUT_Y) + 1;

    % Define the 3 nodes for load application
    load_node_y_indices = [center_node_y_idx - 1; center_node_y_idx; center_node_y_idx + 1];
    
    % Calculate node IDs for the 3 load points
    load_nodes = (load_node_x_idx - 1) * (nely + 1) + load_node_y_indices;
    
    % Distribute the total load evenly over the nodes
    % NOTE: Corrected to divide total load by the number of points.
    load_vals = repmat(LOAD_VAL, NUM_LOAD_POINTS, 1);
    
    % Apply vertical forces, so we target the y-DOFs (2 * node_id)
    load_dofs = 2 * load_nodes;

    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- L-Bracket Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Cutout from top-right: %d x %d elements\n', CUTOUT_X, CUTOUT_Y);
    fprintf('Fixed DOFs on top of vertical arm (width: %d elements)\n', fixed_width_in_elements);
    fprintf('Load: Distributed vertical force at nodes [%d, %d, %d]\n', load_nodes(1), load_nodes(2), load_nodes(3));
    fprintf('Total load magnitude: %.2f\n', sum(load_vals));
    
    % Visualize boundary conditions if requested
    if plot_flag
        % NOTE: The visualization function still needs the cutout dimensions
        % to draw the void area correctly. We pass the constants directly.
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'L-Bracket', designer_mask);
    end
end