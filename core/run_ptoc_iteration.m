function [rho_opt, history, converged, iter] = ...
    run_ptoc_iteration(rho, TM, nelx, nely, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, ...
                       rho_min, rho_max, conv_tol, design_mask, problem_name)
% RUN_PTOC_ITERATION Execute the main PTOc iteration loop
%
%   [RHO_OPT, HISTORY, CONVERGED, ITER] = ...
%       RUN_PTOC_ITERATION(RHO, TM, NELX, NELY, P, E0, NU, ...
%                          LOAD_DOFS, LOAD_VALS, FIXED_DOFS, ...
%                          Q, R_MIN, ALPHA, MAX_ITER, ...
%                          PLOT_FLAG, PLOT_FREQUENCY, DX, DY, ...
%                          RHO_MIN, RHO_MAX, CONV_TOL, PROBLEM_NAME)
%   runs the compliance minimization PTOc algorithm for topology optimization.
%
% Inputs:
%   rho                     - Initial density field (nely x nelx)
%   TM                      - Target material amount (fixed for PTOc)
%   nelx, nely              - Mesh dimensions
%   p, E0, nu               - Material properties (SIMP exponent, Young's modulus, Poisson's ratio)
%   load_dofs               - Degrees of freedom where loads are applied
%   load_vals               - Corresponding load values
%   fixed_dofs              - Degrees of freedom with fixed (zero) displacement
%   q                       - Compliance exponent for material distribution
%   r_min                   - Filter radius (in element units)
%   alpha                   - Move limit
%   max_iter                - Maximum iterations
%   conv_tol                - Convergence error
%   plot_flag               - Whether to show plots (true/false)
%   plot_frequency          - Frequency of new plots
%   dx, dy                  - Element size (default: 1, 1)
%   rho_min, rho_max        - Density bounds
%   problem_name            - Name of problem for display (e.g., 'L-Bracket')
%
% Outputs:
%   rho_opt                 - Final optimal density field
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
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute element compliance
    C = compute_compliance(nelx, nely, rho, p, E0, nu, U, K_global);
    
    % 3. Material redistribution loop
    RM = TM;  % Remaining material (fixed target)
    rho_distributed = zeros(nely, nelx);  % Accumulated distributed density 
    
    % Inner loop: distribute material proportionally to compliance
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOc(C, RM, q, rho_min, rho_max);
        
        % Sum of allocated density
        allocated = sum(rho_opt_iter(:));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate distributed density
        rho_distributed = rho_distributed + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM
            break;
        end
    end
    
    % 4. Density filtering
    rho_filtered = density_filter(rho_distributed, r_min, nelx, nely, dx, dy);
    
    % 5. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, rho_min, rho_max);
    
    % 6. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.change(end+1) = change;
    
    % 7. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, conv_tol, 'PTOc');
    
    % 8. Plot intermediate results
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        clf;
        set(gcf, 'WindowState', 'maximized');
        
        subplot(2,3,1);
        imagesc(rho_new); axis equal tight; colorbar; 
        title(sprintf('Density (iter %d)', iter));
        axis xy;
        xlabel('x'); ylabel('y');
        
        subplot(2,3,2);
        imagesc(C); axis equal tight; colorbar; 
        title('Element Compliance');
        axis xy;
        xlabel('x'); ylabel('y');
        
        subplot(2,3,3);
        plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5); 
        grid on; title('Total Compliance'); xlabel('Iteration'); ylabel('Compliance');
        
        subplot(2,3,4);
        plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5); 
        grid on; title('Volume'); xlabel('Iteration'); ylabel('Volume');
        yline(TM, 'k--', 'Target Volume');
        
        subplot(2,3,5);
        semilogy(history.iteration, history.change, 'm-d', 'LineWidth', 1.5); 
        grid on; title('Density Change (log)'); xlabel('Iteration'); ylabel('Max Change');
        yline(1e-3, '--', 'Tolerance');
        
        subplot(2,3,6);
        imagesc(rho_filtered); axis equal tight; colorbar; 
        title('Filtered Density');
        axis xy;
        xlabel('x'); ylabel('y');
        
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
