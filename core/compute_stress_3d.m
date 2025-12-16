function [sigma_vm, stress_tensor] = compute_stress_3d(nelx, nely, nelz, rho, p, E0, nu, U)
% COMPUTE_STRESS_3D Compute 3D element stresses from displacement field.
%
%   [SIGMA_VM, STRESS_TENSOR] = COMPUTE_STRESS_3D(NELX, NELY, NELZ, RHO, P, E0, NU, U)
%   returns the von Mises stress and a struct containing all stress components
%   for each 8-node hexahedral element.
%
% Inputs:
%   nelx, nely, nelz - Number of elements in x, y, z directions
%   rho              - Density field (nely x nelx x nelz)
%   p                - SIMP penalty exponent
%   E0               - Young's modulus of solid material
%   nu               - Poisson's ratio
%   U                - Displacement vector (from fea_analysis_3d)
%
% Outputs:
%   sigma_vm         - Von Mises stress for each element (nely x nelx x nelz)
%   stress_tensor    - Struct with fields .xx, .yy, .zz, .xy, .yz, .xz
%                      containing the 6 stress components.
%
% Note: Stresses are computed at the element centroid (xi=0, eta=0, zeta=0).

% --- 1. Initialization and Preallocation ---
% Preallocate output matrices
sigma_vm = zeros(nely, nelx, nelz);
stress_tensor.xx = zeros(nely, nelx, nelz);
stress_tensor.yy = zeros(nely, nelx, nelz);
stress_tensor.zz = zeros(nely, nelx, nelz);
stress_tensor.xy = zeros(nely, nelx, nelz);
stress_tensor.yz = zeros(nely, nelx, nelz);
stress_tensor.xz = zeros(nely, nelx, nelz);

% --- 2. Define Material and Strain-Displacement Matrices ---
% Material matrix for 3D elasticity (with E=1, will be scaled by SIMP)
C1 = 1 / ((1 + nu) * (1 - 2*nu));
C2 = (1 - nu);
C3 = (1 - 2*nu) / 2;
D0 = C1 * [C2, nu, nu, 0,  0,  0;  nu, C2, nu, 0,  0,  0;  nu, nu, C2, 0,  0,  0; ...
           0,  0,  0,  C3, 0,  0;  0,  0,  0,  0,  C3, 0;  0,  0,  0,  0,  0,  C3];

% Strain-displacement matrix (B) evaluated at the element centroid
B = strain_displacement_matrix_centroid_3d_hex8();

% --- 3. Loop Over Elements to Compute Stress ---
num_nodes_x = nelx + 1;
num_nodes_y = nely + 1;
E_MIN_FACTOR = 1e-9;
E_min = E_MIN_FACTOR * E0;

for elz = 1:nelz
    for elx = 1:nelx
        for ely = 1:nely
            % Get node numbers for the current element (consistent with assembly)
            n1 = (elz-1)*num_nodes_x*num_nodes_y + (elx-1)*num_nodes_y + ely;
            n2 = (elz-1)*num_nodes_x*num_nodes_y + elx*num_nodes_y + ely;
            n3 = n2 + 1;
            n4 = n1 + 1;
            n5 = n1 + num_nodes_x*num_nodes_y;
            n6 = n2 + num_nodes_x*num_nodes_y;
            n7 = n3 + num_nodes_x*num_nodes_y;
            n8 = n4 + num_nodes_x*num_nodes_y;
            node_numbers = [n1, n2, n3, n4, n5, n6, n7, n8];
            
            % Map node numbers to global DOFs (24 DOFs per element)
            dof_x = 3*node_numbers - 2;
            dof_y = 3*node_numbers - 1;
            dof_z = 3*node_numbers;
            edof = reshape([dof_x; dof_y; dof_z], 1, []);
            
            % Element displacement vector (24x1)
            Ue = U(edof);
            
            % Strain vector (6x1): epsilon = B * Ue
            epsilon = B * Ue;
            
            % Effective Young's modulus from SIMP
            E_element = E_min + rho(ely, elx, elz)^p * (E0 - E_min);
            
            % Stress vector (6x1): sigma = E * D0 * epsilon
            sigma = E_element * D0 * epsilon; % [s_xx, s_yy, s_zz, s_xy, s_yz, s_xz]
            
            % Store stress components
            s_xx = sigma(1);
            s_yy = sigma(2);
            s_zz = sigma(3);
            s_xy = sigma(4); % Note: engineering shear strain means this is tau_xy
            s_yz = sigma(5); % tau_yz
            s_xz = sigma(6); % tau_xz
            
            stress_tensor.xx(ely, elx, elz) = s_xx;
            stress_tensor.yy(ely, elx, elz) = s_yy;
            stress_tensor.zz(ely, elx, elz) = s_zz;
            stress_tensor.xy(ely, elx, elz) = s_xy;
            stress_tensor.yz(ely, elx, elz) = s_yz;
            stress_tensor.xz(ely, elx, elz) = s_xz;
            
            % Von Mises stress (full 3D formula)
            vm_term1 = (s_xx - s_yy)^2 + (s_yy - s_zz)^2 + (s_zz - s_xx)^2;
            vm_term2 = 6 * (s_xy^2 + s_yz^2 + s_xz^2);
            sigma_vm(ely, elx, elz) = sqrt(0.5 * vm_term1 + 0.5 * vm_term2);
        end
    end
end
end