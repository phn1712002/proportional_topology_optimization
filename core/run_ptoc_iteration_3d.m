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
    
    % 8. Plot intermediate results (simplified for 3D)
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        clf;
        set(gcf, 'WindowState', 'maximized');
        
        % 3D visualization using stlPlot from lib/stlTools
        subplot(2,2,1);
        if nelz > 1
            % Create isosurface at density = 0.5
            [X,Y,Z] = meshgrid(1:nelx, 1:nely, 1:nelz);
            [faces, verts] = isosurface(X, Y, Z, rho_filtered, 0.5);
            
            % Scale vertices to physical dimensions
            verts(:,1) = verts(:,1) * dx;
            verts(:,2) = verts(:,2) * dy;
            verts(:,3) = verts(:,3) * dz;
            
            % Use stlPlot to visualize the 3D model
            stlPlot(verts, faces, sprintf('3D Model (iter %d)', iter));
        else
            % 2D case (single layer)
            imagesc(rho_filtered(:,:,1)); axis equal tight; colorbar;
            title('Filtered Density');
            axis xy;
            xlabel('x'); ylabel('y');
        end
        
        subplot(2,2,2);
        plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5); 
        grid on; title('Total Compliance'); xlabel('Iteration'); ylabel('Compliance');
        
        subplot(2,2,3);
        plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5); 
        grid on; title('Volume'); xlabel('Iteration'); ylabel('Volume');
        yline(TM, 'k--', 'Target Volume');
        
        subplot(2,2,4);
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
