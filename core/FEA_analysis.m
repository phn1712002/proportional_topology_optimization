function [U, K_global, element_stiffness] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs)
% FEA_ANALYSIS Perform finite element analysis for topology optimization
%
%   [U, K_GLOBAL, ELEMENT_STIFFNESS] = FEA_ANALYSIS(NELX, NELY, RHO, P, E0, NU, LOAD_DOFS, LOAD_VALS, FIXED_DOFS)
%   computes the displacement field U, global stiffness matrix K_GLOBAL,
%   and element stiffness matrices for a 2D plane stress problem using
%   bilinear quadrilateral elements.
%
% Inputs:
%   nelx        - Number of elements in x-direction
%   nely        - Number of elements in y-direction
%   rho         - Density field (nely x nelx)
%   p           - SIMP penalty exponent
%   E0          - Young's modulus of solid material
%   nu          - Poisson's ratio
%   load_dofs   - Degrees of freedom where loads are applied
%   load_vals   - Corresponding load values
%   fixed_dofs  - Degrees of freedom with fixed (zero) displacement
%
% Outputs:
%   U           - Displacement vector (2*(nelx+1)*(nely+1) x 1)
%   K_global    - Global stiffness matrix (sparse)
%   element_stiffness - Cell array of element stiffness matrices (optional)
%
% Reference: SIMP method with E_min = 1e-9 * E0 to avoid singularity.

% Parameters
E_min = 1e-9 * E0;
ndof = 2 * (nelx + 1) * (nely + 1);

% Element stiffness matrix for solid material (unit Young's modulus)
[Ke, ~] = element_stiffness_matrix(E0, nu);

% Assembly
K_global = assemble_global_stiffness(nelx, nely, rho, p, E0, E_min, Ke, ndof);

% Apply boundary conditions (remove fixed DOFs)
free_dofs = setdiff(1:ndof, fixed_dofs);

% Load vector
F = zeros(ndof, 1);
F(load_dofs) = load_vals;

% Solve linear system
U = zeros(ndof, 1);
U(free_dofs) = K_global(free_dofs, free_dofs) \ F(free_dofs);

% Optionally return element stiffness matrices
if nargout > 2
    element_stiffness = cell(nely, nelx);
    for elx = 1:nelx
        for ely = 1:nely
            E = E_min + rho(ely, elx)^p * (E0 - E_min);
            element_stiffness{ely, elx} = E * Ke;
        end
    end
end
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
