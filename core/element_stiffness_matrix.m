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