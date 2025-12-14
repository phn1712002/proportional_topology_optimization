function visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, title_str, designer_mask)
% VISUALIZE_BOUNDARY_CONDITIONS Plot mesh with boundary conditions.
%
%   VISUALIZE_BOUNDARY_CONDITIONS(NELX, NELY, FIXED_DOFS, LOAD_DOFS, LOAD_VALS, TITLE_STR)
%   creates a visualization of a rectangular mesh with its boundary conditions.
%
%   VISUALIZE_BOUNDARY_CONDITIONS(..., DESIGNER_MASK) also shades the
%   inactive (void) regions of the design domain based on the provided logical mask.

    figure('Position', [100, 100, 800, 450]);
    hold on;
    
    % --- DOMAIN VISUALIZATION (REVISED) ---
    if nargin >= 7 && ~isempty(designer_mask)
        % Use imagesc to draw the background based on the mask.
        imagesc([0, nelx], [0, nely], designer_mask');
        set(gca, 'YDir', 'normal');
        colormap([0.92, 0.92, 0.92; 1, 1, 1]); % [inactive, active]

        % <<< GIẢI PHÁP: Kiểm tra xem mask có phải là một hình chữ nhật đặc hay không >>>
        if numel(unique(designer_mask)) > 1
            % Trường hợp phức tạp (VD: L-bracket): có cả vùng active và inactive
            % Tạo legend cho vùng inactive
            patch(NaN, NaN, [0.92, 0.92, 0.92], 'DisplayName', 'Inactive Region');
            
            % Vẽ đường viền chính xác quanh vùng active (hình L) bằng contour
            x_centers = 0.5:1:nelx-0.5;
            y_centers = 0.5:1:nely-0.5;
            contour(x_centers, y_centers, double(designer_mask'), [0.5 0.5], 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
            
            % Vẽ đường viền bên ngoài của toàn bộ miền để làm khung
            plot([0, nelx, nelx, 0, 0], [0, 0, nely, nely, 0], 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
        else
            % Trường hợp đơn giản (VD: Cantilever): toàn bộ vùng là active
            % Chỉ cần vẽ một đường viền hình chữ nhật
            plot([0, nelx, nelx, 0, 0], [0, 0, nely, nely, 0], 'k-', 'LineWidth', 1.5, 'DisplayName', 'Active Domain');
        end

    else
        % Trường hợp không có mask: mặc định là miền chữ nhật
        plot([0, nelx, nelx, 0, 0], [0, 0, nely, nely, 0], 'k-', 'LineWidth', 1.5, 'DisplayName', 'Active Domain');
    end

    % --- MESH GRID AND BOUNDARY CONDITIONS ---
    [X, Y] = meshgrid(0:nelx, 0:nely);
    plot(X, Y, ':', 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');
    plot(X', Y', ':', 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');
    
    fixed_nodes = unique(ceil(fixed_dofs/2));
    fixed_x = floor((fixed_nodes - 1) / (nely + 1));
    fixed_y = mod(fixed_nodes - 1, nely + 1);
    plot(fixed_x, fixed_y, 'r^', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Fixed Support');
    
    load_color = [0, 0.4, 0.8];
    arrow_scale = 0.05 * max(nelx, nely);
    
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
        
        if dy < 0
            quiver(node_x, node_y + dy*(-1.5), dx, dy, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'HandleVisibility', 'off');
        else
            quiver(node_x, node_y, dx, dy, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'HandleVisibility', 'off');
        end
    end
    quiver(NaN, NaN, 1, 0, 'Color', load_color, 'LineWidth', 3, 'MaxHeadSize', 0.8, 'DisplayName', 'Load');

    % --- FORMAT PLOT ---
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