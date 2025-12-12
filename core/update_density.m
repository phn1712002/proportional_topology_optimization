function rho_new = update_density(rho_prev, rho_opt, alpha, rho_min, rho_max)
% UPDATE_DENSITY Update density field using linear interpolation
%
%   RHO_NEW = UPDATE_DENSITY(RHO_PREV, RHO_OPT, ALPHA, RHO_MIN, RHO_MAX)
%   computes the new density as a convex combination of previous density
%   and optimal density, then applies bounds.
%
% Inputs:
%   rho_prev   - Previous density field (nely x nelx)
%   rho_opt    - Optimal density from material distribution (nely x nelx)
%   alpha      - Move limit (0 < alpha < 1). Higher alpha means slower change.
%   rho_min    - Minimum density (default: 1e-3)
%   rho_max    - Maximum density (default: 1.0)
%
% Outputs:
%   rho_new    - Updated density field (nely x nelx)
%
% Formula:
%   rho_new = alpha * rho_prev + (1 - alpha) * rho_opt

% Default parameters
if nargin < 4
    rho_min = 1e-3;
end
if nargin < 5
    rho_max = 1.0;
end

% Ensure alpha is in valid range
alpha = max(0, min(1, alpha));

% Linear interpolation
rho_new = alpha * rho_prev + (1 - alpha) * rho_opt;

% Apply bounds
rho_new = max(rho_min, min(rho_max, rho_new));
end
