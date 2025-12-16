function [rho_opt, history, sigma_vm, sigma_max, converged, iter] = ...
    run_ptos_iteration_3d(rho, TM_init, nelx, nely, nelz, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, sigma_allow, tau, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, dz, ...
                       rho_min, rho_max, coef_inc_dec, conv_tol, design_mask, problem_name)
% RUN_PTOS_ITERATION_3D Execute the main PTOs iteration loop for 3D problems
%
%   [RHO_OPT, HISTORY, SIGMA_VM, SIGMA_MAX, CONVERGED, ITER] = ...
%       RUN_PTOS_ITERATION_3D(RHO, TM_INIT, NELX, NELY, NELZ, P, E0, NU, ...
%                          LOAD_DOFS, LOAD_VALS, FIXED_DOFS, ...
%                          Q, R_MIN, ALPHA, SIGMA_ALLOW, TAU, MAX_ITER, ...
%                          PLOT_FLAG, PLOT_FREQUENCY, DX, DY, DZ, ...
%                          RHO_MIN, RHO_MAX, COEF_INC_DEC, CONV_TOL, DESIGN_MASK, PROBLEM_NAME)
%   runs the stress-constrained PTOs algorithm for 3D topology optimization.
%
% Inputs:
%   rho                     - Initial density field (nely x nelx x nelz)
%   TM_init                 - Initial target material amount
%   nelx, nely, nelz        - Mesh dimensions
%   p, E0, nu               - Material properties (SIMP exponent, Young's modulus, Poisson's ratio)
%   load_dofs               - Degrees of freedom where loads are applied
%   load_vals               - Corresponding load values
%   fixed_dofs              - Degrees of freedom with fixed (zero) displacement
%   q                       - Stress exponent for material distribution
%   r_min                   - Filter radius (in element units)
%   alpha                   - Move limit
%   sigma_allow             - Allowable von Mises stress
%   tau                     - Stress tolerance band
%   max_iter                - Maximum iterations
%   conv_tol                - Convergence error
%   design_mask             - Design area matrix (nely x nelx x nelz)
%   plot_flag               - Whether to show plots (true/false)
%   plot_frequency          - Frequency of new plots
%   dx, dy, dz              - Element size (default: 1, 1, 1)
%   rho_min, rho_max        - Density bounds
%   coef_inc_dec            - Material increase/decrease coefficient (0->1) (default: 0.05)
%   problem_name            - Name of problem for display (e.g., '3D Cantilever')
%
% Outputs:
%   rho_opt                 - Final optimal density field (nely x nelx x nelz)
%   history                 - Structure with iteration history
%   sigma_vm                - Final von Mises stress field (nely x nelx x nelz)
%   sigma_max               - Final maximum von Mises stress
%   converged               - Convergence flag (true/false)
%   iter                    - Final iteration number
%
% History fields:
%   iteration               - Iteration numbers
%   compliance              - Compliance values
%   volume                  - Volume values
%   sigma_max               - Maximum stress values
%   TM                      - Target material values
%   change                  - Maximum density change values

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.sigma_max = [];
history.TM = [];
history.change = [];

% Inner loop iterations (hardcoded as in original scripts)
inner_max = 20;

% Main iteration loop
for iter = 1:max_iter
    fprintf('%s PTOs Iteration %d\n', problem_name, iter);
    
    % 1. 3D FEA analysis
    [U, K_global] = FEA_analysis_3d(nelx, nely, nelz, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute stresses for 3D
    sigma_vm = compute_stress_3d(nelx, nely, nelz, rho, p, E0, nu, U);
    sigma_max = max(sigma_vm(:));
    
    % 3. Adjust target material based on stress constraint
    if sigma_max >= (1 + tau) * sigma_allow
        % Too much stress → increase material
        TM_init = TM_init * (1 + coef_inc_dec);
        fprintf('  Stress %.3f > allowable band → increase TM to %.4f\n', sigma_max, TM_init);  
    else
        % Too little stress → decrease material
        TM_init = TM_init * (1 - coef_inc_dec);
        fprintf('  Stress %.3f < allowable band → decrease TM to %.4f\n', sigma_max, TM_init);
    end
    
    % 4. Material redistribution loop
    RM = TM_init;  % Remaining material
    rho_distributed = zeros(nely, nelx, nelz);
    
    % Inner loop: distribute material proportionally to stress
    for inner = 1:inner_max
        % Compute optimal density for current RM
        % Note: volume parameter is 1.0 for unit cube elements
        rho_opt_iter = material_distribution_PTOs_3d(sigma_vm, RM, q, 1.0, rho_min, rho_max, design_mask);
        
        % Sum of allocated density (only in design region)
        allocated = sum(rho_opt_iter(design_mask == 1));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate distributed density
        rho_distributed = rho_distributed + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM_init
            break;
        end
    end
    
    % 5. 3D Density filtering
    rho_filtered = density_filter_3d(rho_distributed, r_min, nelx, nely, nelz, dx, dy, dz);
    
    % 6. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, rho_min, rho_max);
    
    % Ensure density is zero in cutout region
    rho_new(design_mask == 0) = 0;
    
    % 7. Compute convergence metrics
    % Only consider design region for change calculation
    change_design = abs(rho_new(design_mask == 1) - rho(design_mask == 1));
    change = max(change_design(:));
    compliance = U' * K_global * U;
    volume = sum(rho_new(design_mask == 1));  % Volume only in design region
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.sigma_max(end+1) = sigma_max;
    history.TM(end+1) = TM_init;
    history.change(end+1) = change;
    
    % 8. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, conv_tol, 'PTOs', sigma_max, sigma_allow, tau);
    
    % 9. Plot intermediate results for 3D
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        
        figure(1);
        clf; % Clear the current figure
        set(gcf, 'WindowState', 'maximized', 'Name', sprintf('%s - Iteration %d', problem_name, iter));

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
            colormap(jet);
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

        % Subplot 4: Compliance history
        subplot(2,3,4);
        plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5);
        grid on; title('Compliance'); xlabel('Iteration'); ylabel('Compliance');
        xlim([0, max_iter]);

        % Subplot 5: Volume history
        subplot(2,3,5);
        plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5);
        grid on; title('Volume'); xlabel('Iteration'); ylabel('Volume');
        xlim([0, max_iter]);

        % Subplot 6: Max stress history with allowable band
        subplot(2,3,6);
        plot(history.iteration, history.sigma_max, 'g-s', 'LineWidth', 1.5);
        hold on;
        yline(sigma_allow * (1 - tau), 'r--', 'Lower Bound');
        yline(sigma_allow * (1 + tau), 'r--', 'Upper Bound');
        yline(sigma_allow, 'k-', 'Allowable');
        hold off;
        grid on; title(sprintf('Max Stress (Current: %.2f)', sigma_max)); 
        xlabel('Iteration'); ylabel('Max Stress');
        xlim([0, max_iter]);
        
        drawnow; % Update the figure window
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('%s PTOs converged after %d iterations.\n', problem_name, iter);
        break;
    end
end

% Final optimal density and stress
rho_opt = rho;
% Recompute final stress for output
sigma_vm = compute_stress_3d(nelx, nely, nelz, rho_opt, p, E0, nu, U);
sigma_max = max(sigma_vm(:));

end
