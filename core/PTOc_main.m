function [rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, plot_flag, plot_frequency)
% PTOC_MAIN Main function for compliance minimization Proportional Topology Optimization
%
%   [RHO_OPT, HISTORY] = PTOC_MAIN(NELX, NELY, P, Q, R_MIN, ALPHA, VOLUME_FRACTION, MAX_ITER, PLOT_FLAG)
%   runs the PTOc algorithm and returns the optimized density field and iteration history.
%
% Inputs:
%   nelx, nely - Number of elements in x and y directions
%   p          - SIMP penalty exponent (typically 3)
%   q          - Compliance exponent for material distribution (typically 0.5-2)
%   r_min      - Filter radius (in element units)
%   alpha      - Move limit (0 < alpha < 1, typically 0.2-0.5)
%   volume_fraction - Target volume fraction (0 < vf < 1, default: 0.4)
%   max_iter   - Maximum iterations (default: 200)
%   plot_flag  - Whether to plot intermediate results (default: true)
%
% Outputs:
%   rho_opt    - Optimized density field (nely x nelx)
%   history    - Structure containing iteration history
%
% Example:
%   [rho, hist] = PTOc_main(60, 30, 3, 1, 1.5, 0.3, 0.4, 200, true);

% Default parameters
if nargin < 10
    plot_frequency = 10;
end
if nargin < 9
    plot_flag = true;
end
if nargin < 8
    plot_flag = true;
end
if nargin < 7
    max_iter = 200;
end
if nargin < 7
    volume_fraction = 0.4;
end

% Material properties
E0 = 1.0;      % Young's modulus of solid
nu = 0.3;      % Poisson's ratio
rho_min = 1e-3;
rho_max = 1.0;
dx = 1; dy = 1; % Element size

% Boundary conditions: cantilever beam (same as PTOs for comparison)
fixed_dofs = 1:2*(nely+1);  % Left edge fixed
load_node = (nelx+1)*(nely+1);  % Bottom right corner
load_dof = 2*load_node;         % y-direction
load_dofs = load_dof;
load_vals = -1;  % Downward load

% Target material (fixed)
TM = volume_fraction * nelx * nely;

% Initial uniform density
rho = ones(nely, nelx) * volume_fraction;
rho = max(rho_min, min(rho_max, rho));

% Initialize history
history.iteration = [];
history.compliance = [];
history.volume = [];
history.change = [];

% Main iteration loop
for iter = 1:max_iter
    fprintf('PTOc Iteration %d\n', iter);
    
    % 1. FEA analysis
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    
    % 2. Compute element compliance
    C = compute_compliance(nelx, nely, rho, p, E0, nu, U, K_global);
    
    % 3. Material redistribution loop
    RM = TM;  % Remaining material
    rho_opt = zeros(nely, nelx);
    
    % Inner loop: distribute material proportionally to compliance
    inner_max = 20;
    for inner = 1:inner_max
        % Compute optimal density for current RM
        rho_opt_iter = material_distribution_PTOc(C, RM, q, rho_min, rho_max);
        
        % Sum of allocated density
        allocated = sum(rho_opt_iter(:));
        
        % Update remaining material
        RM = RM - allocated;
        
        % Accumulate optimal density
        rho_opt = rho_opt + rho_opt_iter;
        
        % Stop if RM is very small
        if RM < 1e-6 * TM
            break;
        end
    end
    
    % 4. Density filtering
    rho_filtered = density_filter(rho_opt, r_min, nelx, nely, dx, dy);
    
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
    [converged, ~] = check_convergence(rho_new, rho, iter, max_iter, 1e-3, 'PTOc');
    
        % 8. Plot intermediate results
    if plot_flag && (mod(iter, plot_frequency) == 0 || iter == 1 || converged)
        figure(1);
        subplot(2,3,1);
        imagesc(rho_new); axis equal tight; colorbar; title(sprintf('Density (iter %d)', iter));
        axis xy;
        subplot(2,3,2);
        imagesc(C); axis equal tight; colorbar; title('Element Compliance');
        axis xy;
        subplot(2,3,3);
        plot(history.iteration, history.compliance, 'b-o'); grid on; title('Total Compliance');
        subplot(2,3,4);
        plot(history.iteration, history.volume, 'r-*'); grid on; title('Volume');
        subplot(2,3,5);
        semilogy(history.iteration, history.change, 'm-d'); grid on; title('Density Change (log)');
        subplot(2,3,6);
        imagesc(rho_filtered); axis equal tight; colorbar; title('Filtered Density');
        axis xy;
        drawnow;
    end
    
    % Update density for next iteration
    rho = rho_new;
    
    % Stop if converged
    if converged
        fprintf('PTOc converged after %d iterations.\n', iter);
        break;
    end
end

% Final optimized density
rho_opt = rho;

% Plot final design
if plot_flag
    figure(2);
    imagesc(rho_opt); axis equal tight; colorbar;
    axis xy;
    title(sprintf('Final PTOc Design (Volume = %.2f%%)', 100*sum(rho_opt(:))/(nelx*nely)));
    xlabel('x'); ylabel('y');
end

fprintf('PTOc completed. Final volume: %.4f, Compliance: %.4f\n', ...
    sum(rho_opt(:))/(nelx*nely), compliance);
end
