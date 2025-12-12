function [C, C_total] = compute_compliance(nelx, nely, rho, p, E0, nu, U, K_global)
% COMPUTE_COMPLIANCE Compute element compliance and total compliance
%
%   [C, C_TOTAL] = COMPUTE_COMPLIANCE(NELX, NELY, RHO, P, E0, NU, U, K_GLOBAL)
%   returns the compliance for each element and the total compliance.
%
% Inputs:
%   nelx, nely - Number of elements in x and y directions
%   rho        - Density field (nely x nelx)
%   p          - SIMP penalty exponent
%   E0         - Young's modulus of solid material
%   nu         - Poisson's ratio
%   U          - Displacement vector (2*(nelx+1)*(nely+1) x 1)
%   K_global   - Global stiffness matrix (optional, if not provided will be computed)
%
% Outputs:
%   C          - Element compliance (nely x nelx)
%   C_total    - Total compliance (scalar)
%
% Note: Element compliance is defined as C_i = U_i^T K_i U_i, where K_i is the
% element stiffness matrix scaled by SIMP interpolation.

% If K_global not provided, compute it (optional)
if nargin < 8
    % Compute load DOFs and fixed DOFs (dummy, not used for compliance)
    % This is not ideal; better to pass K_global from FEA_analysis.
    error('K_global must be provided for accurate compliance computation.');
end

% Preallocate element compliance
C = zeros(nely, nelx);

% Element stiffness matrix for solid material (unit Young's modulus)
[Ke, ~] = element_stiffness_matrix(E0, nu);

% Loop over elements
for elx = 1:nelx
    for ely = 1:nely
        % Element degrees of freedom
        n1 = (nely + 1) * (elx - 1) + ely;
        n2 = (nely + 1) * elx + ely;
        edof = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
        
        % Element displacement vector
        Ue = U(edof);
        
        % SIMP Young's modulus
        E_min = 1e-9 * E0;
        E = E_min + rho(ely, elx)^p * (E0 - E_min);
        
        % Element compliance
        C(ely, elx) = Ue' * (E * Ke) * Ue;
    end
end

% Total compliance = U' * K * U
C_total = U' * K_global * U;
end

function [Ke, B] = element_stiffness_matrix(E, nu)
% ELEMENT_STIFFNESS_MATRIX Compute stiffness matrix for a bilinear quad element
%
%   [KE, B] = ELEMENT_STIFFNESS_MATRIX(E, NU) returns the 8x8 stiffness matrix
%   KE and strain-displacement matrix B for a unit square element under
%   plane stress conditions.
%
%   Uses 2x2 Gauss quadrature.

% Gauss points and weights
xi = [-1/sqrt(3), 1/sqrt(3)];
eta = xi;
w = [1, 1];

% Material matrix (plane stress)
D = E / (1 - nu^2) * [1, nu, 0; nu, 1, 0; 0, 0, (1 - nu)/2];

% Initialize
Ke = zeros(8, 8);

% Shape functions and derivatives
for i = 1:2
    for j = 1:2
        % Natural coordinates
        xi_i = xi(i);
        eta_j = eta(j);
        
        % Shape functions
        N = 0.25 * [(1 - xi_i)*(1 - eta_j);
                    (1 + xi_i)*(1 - eta_j);
                    (1 + xi_i)*(1 + eta_j);
                    (1 - xi_i)*(1 + eta_j)];
        
        % Derivatives of shape functions w.r.t xi and eta
        dN_dxi = 0.25 * [-(1 - eta_j),  (1 - eta_j), (1 + eta_j), -(1 + eta_j)];
        dN_deta = 0.25 * [-(1 - xi_i), -(1 + xi_i), (1 + xi_i),  (1 - xi_i)];
        
        % Jacobian matrix (for unit square, J = 0.5*I)
        J = [dN_dxi; dN_deta] * [0, 0; 1, 0; 1, 1; 0, 1];
        detJ = abs(det(J));
        invJ = inv(J);
        
        % Derivatives w.r.t x and y
        dN_dx = invJ(1,1) * dN_dxi + invJ(1,2) * dN_deta;
        dN_dy = invJ(2,1) * dN_dxi + invJ(2,2) * dN_deta;
        
        % Strain-displacement matrix B (3 x 8)
        B = zeros(3, 8);
        for k = 1:4
            B(1, 2*k-1) = dN_dx(k);
            B(2, 2*k)   = dN_dy(k);
            B(3, 2*k-1) = dN_dy(k);
            B(3, 2*k)   = dN_dx(k);
        end
        
        % Element stiffness contribution
        Ke = Ke + w(i) * w(j) * B' * D * B * detJ;
    end
end
end
