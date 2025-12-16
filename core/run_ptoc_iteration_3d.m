function [rho_opt, history, converged, iter] = ...
    run_ptoc_iteration_3d(rho, TM, nelx, nely, nelz, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, dz, ...
                       rho_min, rho_max, conv_tol, design_mask, problem_name)
% RUN_PTOC_ITERATION_3D Execute the main PTOc iteration loop for 3D problems
%
%   [RHO_OPT, HISTORY, CONVERGED, ITER] = ...
%       RUN_PTOC_ITERATION_3D(RHO, TM, NELX, NELY, NELZ, P, E0, NU, ...
%                          LOAD_DOFS, LOAD_VALS, FIXED_DOFS, ...
%                          Q, R_MIN, ALPHA, MAX_ITER, ...
%                          PLOT_FLAG, PLOT_FREQUENCY, DX, DY, DZ, ...
%                          RHO_MIN, RHO_MAX, CONV_TOL, DESIGN_MASK, PROBLEM_NAME)
%   runs the compliance minimization PTOc algorithm for 3D topology optimization.
%
% Inputs:
%   rho                     - Initial density field (nely x nelx x nelz)
%   TM                      - Target material amount (fixed for PTOc)
%   nelx, nely, nelz        - Mesh dimensions
%   p, E0, nu               - Material properties (SIMP exponent, Young's modulus, Poisson's ratio)
%   load_dofs               - Degrees of freedom where loads are applied
%   load_vals               - Corresponding load values
%   fixed_dofs              - Degrees of freedom with fixed (zero) displacement
%   q                       - Compliance exponent for material distribution
%   r_min                   - Filter radius (in element units)
%   alpha                   - Move limit
%   max_iter                - Maximum iterations
%   conv_tol                - Convergence error
%   design_mask             - Design area matrix (nely x nelx x nelz)
%   plot_flag               - Whether to show plots (true/false)
%   plot_frequency          - Frequency of new plots
%   dx, dy, dz              - Element size (default: 1, 1, 1)
%   rho_min, rho_max        - Density bounds
%   problem_name            - Name of problem for display (e.g., '3D Cantilever')
%
% Outputs:
%   rho_opt                 - Final optimal density distribution (nely x nelx x nelz)
%   history                 - Structure with iteration history
%   converged               - Convergence flag (true/false)
%   iter                    - Final iteration number
%
% History fields:
%   iteration               - Iteration numbers
%   compliance              - Compliance values
%   volume                  - Volume values
%   change                  - Maximum density change values
%
% Note: PTOc maintains fixed target material (TM) throughout optimization,
% unlike PTOs which adjusts TM based on stress constraints.

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.change = [];

% Inner loop iterations (hardcoded as in original scripts)
inner_max = 20;

% Main iteration loop
for iter = 1:max_iter
    fprintf('%s PTOc Iteration %d\n', problem_name, iter);
    
    % 1. 3D FEA analysis
    [U, K_global] = FEA_analysis_3d(nelx, nely, nelz, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute element compliance for 3D
    C = compute_compliance_3d(nelx, nely, nelz, rho, p, E0, nu, U, K_global);
    
    % 3. Material redistribution loop
    RM = TM;  % Remaining material (fixed target)
    rho_distributed = zeros(nely, nelx, nelz);  % Accumulated distributed density 
    
    % Inner loop: distribute material proportionally to compliance
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOc_3d(C, RM, q, rho_min, rho_max, design_mask);
        
        % Sum of allocated density (only in design region)
        allocated = sum(rho_opt_iter(design_mask == 1));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate distributed density
        rho_distributed = rho_distributed + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM
            break;
        end
    end
    
    % 4. 3D Density filtering
    rho_filtered = density_filter_3d(rho_distributed, r_min, nelx, nely, nelz, dx, dy, dz);
    
    % 5. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, rho_min, rho_max);
    
    % Ensure density is zero in cutout region
    rho_new(design_mask == 0) = 0;
    
    % 6. Compute convergence metrics
    % Only consider design region for change calculation
    change_design = abs(rho_new(design_mask == 1) - rho(design_mask == 1));
    change = max(change_design(:));
    compliance = U' * K_global * U;
    volume = sum(rho_new(design_mask == 1));  % Volume only in design region
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.change(end+1) = change;
    
    % 7. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, conv_tol, 'PTOc');
    
    % 8. Plot intermediate results for 3D
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        
        % Subplot 1: 3D Scatter plot of density (using points)
        subplot(2,3,[1,2,3]);
        
        % Create coordinates for voxel centers
        [X, Y, Z] = meshgrid(1:nelx, 1:nely, 1:nelz);
        
        % Reshape density and coordinates to vectors
        rho_vec = rho_new(:);
        x_vec = X(:);
        y_vec = Y(:);
        z_vec = Z(:);
        
        % Apply threshold to reduce number of points (only show voxels with significant density)
        threshold = rho_min;
        mask = rho_vec > threshold;
        
        if any(mask)
            % Use scatter3 to plot points
            scatter3(x_vec(mask), y_vec(mask), z_vec(mask), 50, rho_vec(mask), 'filled');
            colorbar;
            colormap(gray);
            caxis([rho_min, rho_max]);
            title(sprintf('3D Density (iter %d)', iter));
            xlabel('x'); ylabel('y'); zlabel('z');
            axis equal;
            grid on;
            view(3); % 3D view
            % Set axis limits
            xlim([0.5, nelx+0.5]);
            ylim([0.5, nely+0.5]);
            zlim([0.5, nelz+0.5]);
        else
            % No points above threshold
            text(0.5, 0.5, 0.5, 'No density above threshold', 'HorizontalAlignment', 'center');
            title(sprintf('3D Density (iter %d)', iter));
            xlabel('x'); ylabel('y'); zlabel('z');
            axis equal;
            grid on;
            view(3);
        end

        % --- History Plots (moved to the bottom row) ---
        subplot(2,3,4);
        plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5); 
        grid on; title('Total Compliance'); xlabel('Iteration'); ylabel('Compliance');
        
        subplot(2,3,5);
        plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5); 
        grid on; title('Volume'); xlabel('Iteration'); ylabel('Volume');
        yline(TM, 'k--', 'Target Volume');
        
        subplot(2,3,6);
        semilogy(history.iteration, history.change, 'm-d', 'LineWidth', 1.5); 
        grid on; title('Density Change (log)'); xlabel('Iteration'); ylabel('Max Change');
        yline(1e-3, '--', 'Tolerance');
        
        drawnow;
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('%s PTOc converged after %d iterations.\n', problem_name, iter);
        break;
    end
end

% Final optimal density
rho_opt = rho;

end
