function rho_opt = material_distribution_PTOc(C, TM, q, rho_min, rho_max, design_mask)
% MATERIAL_DISTRIBUTION_PTOC Compute optimal density distribution for compliance-based PTO
%
%   RHO_OPT = MATERIAL_DISTRIBUTION_PTOC(C, TM, Q, RHO_MIN, RHO_MAX, DESIGN_MASK)
%   computes the optimal density distribution using the Optimality Criteria (OC)
%   method with bisection to enforce the total material constraint.
%   Design mask indicates which elements are in the design region (1 = design, 0 = cutout/void).
%
%   The method finds densities that minimize compliance while satisfying:
%   sum(rho(:)) = TM, with rho_min ≤ rho ≤ rho_max.
%
% Inputs:
%   C        - Element compliance values (nely x nelx matrix)
%   TM       - Total material volume constraint (scalar)
%   q        - Compliance exponent (sensitivity parameter)
%   rho_min  - Minimum density (default: 1e-3)
%   rho_max  - Maximum density (default: 1.0)
%   design_mask - Design region mask (nely x nelx, 1 = design, 0 = cutout)
%
% Outputs:
%   rho_opt  - Optimal density distribution (nely x nelx)
%
% Algorithm:
%   1. Use bisection to find Lagrange multiplier λ that satisfies sum(rho) = TM
%   2. Density update: rho_i = (C_i / λ)^(1/q)
%   3. Apply bounds: rho_min ≤ rho_i ≤ rho_max
%
% Note: This is a derivative-free method based on proportional distribution.

% Default parameters
if nargin < 4
    rho_min = 1e-3;
end
if nargin < 5
    rho_max = 1.0;
end
if nargin < 6
    % If design_mask not provided, assume all elements are in design region
    [nely, nelx] = size(C);
    design_mask = ones(nely, nelx);
end

% Bisection parameters
TOLERANCE = 1e-6;         % Relative tolerance for bisection convergence

% Initialize bisection bounds
l1 = 0;
l2 = max(C(:)) / (rho_min^q);

% Only consider design region for material distribution
C_design = C .* design_mask;

% Bisection loop to find Lagrange multiplier λ
while (l2 - l1) / (l1 + l2) > TOLERANCE
    lambda = 0.5 * (l1 + l2);
    
    % Compute trial densities using OC formula
    rho_trial = (C_design ./ lambda).^(1/q);
    
    % Apply density bounds
    rho_trial = max(rho_min, min(rho_max, rho_trial));
    
    % Only consider design region for material constraint
    rho_trial_design = rho_trial .* design_mask;
    
    % Update bisection bounds based on total material constraint in design region
    if sum(rho_trial_design(:)) > TM
        l1 = lambda;      % Too much material, increase λ
    else
        l2 = lambda;      % Too little material, decrease λ
    end
end

% Final optimal density distribution
rho_opt = rho_trial;

% Ensure density is zero in cutout region
rho_opt(design_mask == 0) = 0;
end
