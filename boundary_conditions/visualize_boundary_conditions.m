function visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, title_str, varargin)
% VISUALIZE_BOUNDARY_CONDITIONS Plot mesh with boundary conditions
%
%   VISUALIZE_BOUNDARY_CONDITIONS(NELX, NELY, FIXED_DOFS, LOAD_DOFS, LOAD_VALS, TITLE_STR)
%   creates a visualization of the mesh with fixed supports and load locations.
%
%   VISUALIZE_BOUNDARY_CONDITIONS(..., CUTOUT_X, CUTOUT_Y) also displays a
%   cutout region in the top-right corner (for L-bracket problems).

    figure('Position', [100, 100, 800, 450]); % Adjusted height for better aspect ratio
    hold on;
    
    % Create mesh grid
    [X, Y] = meshgrid(0:nelx, 0:nely);
    
    % Plot the full grid domain lightly
    plot(X, Y, ':', 'Color', [0.8 0.8 0.8]);
    plot(X', Y', ':', 'Color', [0.8 0.8 0.8]);
    
    % Correctly convert DOFs to node coordinates based on COLUMN-WISE numbering.
    fixed_nodes = unique(ceil(fixed_dofs/2));
    fixed_x = floor((fixed_nodes - 1) / (nely + 1));
    fixed_y = mod(fixed_nodes - 1, nely + 1);
    
    % Plot fixed supports (red triangles)
    plot(fixed_x, fixed_y, 'r^', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Fixed Support');
    
    % Plot load locations with arrows
    load_color = [0, 0.4, 0.8]; % A nice blue
    arrow_scale = 0.05 * max(nelx, nely); % Scale arrow size relative to domain
    
    for i = 1:length(load_dofs)
        current_node = ceil(load_dofs(i)/2);
        node_x = floor((current_node - 1) / (nely + 1));
        node_y = mod(current_node - 1, nely + 1);
        
        dx = 0; dy = 0;
        if mod(load_dofs(i), 2) == 1 % x-direction
            dx = sign(load_vals(i)) * arrow_scale;
        else % y-direction
            dy = sign(load_vals(i)) * arrow_scale;
        end
        
        % Increased LineWidth from 2 to 3 and MaxHeadSize from 0.5 to 0.8
        if dy < 0
            quiver(node_x, node_y + dy*(-1.5), dx, dy, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'DisplayName', 'Load', 'HandleVisibility', 'off');
        else
            quiver(node_x, node_y, dx, dy, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'DisplayName', 'Load', 'HandleVisibility', 'off');
        end
    end
    % Add a single representative quiver for the legend
    quiver(NaN, NaN, 1, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'DisplayName', 'Load');

    % Check for cutout parameters
    if ~isempty(varargin) && nargin >= 7
        cutout_x = varargin{1};
        cutout_y = varargin{2};
        
        % The patch command that drew the gray inactive region is now commented out.
        % patch_x = [nelx - cutout_x, nelx,            nelx,            nelx - cutout_x];
        % patch_y = [nely - cutout_y, nely - cutout_y, nely,            nely];
        % patch(patch_x, patch_y, [0.92, 0.92, 0.92], 'EdgeColor', 'none', 'DisplayName', 'Inactive Region');
        
        % Draw the active L-shape boundary (this part remains)
        plot([0, nelx, nelx, nelx-cutout_x, nelx-cutout_x, 0, 0], ...
             [0, 0, nely-cutout_y, nely-cutout_y, nely, nely, 0], ...
             'k-', 'LineWidth', 1.5, 'DisplayName', 'Active Domain');

    else
        % If no cutout, draw the full rectangular domain boundary
        plot([0, nelx, nelx, 0, 0], [0, 0, nely, nely, 0], 'k-', 'LineWidth', 1.5, 'DisplayName', 'Active Domain');
    end
    
    % Format plot
    axis equal;
    axis tight;
    padding_x = 0.1 * nelx;
    padding_y = 0.1 * nely;
    xlim([-padding_x, nelx + padding_x]);
    ylim([-padding_y, nely + padding_y]);
    xlabel('X-coordinate');
    ylabel('Y-coordinate');
    title(sprintf('%s: Boundary Conditions', title_str));
    grid on;
    box on;
    hold off;
end