function [rho_opt, history, sigma_vm, sigma_max, converged, iter] = ...
    run_ptos_iteration(rho, TM_init, nelx, nely, p, E0, nu, ...
                       load_dofs, load_vals, fixed_dofs, ...
                       q, r_min, alpha, sigma_allow, tau, max_iter, ...
                       plot_flag, plot_frequency, dx, dy, ...
                       rho_min, rho_max, coef_inc_dec, problem_name)
% RUN_PTOS_ITERATION Execute the main PTOs iteration loop
%
%   [RHO_OPT, HISTORY, SIGMA_VM, SIGMA_MAX, CONVERGED, ITER] = ...
%       RUN_PTOS_ITERATION(RHO, TM_INIT, NELX, NELY, P, E0, NU, ...
%                          LOAD_DOFS, LOAD_VALS, FIXED_DOFS, ...
%                          Q, R_MIN, ALPHA, SIGMA_ALLOW, TAU, MAX_ITER, ...
%                          PLOT_FLAG, PLOT_FREQUENCY, DX, DY, ...
%                          RHO_MIN, RHO_MAX, COEF_INC_DEC, PROBLEM_NAME)
%   runs the stress-constrained PTOs algorithm for topology optimization.
%
% Inputs:
%   rho               - Initial density field (nely x nelx)
%   TM_init           - Initial target material amount
%   nelx, nely        - Mesh dimensions
%   p, E0, nu         - Material properties (SIMP exponent, Young's modulus, Poisson's ratio)
%   load_dofs         - Degrees of freedom where loads are applied
%   load_vals         - Corresponding load values
%   fixed_dofs        - Degrees of freedom with fixed (zero) displacement
%   q                 - Stress exponent for material distribution
%   r_min             - Filter radius (in element units)
%   alpha             - Move limit
%   sigma_allow       - Allowable von Mises stress
%   tau               - Stress tolerance band
%   max_iter          - Maximum iterations
%   plot_flag         - Whether to show plots (true/false)
%   plot_frequency    - Frequency of new plots
%   dx, dy            - Element size (default: 1, 1)
%   rho_min, rho_max  - Density bounds
%   coef_inc_dec      - Material increase/decrease coefficient (0->1) (default: 0.05)
%   problem_name      - Name of problem for display (e.g., 'MBB Beam')
%
% Outputs:
%   rho_opt           - Final optimal density field
%   history           - Structure with iteration history
%   sigma_vm          - Final von Mises stress field
%   sigma_max         - Final maximum von Mises stress
%   converged         - Convergence flag (true/false)
%   iter              - Final iteration number
%
% History fields:
%   iteration         - Iteration numbers
%   compliance        - Compliance values
%   volume            - Volume values
%   sigma_max         - Maximum stress values
%   TM                - Target material values
%   change            - Maximum density change values

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
    fprintf('%s PTOs Iteration %d: TM = %.4f\n', problem_name, iter, TM_init);
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute stresses
    sigma_vm = compute_stress(nelx, nely, rho, p, E0, nu, U);
    sigma_max = max(sigma_vm(:));
    
    % 3. Adjust target material based on stress constraint
    if sigma_max > (1 + tau) * sigma_allow
        % Too much stress → increase material
        TM_init = TM_init * (1 + coef_inc_dec);
        fprintf('  Stress %.3f > allowable band → increase TM to %.4f\n', sigma_max, TM_init);
    elseif sigma_max < (1 - tau) * sigma_allow
        % Too little stress → decrease material
        TM_init = TM_init * (1 - coef_inc_dec);
        fprintf('  Stress %.3f < allowable band → decrease TM to %.4f\n', sigma_max, TM_init);
    end
    
    % 4. Material redistribution loop
    RM = TM_init;  % Remaining material
    rho_opt = zeros(nely, nelx);
    
    % Inner loop: distribute material proportionally to stress
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOs(sigma_vm, RM, q, 1.0, rho_min, rho_max);
        
        % Sum of allocated density
        allocated = sum(rho_opt_iter(:));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate optimal density
        rho_opt = rho_opt + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM_init
            break;
        end
    end
    
    % 5. Density filtering
    rho_filtered = density_filter(rho_opt, r_min, nelx, nely, dx, dy);
    
    % 6. Update density with move limit
    rho_new = update_density(rho, rho_filtered, alpha, rho_min, rho_max);
    
    % 7. Compute convergence metrics
    change = max(abs(rho_new(:) - rho(:)));
    compliance = U' * K_global * U;
    volume = sum(rho_new(:));
    
    % Store history
    history.iteration(end+1) = iter;
    history.compliance(end+1) = compliance;
    history.volume(end+1) = volume;
    history.sigma_max(end+1) = sigma_max;
    history.TM(end+1) = TM_init;
    history.change(end+1) = change;
    
    % 8. Check convergence
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, 1e-3, 'PTOs', sigma_max, sigma_allow, tau);
    
    % 9. Plot intermediate results
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
        imagesc(sigma_vm); axis equal tight; colorbar; 
        title(sprintf('Stress (max=%.2f)', sigma_max));
        axis xy;
        xlabel('x'); ylabel('y');
        
        subplot(2,3,3);
        plot(history.iteration, history.compliance, 'b-o', 'LineWidth', 1.5); 
        grid on; title('Compliance'); xlabel('Iteration'); ylabel('Compliance');
        
        subplot(2,3,4);
        plot(history.iteration, history.volume, 'r-*', 'LineWidth', 1.5); 
        grid on; title('Volume'); xlabel('Iteration'); ylabel('Volume');
        
        subplot(2,3,5);
        plot(history.iteration, history.sigma_max, 'g-s', 'LineWidth', 1.5); 
        grid on; title('Max Stress'); xlabel('Iteration'); ylabel('Max Stress');
        yline(sigma_allow*(1-tau), 'r--', ''); 
        yline(sigma_allow*(1+tau), 'r--', '');
        yline(sigma_allow, 'k-', 'Allowable stress');
        
        subplot(2,3,6);
        plot(history.iteration, history.change, 'm-d', 'LineWidth', 1.5); 
        grid on; title('Density Change'); xlabel('Iteration'); ylabel('Max Change');
        yline(1e-3, '--', 'Tolerance');
        
        drawnow;
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('%s PTOs converged after %d iterations.\n', problem_name, iter);
        break;
    end
end

% Final optimal density
rho_opt = rho;

end
