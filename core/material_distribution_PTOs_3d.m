function rho_opt = material_distribution_PTOs_3d(sigma_vm, RM, q, volume, rho_min, rho_max, design_mask)
% MATERIAL_DISTRIBUTION_PTOS_3D Compute optimal density distribution for stress-constrained PTO in 3D
%
%   RHO_OPT = MATERIAL_DISTRIBUTION_PTOS_3D(SIGMA_VM, RM, Q, VOLUME, RHO_MIN, RHO_MAX, DESIGN_MASK)
%   distributes the remaining material RM proportionally to the stress raised
%   to power q, with optional volume weighting. Design mask indicates which
%   elements are in the design region (1 = design, 0 = cutout/void).
%
% Inputs:
%   sigma_vm   - Von Mises stress for each element (nely x nelx x nelz)
%   RM         - Remaining material to distribute (scalar)
%   q          - Stress exponent (sensitivity parameter)
%   volume     - Element volumes (nely x nelx x nelz) or scalar if uniform
%   rho_min    - Minimum density (default: 1e-3)
%   rho_max    - Maximum density (default: 1.0)
%   design_mask- Design region mask (nely x nelx x nelz, 1 = design, 0 = cutout)
%
% Outputs:
%   rho_opt    - Optimal density distribution (nely x nelx x nelz)
%
% Formula:
%   rho_i^opt = RM * (sigma_i^q * v_i) / sum_j (sigma_j^q * v_j)
%
% This implementation uses the first formula (stress^q * volume).

% Default parameters
if nargin < 5
    rho_min = 1e-3;
end
if nargin < 6
    rho_max = 1.0;
end
if nargin < 7
    % If design_mask not provided, assume all elements are in design region
    [nely, nelx, nelz] = size(sigma_vm);
    design_mask = ones(nely, nelx, nelz);
end

% Ensure sigma_vm is a 3D array
[nely, nelx, nelz] = size(sigma_vm);

% If volume is scalar, create uniform 3D matrix
if isscalar(volume)
    volume = volume * ones(nely, nelx, nelz);
end

% Avoid zero stress to prevent division issues
sigma_vm = max(sigma_vm, 1e-9);

% Compute weighted stress
weighted_stress = sigma_vm.^q .* volume;

% Only consider design region for material distribution
weighted_stress_design = weighted_stress .* design_mask;

% Total weighted stress in design region
total_weight = sum(weighted_stress_design(:));

% If total weight is zero (unlikely), distribute uniformly in design region
if total_weight < 1e-12
    % Count design elements
    num_design_elements = sum(design_mask(:));
    if num_design_elements > 0
        rho_opt = RM / num_design_elements * ones(nely, nelx, nelz);
    else
        rho_opt = zeros(nely, nelx, nelz);
    end
else
    % Proportional distribution in design region
    rho_opt = RM * weighted_stress_design / total_weight;
end

% Apply density bounds
rho_opt = max(rho_min, min(rho_max, rho_opt));

% Ensure density is zero in cutout region
rho_opt(design_mask == 0) = 0;
end
