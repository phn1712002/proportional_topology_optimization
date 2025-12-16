function [Ke, B] = element_stiffness_matrix_3d_hex8(E, nu)
% ELEMENT_STIFFNESS_MATRIX_3D_HEX8 Stiffness matrix for an 8-node hex element.
%
%   [KE, B] = ELEMENT_STIFFNESS_MATRIX_3D_HEX8(E, NU) returns the 24x24
%   stiffness matrix KE for a unit cube element.
%
%   Method: Uses 2x2x2 Gauss quadrature for numerical integration.

% --- Constants ---
GAUSS_POINT = 1 / sqrt(3);
GAUSS_POINTS = [-GAUSS_POINT, GAUSS_POINT];
GAUSS_WEIGHTS = [1, 1];
NUM_NODES = 8;
DOFS_PER_NODE = 3;
MATRIX_SIZE = NUM_NODES * DOFS_PER_NODE; % 24

% --- Material Matrix (3D Isotropic Elasticity) ---
C1 = E / ((1 + nu) * (1 - 2*nu));
C2 = (1 - nu);
C3 = (1 - 2*nu) / 2;
D = C1 * [C2, nu, nu, 0,  0,  0;  ...
          nu, C2, nu, 0,  0,  0;  ...
          nu, nu, C2, 0,  0,  0;  ...
          0,  0,  0,  C3, 0,  0;  ...
          0,  0,  0,  0,  C3, 0;  ...
          0,  0,  0,  0,  0,  C3];

% --- Numerical Integration ---
Ke = zeros(MATRIX_SIZE, MATRIX_SIZE);

for i = 1:length(GAUSS_POINTS)
    for j = 1:length(GAUSS_POINTS)
        for k = 1:length(GAUSS_POINTS)
            xi = GAUSS_POINTS(i);   % Natural coordinate ξ
            eta = GAUSS_POINTS(j);  % Natural coordinate η
            zeta = GAUSS_POINTS(k); % Natural coordinate ζ
            
            % Derivatives of shape functions w.r.t. natural coordinates
            [~, dN_dxi_eta_zeta] = shape_functions_hex8(xi, eta, zeta);
            dN_dxi   = dN_dxi_eta_zeta(1, :);
            dN_deta  = dN_dxi_eta_zeta(2, :);
            dN_dzeta = dN_dxi_eta_zeta(3, :);
            
            % For a unit cube element, Jacobian is constant and diagonal
            J = 0.5 * eye(3);
            detJ = det(J);
            
            % Derivatives w.r.t. physical coordinates (x, y, z)
            dN_dxyz = J \ [dN_dxi; dN_deta; dN_dzeta];
            dN_dx = dN_dxyz(1, :);
            dN_dy = dN_dxyz(2, :);
            dN_dz = dN_dxyz(3, :);
            
            % Strain-Displacement Matrix (B), size is 6x24
            B = zeros(6, MATRIX_SIZE);
            for n_node = 1:NUM_NODES
                col1 = 3*n_node - 2; % u displacement column
                col2 = 3*n_node - 1; % v displacement column
                col3 = 3*n_node;     % w displacement column
                
                B(1, col1) = dN_dx(n_node);
                B(2, col2) = dN_dy(n_node);
                B(3, col3) = dN_dz(n_node);
                B(4, col1) = dN_dy(n_node); B(4, col2) = dN_dx(n_node);
                B(5, col2) = dN_dz(n_node); B(5, col3) = dN_dy(n_node);
                B(6, col1) = dN_dz(n_node); B(6, col3) = dN_dx(n_node);
            end
            
            % Add contribution to stiffness matrix
            w_i = GAUSS_WEIGHTS(i);
            w_j = GAUSS_WEIGHTS(j);
            w_k = GAUSS_WEIGHTS(k);
            Ke = Ke + (B' * D * B) * w_i * w_j * w_k * detJ;
        end
    end
end
end

function [N, dN_dxi_eta_zeta] = shape_functions_hex8(xi, eta, zeta)
% SHAPE_FUNCTIONS_HEX8 Computes shape functions and their derivatives for an 8-node hex element.
N = 0.125 * [ (1-xi)*(1-eta)*(1-zeta); (1+xi)*(1-eta)*(1-zeta); ...
              (1+xi)*(1+eta)*(1-zeta); (1-xi)*(1+eta)*(1-zeta); ...
              (1-xi)*(1-eta)*(1+zeta); (1+xi)*(1-eta)*(1+zeta); ...
              (1+xi)*(1+eta)*(1+zeta); (1-xi)*(1+eta)*(1+zeta) ]';

dN_dxi_eta_zeta = 0.125 * [ ...
    -(1-eta)*(1-zeta),  (1-eta)*(1-zeta),  (1+eta)*(1-zeta), -(1+eta)*(1-zeta), -(1-eta)*(1+zeta),  (1-eta)*(1+zeta),  (1+eta)*(1+zeta), -(1+eta)*(1+zeta); ... % dN/dxi
    -(1-xi)*(1-zeta), -(1+xi)*(1-zeta),  (1+xi)*(1-zeta),  (1-xi)*(1-zeta), -(1-xi)*(1+zeta), -(1+xi)*(1+zeta),  (1+xi)*(1+zeta),  (1-xi)*(1+zeta); ... % dN/deta
    -(1-xi)*(1-eta), -(1+xi)*(1-eta), -(1+xi)*(1+eta), -(1-xi)*(1+eta),  (1-xi)*(1-eta),  (1+xi)*(1-eta),  (1+xi)*(1+eta),  (1-xi)*(1+eta) ];    % dN/dzeta
end