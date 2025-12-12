function rho_opt = material_distribution_PTOc(C, RM, q, rho_min, rho_max)
% MATERIAL_DISTRIBUTION_PTOC Compute optimal density distribution for compliance PTO
%
%   RHO_OPT = MATERIAL_DISTRIBUTION_PTOC(C, RM, Q, RHO_MIN, RHO_MAX)
%   distributes the remaining material RM proportionally to the compliance
%   raised to power q.
%
% Inputs:
%   C          - Element compliance (nely x nelx)
%   RM         - Remaining material to distribute (scalar)
%   q          - Compliance exponent (sensitivity parameter)
%   rho_min    - Minimum density (default: 1e-3)
%   rho_max    - Maximum density (default: 1.0)
%
% Outputs:
%   rho_opt    - Optimal density distribution (nely x nelx)
%
% Formula:
%   rho_i^opt = RM * C_i^q / sum_j C_j^q

% Default parameters
if nargin < 4
    rho_min = 1e-3;
end
if nargin < 5
    rho_max = 1.0;
end

% Ensure C is a matrix
[nely, nelx] = size(C);

% Avoid zero compliance to prevent division issues
C = max(C, 1e-12);

% Compute weighted compliance
weighted_C = C.^q;

% Total weighted compliance
total_weight = sum(weighted_C(:));

% If total weight is zero (unlikely), distribute uniformly
if total_weight < 1e-12
    rho_opt = RM / (nelx * nely) * ones(nely, nelx);
else
    % Proportional distribution
    rho_opt = RM * weighted_C / total_weight;
end

% Apply density bounds
rho_opt = max(rho_min, min(rho_max, rho_opt));
end
