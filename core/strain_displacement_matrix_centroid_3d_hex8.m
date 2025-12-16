function B = strain_displacement_matrix_centroid_3d_hex8()
    % STRAIN_DISPLACEMENT_MATRIX_CENTROID_3D_HEX8
    %
    %   Computes the strain-displacement matrix (B) for an 8-node hexahedral
    %   element, evaluated at the element's centroid (xi=0, eta=0, zeta=0).
    %
    % Output:
    %   B - The 6x24 strain-displacement matrix.

    NUM_NODES = 8;
    MATRIX_SIZE = 24;

    % At the centroid (xi=0, eta=0, zeta=0), the derivatives of the shape
    % functions are simple.
    xi = 0; eta = 0; zeta = 0;

    dN_dxi_eta_zeta = 0.125 * [ ...
        -(1-eta)*(1-zeta),  (1-eta)*(1-zeta),  (1+eta)*(1-zeta), -(1+eta)*(1-zeta), -(1-eta)*(1+zeta),  (1-eta)*(1+zeta),  (1+eta)*(1+zeta), -(1+eta)*(1+zeta); ... % dN/dxi
        -(1-xi)*(1-zeta), -(1+xi)*(1-zeta),  (1+xi)*(1-zeta),  (1-xi)*(1-zeta), -(1-xi)*(1+zeta), -(1+xi)*(1+zeta),  (1+xi)*(1+zeta),  (1-xi)*(1+zeta); ... % dN/deta
        -(1-xi)*(1-eta), -(1+xi)*(1-eta), -(1+xi)*(1+eta), -(1-xi)*(1+eta),  (1-xi)*(1-eta),  (1+xi)*(1-eta),  (1+xi)*(1+eta),  (1-xi)*(1-eta) ];    % dN/dzeta

    % For a unit cube element, Jacobian is constant
    J = 0.5 * eye(3); 
    % Derivatives w.r.t. physical coordinates (x, y, z)
    dN_dxyz = J \ dN_dxi_eta_zeta;
    dN_dx = dN_dxyz(1, :);
    dN_dy = dN_dxyz(2, :);
    dN_dz = dN_dxyz(3, :);

    % Assemble the Strain-Displacement Matrix (B)
    B = zeros(6, MATRIX_SIZE);
    for n_node = 1:NUM_NODES
        col1 = 3*n_node - 2;
        col2 = 3*n_node - 1;
        col3 = 3*n_node;
        
        B(1, col1) = dN_dx(n_node);
        B(2, col2) = dN_dy(n_node);
        B(3, col3) = dN_dz(n_node);
        B(4, col1) = dN_dy(n_node); B(4, col2) = dN_dx(n_node);
        B(5, col2) = dN_dz(n_node); B(5, col3) = dN_dy(n_node);
        B(6, col1) = dN_dz(n_node); B(6, col3) = dN_dx(n_node);
    end
end