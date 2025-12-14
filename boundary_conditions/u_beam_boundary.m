function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = u_beam_boundary(plot_flag)
%% U_BEAM_BOUNDARY Define BCs for a vertical U-shaped cantilever beam.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = U_BEAM_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions and design domain for a U-shaped cantilever beam.
%
%   This configuration models a U-shaped beam fixed along its entire left
%   edge, with a load applied at the center of the right-side opening.
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
%                   design element, shaping the U-beam.
%
% Description:
%   - Fixed support: The entire left edge is fully fixed (cantilevered).
%   - Load: A vertical load is distributed over 3 nodes at the center of
%           the opening on the right edge.
%   - Domain: A rectangular domain with a central cutout on the right side.

%% 1. Default Parameters
    if nargin < 1
        plot_flag = true;
    end

%% 2. Problem Configuration
    % --- Domain Size ---
    NELX = 120;             % Number of elements in x-direction
    NELY = 60;              % Number of elements in y-direction

    % --- U-Shape Geometry Parameters ---
    SPINE_WIDTH = 30;       % Width of the fixed vertical spine on the left
    ARM_HEIGHT = 20;        % Height of the top and bottom horizontal arms

    % --- Assign output variables ---
    nelx = NELX;
    nely = NELY;

%% 3. Define Design Domain (Vertical U-Shape)
    % Start with a full rectangular domain
    designer_mask = true(nely, nelx);

    % Define the region to be removed (the cutout on the right)
    cutout_x_start = SPINE_WIDTH + 1;
    cutout_x_end = nelx;
    cutout_y_start = ARM_HEIGHT + 1;
    cutout_y_end = nely - ARM_HEIGHT;

    % Set the cutout region to false (non-design area)
    if cutout_y_start <= cutout_y_end && cutout_x_start <= cutout_x_end
        designer_mask(cutout_y_start:cutout_y_end, cutout_x_start:cutout_x_end) = false;
    end

%% 4. Define Fixed Boundary Conditions (Cantilever)
    % The entire left edge is fixed.
    % Node ID formula: node_id = (col - 1) * (nely + 1) + row
    
    % Get all nodes on the left edge (column 1)
    fixed_col = 1;
    fixed_rows = 1:(nely + 1);
    fixed_node_ids = (fixed_col - 1) * (nely + 1) + fixed_rows;
    
    % Get both x and y degrees of freedom for these nodes.
    % Convention: x-DOF = 2*node_id - 1; y-DOF = 2*node_id.
    fixed_dofs_x = 2 * fixed_node_ids' - 1;
    fixed_dofs_y = 2 * fixed_node_ids';
    fixed_dofs = sort([fixed_dofs_x; fixed_dofs_y]);

%% 5. Define Load Conditions
    % Apply a concentrated vertical load over 3 nodes at the center of the U-beam's opening.
    NUM_LOAD_POINTS = 3;
    LOAD_PER_POINT = -1; % Giá trị lực tại mỗi điểm (âm = hướng xuống)
    
    load_col = nelx + 1; % Tải trọng đặt ở cột nút ngoài cùng bên phải

    % Tìm hàng của nút ở chính giữa theo chiều dọc
    center_load_row = round(nely / 2) + 1;
    
    % Lấy các hàng của nút trung tâm và các nút lân cận trên/dưới
    offset = floor(NUM_LOAD_POINTS / 2);
    load_node_rows = (center_load_row - offset):(center_load_row + offset);
    
    % Tính toán ID cho các nút này
    load_node_ids = (load_col - 1) * (nely + 1) + load_node_rows;
    
    % Lực tác dụng theo phương đứng (y), tương ứng với bậc tự do chẵn
    load_dofs = 2 * load_node_ids'; % Chuyển vị thành vector cột
   
    % Gán giá trị lực cho 3 điểm
    load_vals = repmat(LOAD_PER_POINT, NUM_LOAD_POINTS, 1);
 
%% 6. Display and Visualize
    fprintf('--- U-Shaped Beam Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Spine Width: %d, Arm Height: %d\n', SPINE_WIDTH, ARM_HEIGHT);
    fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
    fprintf('Load applied at %d points, value per point: %.2f\n', NUM_LOAD_POINTS, LOAD_PER_POINT);

    % Visualize boundary conditions if requested
    if plot_flag
        % This assumes a visualization function is available.
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'U-Shaped Beam', designer_mask);
    end
end