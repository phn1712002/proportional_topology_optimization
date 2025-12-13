function [fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(plot_flag)
% L_BRACKET_BOUNDARY Define boundary conditions for an L-bracket problem
%
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, CUTOUT_X, CUTOUT_Y] = L_BRACKET_BOUNDARY(PLOT_FLAG)
%   returns the boundary conditions for an L-bracket topology optimization
%   problem. The bracket is fixed on the top edge and has a horizontal
%   inward point load at the middle of the right edge.
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
%   cutout_x   - Width of cutout region
%   cutout_y   - Height of cutout region
%
% Description:
%   - Fixed boundary: All DOFs on the top edge (y = nely)
%   - Load: Horizontal inward force at the middle of the right edge
%
% Example:
%   [fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary();
%   [fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(true);

    % Set default plot_flag to false if not provided
    if nargin < 1
        plot_flag = false;
    end

    % Constants
    NELX = 100;           % Number of elements in x-direction
    NELY = 40;            % Number of elements in y-direction
    CUTOUT_X = 40;        % Width of cutout
    CUTOUT_Y = 40;        % Height of cutout
    LOAD_VAL = -1;        % Inward load (negative x-direction)
    
    % Mesh parameters (outputs)
    nelx = NELX;
    nely = NELY;
    cutout_x = CUTOUT_X;
    cutout_y = CUTOUT_Y;

    % Fixed DOFs: all degrees of freedom on the top edge
    fixed_nodes = [];
    for i = 1:(nelx + 1)
        node_id = i * (nely + 1);  % Top edge nodes
        fixed_nodes = [fixed_nodes, node_id];
    end
    
    % Convert node IDs to DOFs (x and y directions)
    fixed_dofs = [2 * fixed_nodes - 1, 2 * fixed_nodes];
    
    % Load application point: middle of the right edge
    mid_right_node = (nelx + 1) * (nely + 1) - floor(nely / 2);
    load_dof = 2 * mid_right_node - 1;  % x-direction DOF
    load_dofs = load_dof;
    load_vals = LOAD_VAL;  % Inward load (negative x-direction)
    
    % Display configuration information
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs: %d \n', length(fixed_dofs));
    fprintf('Cutout: %d x %d \n', cutout_x, cutout_y);
    fprintf('Load at node %d (dof %d) = %.2f (horizontal inward)\n', ...
            mid_right_node, load_dof, load_vals);
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'L-Bracket');
    end
end
