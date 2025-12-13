function visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, title_str)
% VISUALIZE_BOUNDARY_CONDITIONS Plot mesh with boundary conditions
%
%   VISUALIZE_BOUNDARY_CONDITIONS(NELX, NELY, FIXED_DOFS, LOAD_DOFS, LOAD_VALS, TITLE_STR)
%   creates a visualization of the mesh with fixed supports and load locations.
%
% Inputs:
%   nelx      - Number of elements in x-direction
%   nely      - Number of elements in y-direction
%   fixed_dofs - Fixed degrees of freedom
%   load_dofs  - Load degrees of freedom
%   load_vals  - Load values
%   title_str  - Title for the plot

    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    % Create mesh grid
    [X, Y] = meshgrid(0:nelx, 0:nely);
    
    % Plot mesh
    plot(X, Y, 'k-', 'LineWidth', 0.5);
    plot(X', Y', 'k-', 'LineWidth', 0.5);
    
    % Plot nodes
    plot(X(:), Y(:), 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
    
    % Identify fixed nodes from fixed_dofs
    fixed_nodes = unique(ceil(fixed_dofs/2));
    fixed_x = X(fixed_nodes);
    fixed_y = Y(fixed_nodes);
    
    % Plot fixed supports (red triangles)
    plot(fixed_x, fixed_y, 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Fixed Support');
    
    % Identify load nodes from load_dofs
    load_nodes = unique(ceil(load_dofs/2));
    load_x = X(load_nodes);
    load_y = Y(load_nodes);
    
    % Plot load locations with arrows (enhanced visibility - direction only)
    % Normalize load values for consistent arrow scaling
    max_load = max(abs(load_vals));
    if max_load == 0
        max_load = 1;  % Avoid division by zero
    end
    
    % Use a distinct color for loads
    load_color = [0, 0.5, 1];  % Bright blue
    
    % Track if legend entry has been added
    legend_load_added = false;
    
    for i = 1:length(load_nodes)
        % Determine direction based on DOF (odd = x, even = y)
        if mod(load_dofs(i), 2) == 1  % x-direction
            % Scale arrow length by load magnitude (0.5 to 1.0 of mesh size)
            dx = (load_vals(i) / max_load) * 0.8;
            dy = 0;
            
            % Only add to legend for first load arrow
            if ~legend_load_added
                quiver(load_x(i), load_y(i), dx, 0, 'Color', load_color, ...
                       'LineWidth', 15, 'MaxHeadSize', 15, 'DisplayName', 'Load');
                legend_load_added = true;
            else
                quiver(load_x(i), load_y(i), dx, 0, 'Color', load_color, ...
                       'LineWidth', 15, 'MaxHeadSize', 15, 'HandleVisibility', 'off');
            end
                 
        else  % y-direction
            % Scale arrow length by load magnitude (0.5 to 1.0 of mesh size)
            dx = 0;
            dy = (load_vals(i) / max_load) * 0.8;
            
            % Only add to legend for first load arrow
            if ~legend_load_added
                quiver(load_x(i), load_y(i), 0, dy, 'Color', load_color, ...
                       'LineWidth', 15, 'MaxHeadSize', 15, 'DisplayName', 'Load');
                legend_load_added = true;
            else
                quiver(load_x(i), load_y(i), 0, dy, 'Color', load_color, ...
                       'LineWidth', 15, 'MaxHeadSize', 15, 'HandleVisibility', 'off');
            end
        end
    end
    
    % Format plot
    axis equal;
    xlim([-0.5, nelx+0.5]);
    ylim([-0.5, nely+0.5]);
    xlabel('x');
    ylabel('y');
    title(sprintf('%s Boundary Conditions\nMesh: %d x %d', title_str, nelx, nely));
    grid on;
    hold off;
end
