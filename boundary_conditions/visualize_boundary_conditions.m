function visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, title_str, designer_mask)
% VISUALIZE_BOUNDARY_CONDITIONS Plot mesh with boundary conditions (no domain outline)

    figure('Position', [100, 100, 800, 450]);
    hold on;

    % --- DOMAIN VISUALIZATION (NO OUTLINE) ---
    if nargin >= 7 && ~isempty(designer_mask)
        imagesc([0, nelx], [0, nely], designer_mask');
        set(gca, 'YDir', 'normal');
        colormap([0.92, 0.92, 0.92; 1, 1, 1]); % inactive / active

        if numel(unique(designer_mask)) > 1
            patch(NaN, NaN, [0.92, 0.92, 0.92], ...
                  'DisplayName', 'Inactive Region');
        end
    end

    % --- MESH GRID ---
    [X, Y] = meshgrid(0:nelx, 0:nely);
    plot(X, Y, ':', 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');
    plot(X', Y', ':', 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');

    % --- FIXED SUPPORTS ---
    fixed_nodes = unique(ceil(fixed_dofs/2));
    fixed_x = floor((fixed_nodes - 1) / (nely + 1));
    fixed_y = mod(fixed_nodes - 1, nely + 1);
    plot(fixed_x, fixed_y, 'r^', ...
        'MarkerSize', 8, 'MarkerFaceColor', 'r');

    % --- LOADS ---
    load_color = [0, 0.4, 0.8];
    arrow_scale = 0.05 * max(nelx, nely);

    for i = 1:length(load_dofs)
        current_node = ceil(load_dofs(i)/2);
        node_x = floor((current_node - 1) / (nely + 1));
        node_y = mod(current_node - 1, nely + 1);

        dx = 0; dy = 0;
        if mod(load_dofs(i), 2) == 1
            dx = sign(load_vals(i)) * arrow_scale;
        else
            dy = sign(load_vals(i)) * arrow_scale;
        end

        quiver(node_x, node_y, dx, dy, 0, ...
            'Color', load_color, ...
            'LineWidth', 3, ...
            'MaxHeadSize', 0.8, ...
            'HandleVisibility', 'off');
    end

    quiver(NaN, NaN, 1, 0, ...
        'Color', load_color, ...
        'LineWidth', 3, ...
        'MaxHeadSize', 0.8);

    % --- FORMAT ---
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
