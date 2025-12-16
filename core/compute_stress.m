function [sigma_vm, sigma_xx, sigma_yy, tau_xy] = compute_stress(nelx, nely, rho, p, E0, nu, U)
% COMPUTE_STRESS Compute element stresses from displacement field
%
%   [SIGMA_VM, SIGMA_XX, SIGMA_YY, TAU_XY] = COMPUTE_STRESS(NELX, NELY, RHO, P, E0, NU, U)
%   returns the von Mises stress and stress components for each element.
%
% Inputs:
%   nelx, nely - Number of elements in x and y directions
%   rho        - Density field (nely x nelx)
%   p          - SIMP penalty exponent
%   E0         - Young's modulus of solid material
%   nu         - Poisson's ratio
%   U          - Displacement vector (2*(nelx+1)*(nely+1) x 1)
%
% Outputs:
%   sigma_vm   - Von Mises stress for each element (nely x nelx)
%   sigma_xx   - Normal stress in x-direction (nely x nelx)
%   sigma_yy   - Normal stress in y-direction (nely x nelx)
%   tau_xy     - Shear stress (nely x nelx)
%
% Note: Stresses are computed at element centroids using the strain-displacement
% matrix evaluated at the center of the element (xi=0, eta=0).

% Preallocate
sigma_vm = zeros(nely, nelx);
sigma_xx = zeros(nely, nelx);
sigma_yy = zeros(nely, nelx);
tau_xy   = zeros(nely, nelx);

% Material matrix for plane stress (unit E, will be scaled by SIMP)
D0 = 1 / (1 - nu^2) * [1, nu, 0; nu, 1, 0; 0, 0, (1 - nu)/2];

% Strain-displacement matrix at centroid (xi=0, eta=0)
B = strain_displacement_matrix_centroid();

% Loop over elements
for elx = 1:nelx
    for ely = 1:nely
        % Element degrees of freedom
        n1 = (nely + 1) * (elx - 1) + ely;
        n2 = (nely + 1) * elx + ely;
        edof = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
        
        % Element displacement vector
        Ue = U(edof);
        
        % Strain vector epsilon = B * Ue
        epsilon = B * Ue;  % [epsilon_xx; epsilon_yy; gamma_xy]
        
        % SIMP Young's modulus
        E_min = 1e-9 * E0;
        E = E_min + rho(ely, elx)^p * (E0 - E_min);
        
        % Stress vector sigma = D * epsilon
        sigma = E * D0 * epsilon;  % [sigma_xx; sigma_yy; tau_xy]
        
        % Store components
        sigma_xx(ely, elx) = sigma(1);
        sigma_yy(ely, elx) = sigma(2);
        tau_xy(ely, elx)   = sigma(3);
        
        % Von Mises stress (plane stress)
        sigma_vm(ely, elx) = sqrt(sigma(1)^2 + sigma(2)^2 - sigma(1)*sigma(2) + 3*sigma(3)^2);
    end
end
end


