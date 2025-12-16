function B = strain_displacement_matrix_centroid()
% STRAIN_DISPLACEMENT_MATRIX_CENTROID Compute B matrix at element centroid
%
%   B = STRAIN_DISPLACEMENT_MATRIX_CENTROID() returns the 3x8 strain-displacement
%   matrix evaluated at the centroid (xi=0, eta=0) of a bilinear quadrilateral.
%
%   For a unit square element with nodes at (0,0), (1,0), (1,1), (0,1).

% Derivatives of shape functions at centroid
dN_dxi = 0.25 * [-1, 1, 1, -1];
dN_deta = 0.25 * [-1, -1, 1, 1];

% Jacobian matrix (unit square)
J = [dN_dxi; dN_deta] * [0, 0; 1, 0; 1, 1; 0, 1];
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
end