function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = distributed_load_example(plot_flag)
%% DISTRIBUTED_LOAD_EXAMPLE Define boundary conditions with distributed load.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = DISTRIBUTED_LOAD_EXAMPLE(PLOT_FLAG)
%   returns boundary conditions for a cantilever beam with a uniformly distributed load
%   on the top edge. This demonstrates how to implement distributed loads.
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
    TOTAL_LOAD = -1;            % Total load magnitude (downward direction)
    
    % Assign output variables
    nelx = NELX;
    nely = NELY;

    % --- DEFINE DESIGN DOMAIN ---
    % For a standard cantilever, the entire domain is active.
    designer_mask = true(nely, nelx);

    % --- NODE AND DOF NUMBERING CONVENTION ---
    % The mesh contains (nelx+1) x (nely+1) nodes.
    % Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
    % Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
    % Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)

    % --- FIXED DOFs ---
    % The left edge is fully fixed (cantilever)
    fixed_dofs = 1:2*(nely+1);
    
    % --- DISTRIBUTED LOAD APPLICATION ---
    % Uniformly distributed load on the entire top edge
    
    % Get all nodes on the top edge
    top_edge_nodes = (0:nelx) * (nely + 1) + (nely + 1);
    num_top_nodes = length(top_edge_nodes);
    
    % Distribute total load evenly among all top nodes
    load_per_node = TOTAL_LOAD / num_top_nodes;
    
    % Load acts in the y-direction (downward)
    load_dofs = 2 * top_edge_nodes;
    load_vals = repmat(load_per_node, 1, num_top_nodes);
    
    % --- DISPLAY & VISUALIZATION ---
    fprintf('--- Distributed Load Example (Cantilever) ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs count: %d (Left edge fixed)\n', length(fixed_dofs));
    fprintf('Load: Uniformly distributed load on top edge\n');
    fprintf('Total load magnitude: %.2f\n', TOTAL_LOAD);
    fprintf('Load distributed over %d nodes\n', num_top_nodes);
    fprintf('Load per node: %.4f\n', load_per_node);
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Distributed Load Example', designer_mask);
    end
end

%% Additional function for linearly varying distributed load
function [load_dofs, load_vals] = create_linearly_varying_load(nelx, nely, total_load, variation_factor)
%% CREATE_LINEARLY_VARYING_LOAD Create a linearly varying distributed load.
%   [LOAD_DOFS, LOAD_VALS] = CREATE_LINEARLY_VARYING_LOAD(NELX, NELY, TOTAL_LOAD, VARIATION_FACTOR)
%   creates a linearly varying load along the top edge.
%
% Inputs:
%   nelx, nely    - Mesh dimensions
%   total_load    - Total load magnitude
%   variation_factor - Load variation factor (e.g., 0.5 for 50% increase from left to right)
%
% Outputs:
%   load_dofs     - DOFs where loads are applied
%   load_vals     - Load values (linearly varying)

    % Get all nodes on the top edge
    top_edge_nodes = (0:nelx) * (nely + 1) + (nely + 1);
    num_top_nodes = length(top_edge_nodes);
    
    % Normalized x-positions from 0 to 1
    x_positions = (0:nelx) / nelx;
    
    % Linearly varying load factors
    % load_factor = 1 + variation_factor * (x_position - 0.5)*2
    % This gives load_factor = 1 - variation_factor at left edge,
    % 1 + variation_factor at right edge
    load_factors = 1 + variation_factor * (2*x_positions - 1);
    
    % Normalize so total load equals specified value
    total_factor = sum(load_factors);
    base_load = total_load / total_factor;
    load_vals = base_load * load_factors;
    
    % Load acts in the y-direction
    load_dofs = 2 * top_edge_nodes;
end
