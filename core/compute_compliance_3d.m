function [C, C_total] = compute_compliance_3d(nelx, nely, nelz, rho, p, E0, nu, U, K_global)
% COMPUTE_COMPLIANCE_3D Compute element compliance and total compliance for 3D
%
%   [C, C_TOTAL] = COMPUTE_COMPLIANCE_3D(NELX, NELY, NELZ, RHO, P, E0, NU, U, K_GLOBAL)
%   returns the compliance for each element and the total compliance for 3D problems.
%
% Inputs:
%   nelx, nely, nelz - Number of elements in x, y, z directions
%   rho              - Density field (nely x nelx x nelz)
%   p                - SIMP penalty exponent
%   E0               - Young's modulus of solid material
%   nu               - Poisson's ratio
%   U                - Displacement vector (3*(nelx+1)*(nely+1)*(nelz+1) x 1)
%   K_global         - Global stiffness matrix (optional, if not provided will be computed)
%
% Outputs:
%   C                - Element compliance (nely x nelx x nelz)
%   C_total          - Total compliance (scalar)
%
% Note: Element compliance is defined as C_i = U_i^T K_i U_i, where K_i is the
% element stiffness matrix scaled by SIMP interpolation.

% If K_global not provided, compute it (optional)
if nargin < 9
    error('K_global must be provided for accurate compliance computation.');
end

% Preallocate element compliance
C = zeros(nely, nelx, nelz);

% Element stiffness matrix for solid material (unit Young's modulus)
[Ke_solid, ~] = element_stiffness_matrix_3d_hex8(1.0, nu);

% Loop over elements
for elx = 1:nelx
    for ely = 1:nely
        for elz = 1:nelz
            % Node numbers for 8-node hex element
            % Node numbering convention:
            % Bottom layer (z=0): nodes 1-4, top layer (z=1): nodes 5-8
            n1 = (nely+1)*(nelx+1)*(elz-1) + (nely+1)*(elx-1) + ely;
            n2 = n1 + 1;
            n3 = n1 + (nely+1) + 1;
            n4 = n1 + (nely+1);
            n5 = n1 + (nely+1)*(nelx+1);
            n6 = n2 + (nely+1)*(nelx+1);
            n7 = n3 + (nely+1)*(nelx+1);
            n8 = n4 + (nely+1)*(nelx+1);
            
            % Degrees of freedom (3 DOFs per node)
            edof = zeros(1, 24);
            for i = 1:8
                node_idx = [n1, n2, n3, n4, n5, n6, n7, n8];
                edof(3*i-2) = 3*node_idx(i) - 2; % u displacement
                edof(3*i-1) = 3*node_idx(i) - 1; % v displacement
                edof(3*i)   = 3*node_idx(i);     % w displacement
            end
            
            % Element displacement vector
            Ue = U(edof);
            
            % SIMP Young's modulus
            E_min = 1e-9 * E0;
            E = E_min + rho(ely, elx, elz)^p * (E0 - E_min);
            
            % Element compliance
            C(ely, elx, elz) = Ue' * (E * Ke_solid) * Ue;
        end
    end
end

% Total compliance = U' * K * U
C_total = U' * K_global * U;
end
