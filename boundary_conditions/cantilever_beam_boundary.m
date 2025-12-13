function [fixed_dofs, load_dofs, load_vals, nelx, nely] = cantilever_beam_boundary(plot_flag)
% CANTILEVER_BEAM_BOUNDARY Define boundary conditions for a cantilever beam problem
%
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY] = cantilever_beam_boundary(PLOT_FLAG)
%   returns the boundary conditions for a cantilever beam topology
%   optimization problem. The beam is fixed on the left edge and has a
%   downward point load at the top-right corner.
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
%   - Fixed boundary: All DOFs on the left edge (x = 0)
%   - Load: Vertical downward force at the top-right corner node
%
% Example:
%   [fixed_dofs, load_dofs, load_vals, nelx, nely] = cantilever_beam_boundary();
%   [fixed_dofs, load_dofs, load_vals, nelx, nely] = cantilever_beam_boundary(true);

    % Set default plot_flag to false if not provided
    if nargin < 1
        plot_flag = false;
    end

    % Constants
    NELX = 120;      % Number of elements in x-direction
    NELY = 60;       % Number of elements in y-direction
    LOAD_VAL = -1;   % Downward load (negative y-direction)
    
    % Mesh parameters (outputs)
    nelx = NELX;
    nely = NELY;

    % Fixed DOFs: all degrees of freedom on the left edge
    fixed_dofs = 1:2*(nely+1);
    
    % Load application point: top-right corner node
    top_right_node = (nelx + 1) * (nely + 1);
    load_dof = 2 * top_right_node;  % y-direction DOF
    load_dofs = load_dof;
    load_vals = LOAD_VAL;  % Downward load (negative y-direction)
    
    % Display configuration information
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs: %d (left edge)\n', length(fixed_dofs));
    fprintf('Load at node %d (dof %d) = %.2f\n', top_right_node, load_dof, load_vals);
    
    % Visualize boundary conditions if requested
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'Cantilever Beam');
    end
end
