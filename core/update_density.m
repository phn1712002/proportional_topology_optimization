function rho_new = update_density(rho_prev, rho_opt, alpha, rho_min, rho_max)
% UPDATE_DENSITY Update density field with a move limit strategy.
%
%   This function is dimension-agnostic and works for 2D, 3D, or N-D arrays.
%   It computes the new density as a convex combination of the previous and
%   optimal densities, effectively applying a move limit to stabilize convergence.
%
% Inputs:
%   rho_prev   - Previous density field (e.g., nely x nelx x nelz array)
%   rho_opt    - Optimal density from the current iteration (same size as rho_prev)
%   alpha      - Move limit factor (0 <= alpha <= 1). A value closer to 1.0
%                results in a smaller update step (slower, more stable change).
%   rho_min    - Minimum allowed density (scalar, default: 1e-3)
%   rho_max    - Maximum allowed density (scalar, default: 1.0)
%
% Outputs:
%   rho_new    - Updated density field, with bounds applied.
%
% Formula:
%   rho_new = alpha * rho_prev + (1 - alpha) * rho_opt

% --- 1. Set Default Parameters ---
if nargin < 4
    rho_min = 1e-3;
end
if nargin < 5
    rho_max = 1.0;
end

% --- 2. Core Logic (Dimension-Agnostic) ---
% Ensure the move limit factor is within the valid [0, 1] range
alpha = max(0, min(1, alpha));

% Linearly interpolate between the previous and the new optimal density.
% This operation is element-wise and works for arrays of any dimension.
rho_new = alpha * rho_prev + (1 - alpha) * rho_opt;

% Apply the minimum and maximum density bounds.
% The max/min functions with a scalar argument also operate element-wise.
rho_new = max(rho_min, min(rho_max, rho_new));

end