function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = c_beam_boundary(plot_flag)
% C_BEAM_BOUNDARY Define BCs for a horizontal U-shaped cantilever beam.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = C_BEAM_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions and design domain for a U-shaped cantilever beam.
%
%   This configuration models a U-shaped beam fixed along its entire left
%   edge, with a load applied at the center of the right-side opening.
%
% Inputs:
%   plot_flag     - (Optional) If true, displays a visualization of boundary
%                   conditions. Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom with fixed (zero) displacement.
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Corresponding load values.
%   nelx          - Number of elements in x-direction.
%   nely          - Number of elements in y-direction.
%   designer_mask - Logical matrix (nely x nelx) where `true` indicates a
%                   design element, shaping the U-beam.
%
% Description:
%   - Fixed support: The entire left edge is fully fixed (cantilevered).
%   - Load: A vertical load is distributed over 3 nodes at the center of
%           the opening on the right edge.
%   - Domain: A rectangular domain with a central cutout on the right side,
%             forming a 'U' or 'C' shape.

%% 1. Configuration Constants
    % --- Domain Size ---
    NELX = 120; % Number of elements in x-direction
    NELY = 60;  % Number of elements in y-direction

    % --- U-Shape Geometry Parameters ---
    SPINE_WIDTH = 20;  % Width of the fixed vertical spine on the left
    ARM_HEIGHT = 20;   % Height of the top and bottom horizontal arms

    % --- Load Parameters ---
    NUM_LOAD_POINTS = 3;   % Distribute load over this many nodes
    LOAD_PER_POINT = -1.0; % Load value per point (negative for downward)

%% 2. Handle Optional Inputs
    if nargin < 1
        plot_flag = true;
    end

%% 3. Define Design Domain (Horizontal U-Shape)
    % Start with a full rectangular domain
    designer_mask = true(NELY, NELX);

    % Define the region to be removed (the cutout on the right side)
    cutout_x_start = SPINE_WIDTH + 1;
    cutout_x_end   = NELX;
    cutout_y_start = ARM_HEIGHT + 1;
    cutout_y_end   = NELY - ARM_HEIGHT;

    % Set the cutout region to false (non-design area)
    if cutout_y_start <= cutout_y_end && cutout_x_start <= cutout_x_end
        designer_mask(cutout_y_start:cutout_y_end, cutout_x_start:cutout_x_end) = false;
    end
    
%% 4. Define Fixed Boundary Conditions (Cantilever)
    % The entire left edge is fixed.
    % Node ID formula: node_id = (col - 1) * (nely + 1) + row
    fixed_col = 1;
    fixed_rows = 1:(NELY + 1);
    fixed_node_ids = (fixed_col - 1) * (NELY + 1) + fixed_rows;
    
    % Get both x and y degrees of freedom for these nodes.
    % Convention: x-DOF = 2*node_id - 1; y-DOF = 2*node_id.
    fixed_dofs_x = 2 * fixed_node_ids' - 1;
    fixed_dofs_y = 2 * fixed_node_ids';
    fixed_dofs = sort([fixed_dofs_x; fixed_dofs_y]);

%% 5. Define Load Conditions
    % Apply a concentrated vertical load on the right side of the beam
    % (at the free end of the bottom arm, pointing downward).
    load_col = NELX; % Load is applied on the rightmost column of the beam (not NELX+1)

    % The bottom arm occupies rows from (NELY - ARM_HEIGHT + 1) to NELY
    % We'll apply load to the last 3 rows of the bottom arm
    bottom_arm_start = NELY - ARM_HEIGHT + 1;
    load_node_rows = (NELY - 2):NELY; % Last 3 rows (58, 59, 60 when NELY=60)
    
    % Ensure we have exactly NUM_LOAD_POINTS points
    if length(load_node_rows) > NUM_LOAD_POINTS
        % Take the last NUM_LOAD_POINTS rows
        load_node_rows = load_node_rows(end-NUM_LOAD_POINTS+1:end);
    elseif length(load_node_rows) < NUM_LOAD_POINTS
        % If bottom arm is too small, adjust
        load_node_rows = bottom_arm_start:min(bottom_arm_start+NUM_LOAD_POINTS-1, NELY);
    end
    
    % Calculate node IDs for the load points
    load_node_ids = (load_col - 1) * (NELY + 1) + load_node_rows;
    
    % The load is applied vertically (y-direction), which corresponds to even DOFs
    load_dofs = 2 * load_node_ids'; % Ensure it's a column vector
   
    % Assign load values to each point (negative for downward)
    load_vals = repmat(LOAD_PER_POINT, NUM_LOAD_POINTS, 1);
 
%% 6. Assign Output Variables and Display Info
    % Assign constants to output arguments
    nelx = NELX;
    nely = NELY;

    fprintf('--- C-Shaped Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Spine Width: %d, Arm Height: %d\n', SPINE_WIDTH, ARM_HEIGHT);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('Load applied at %d points, value per point: %.2f\n', NUM_LOAD_POINTS, LOAD_PER_POINT);

    % Visualize boundary conditions if requested
    if plot_flag
        % This assumes a visualization function is available in the path.
        % Example: visualize_boundary_conditions(nelx, nely, fixed_dofs, ...
        %                                     load_dofs, load_vals, ...
        %                                     'C-Shaped Beam', designer_mask);
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'C-Shaped Beam', designer_mask);
    end
end
