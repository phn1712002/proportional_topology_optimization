function [converged, change] = check_convergence(rho_new, rho_prev, iter, max_iter, tol, mode, sigma_max, sigma_allow, tau)
% CHECK_CONVERGENCE Check convergence criteria for PTO algorithms
%
%   [CONVERGED, CHANGE] = CHECK_CONVERGENCE(RHO_NEW, RHO_PREV, ITER, MAX_ITER, TOL, MODE, SIGMA_MAX, SIGMA_ALLOW, TAU)
%   determines whether the optimization has converged based on density change,
%   iteration count, and stress criteria (for PTOs).
%
% Inputs:
%   rho_new    - Current density field (nely x nelx)
%   rho_prev   - Previous density field (nely x nelx)
%   iter       - Current iteration number
%   max_iter   - Maximum allowed iterations
%   tol        - Tolerance for density change (default: 1e-3)
%   mode       - 'PTOs' for stress-constrained, 'PTOc' for compliance (default: 'PTOc')
%   sigma_max  - Maximum von Mises stress (required for PTOs mode)
%   sigma_allow- Allowable stress (required for PTOs mode)
%   tau        - Tolerance band for stress (default: 0.05)
%
% Outputs:
%   converged  - Boolean indicating convergence
%   change     - Maximum absolute density change
%
% Convergence criteria:
%   - PTOc: max|rho_new - rho_prev| < tol
%   - PTOs: sigma_max within (1±tau)*sigma_allow AND density change small
%   - Always stop if iter >= max_iter

% Default parameters
if nargin < 6
    mode = 'PTOc';
end
if nargin < 7
    sigma_max = Inf;
end
if nargin < 8
    sigma_allow = Inf;
end
if nargin < 9
    tau = 0.05;
end
if nargin < 5
    tol = 1e-3;
end

% Compute maximum density change
change = max(abs(rho_new(:) - rho_prev(:)));

% Check iteration limit
if iter >= max_iter
    converged = true;
    fprintf('Convergence: reached maximum iterations (%d)\n', max_iter);
    return;
end

% Mode-specific convergence
switch lower(mode)
    case 'ptoc'
        % Compliance minimization: density change tolerance
        if change < tol
            converged = true;
            fprintf('Convergence: density change %.2e < tolerance %.2e\n', change, tol);
        else
            converged = false;
        end
        
    case 'ptos'
        % Stress-constrained: stress within band AND density change small
        stress_lower = (1 - tau) * sigma_allow;
        stress_upper = (1 + tau) * sigma_allow;
        
        stress_ok = (sigma_max >= stress_lower) && (sigma_max <= stress_upper);
        density_ok = change < tol;
        
        if stress_ok && density_ok
            converged = true;
            fprintf('Convergence: stress %.3f within [%.3f, %.3f] and density change %.2e < %.2e\n', ...
                sigma_max, stress_lower, stress_upper, change, tol);
        else
            converged = false;
            if ~stress_ok
                fprintf('Not converged: stress %.3f outside band [%.3f, %.3f]\n', ...
                    sigma_max, stress_lower, stress_upper);
            end
            if ~density_ok
                fprintf('Not converged: density change %.2e >= %.2e\n', change, tol);
            end
        end
        
    otherwise
        error('Unknown mode: %s. Use ''PTOs'' or ''PTOc''.', mode);
end
end
