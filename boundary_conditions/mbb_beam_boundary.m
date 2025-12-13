function [fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(plot_flag)
% MBB_BEAM_BOUNDARY Define boundary conditions for an MBB beam problem (half symmetry)
%
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY] = MBB_BEAM_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions for an MBB beam topology optimization
%   problem with half symmetry. The beam has symmetry on the left edge,
%   a roller support at the right bottom corner, and a point load at the
%   top middle.
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of boundary
%               conditions. Default is false.
%
% Outputs:
%   fixed_dofs - Degrees of freedom with fixed (zero) displacement
%   load_dofs  - Degrees of freedom where loads are applied
%   load_vals  - Corresponding load values
%   nelx       - Number of elements in x-direction
%   nely       - Number of elements in y-direction
%
% Description:
%   - Symmetry boundary: Left edge fixed in x-direction, free in y-direction
%   - Roller support: Right bottom corner fixed in y-direction
%   - Load: Vertical downward force at the top middle
%
% Example:
%   [fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary();
%   [fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(true);

    % Set default plot_flag to false if not provided
    if nargin < 1
        plot_flag = false;
    end

    % Constants
    NELX = 120;      % Number of elements in x-direction
    NELY = 40;       % Number of elements in y-direction
    LOAD_VAL = -1;   % Downward load (negative y-direction)
    
    % Mesh parameters (outputs)
    nelx = NELX;
    nely = NELY;

    % Fixed DOFs: left edge x-direction (symmetry condition)
    fixed_dofs_x = 1:2:2*(nely + 1);  % x-direction DOFs of left edge
    
    % Roller support: right bottom corner y-direction
    right_bottom_node = (nelx + 1) * (nely + 1);
    fixed_dofs_y = 2 * right_bottom_node;  % y-direction DOF
    
    % Combine fixed DOFs
    fixed_dofs = [fixed_dofs_x, fixed_dofs_y];
    
    % TODO: Load at top middle - verify calculation
    % Find the node at the top middle (center of top edge)
    mid_col = floor((nelx + 1) / 2) + 1;  % Column index (1-based)
    top_row = nely + 1;                   % Row index (top row, 1-based)
    
    % Linear node index: (row-1)*(num_cols) + col
    top_mid_node = (top_row - 1) * (nelx + 1) + mid_col;
    
    load_dof = 2 * top_mid_node;  % y-direction DOF
    load_dofs = load_dof;
    load_vals = LOAD_VAL;  % Downward load (negative y-direction)
    
    % Display configuration information
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs: %d\n', length(fixed_dofs));
    fprintf('Load at node %d (dof %d) = %.2f\n', ...
            top_mid_node, load_dof, load_vals);
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'MBB Beam');
    end
end
