function rho_opt = material_distribution_PTOs(sigma_vm, RM, q, volume, rho_min, rho_max)
% MATERIAL_DISTRIBUTION_PTOS Compute optimal density distribution for stress-constrained PTO
%
%   RHO_OPT = MATERIAL_DISTRIBUTION_PTOS(SIGMA_VM, RM, Q, VOLUME, RHO_MIN, RHO_MAX)
%   distributes the remaining material RM proportionally to the stress raised
%   to power q, with optional volume weighting.
%
% Inputs:
%   sigma_vm   - Von Mises stress for each element (nely x nelx)
%   RM         - Remaining material to distribute (scalar)
%   q          - Stress exponent (sensitivity parameter)
%   volume     - Element volumes (nely x nelx) or scalar if uniform
%   rho_min    - Minimum density (default: 1e-3)
%   rho_max    - Maximum density (default: 1.0)
%
% Outputs:
%   rho_opt    - Optimal density distribution (nely x nelx)
%
% Formula:
%   rho_i^opt = RM * (sigma_i^q * v_i) / sum_j (sigma_j^q * v_j)
%   or alternative: rho_i^opt = RM * (sigma_i / v_i)^q / sum_j (sigma_j / v_j)^q
%
% This implementation uses the first formula (stress^q * volume).

% Default parameters
if nargin < 5
    rho_min = 1e-3;
end
if nargin < 6
    rho_max = 1.0;
end

% Ensure sigma_vm is a matrix
[nely, nelx] = size(sigma_vm);

% If volume is scalar, create uniform matrix
if isscalar(volume)
    volume = volume * ones(nely, nelx);
end

% Avoid zero stress to prevent division issues
sigma_vm = max(sigma_vm, 1e-9);

% Compute weighted stress
weighted_stress = sigma_vm.^q .* volume;

% Total weighted stress
total_weight = sum(weighted_stress(:));

% If total weight is zero (unlikely), distribute uniformly
if total_weight < 1e-12
    rho_opt = RM / (nelx * nely) * ones(nely, nelx);
else
    % Proportional distribution
    rho_opt = RM * weighted_stress / total_weight;
end

% Apply density bounds
rho_opt = max(rho_min, min(rho_max, rho_opt));
end
