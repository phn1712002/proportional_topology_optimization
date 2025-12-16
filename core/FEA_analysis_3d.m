function [displacement_vector, global_stiffness_matrix, element_stiffnesses] = FEA_analysis_3d(nelx, nely, nelz, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs)
% FEA_analysis_3d Perform 3D finite element analysis for topology optimization
%
%   Performs a finite element analysis for a 3D problem using 8-node
%   hexahedral (brick) elements.
%
% Usage Example:
%   nelx = 30; nely = 10; nelz = 10;
%   rho = ones(nely, nelx, nelz);
%   % ... define loads and boundary conditions ...
%   [U, K] = FEA_analysis_3d(nelx, nely, nelz, rho, 3.0, 1.0, 0.3, ...);
%
% Inputs:
%   nelx        - Number of elements in x-direction
%   nely        - Number of elements in y-direction
%   nelz        - Number of elements in z-direction
%   rho         - Density field (nely x nelx x nelz)
%   p           - SIMP penalty exponent
%   E0          - Young's modulus of solid material
%   nu          - Poisson's ratio
%   load_dofs   - Degrees of freedom where loads are applied
%   load_vals   - Corresponding load values
%   fixed_dofs  - Degrees of freedom with fixed (zero) displacement
%
% Outputs:
%   displacement_vector - Displacement vector (3*(nx+1)*(ny+1)*(nz+1) x 1)
%   global_stiffness_matrix - Global stiffness matrix (sparse)
%   element_stiffnesses   - Cell array of element stiffness matrices

% --- 1. Constants and Initialization ---
E_MIN_FACTOR = 1e-9;
E_min = E_MIN_FACTOR * E0;

% Total number of degrees of freedom (3 DOFs per node)
num_nodes_x = nelx + 1;
num_nodes_y = nely + 1;
num_nodes_z = nelz + 1;
ndof = 3 * num_nodes_x * num_nodes_y * num_nodes_z;

% --- 2. Assembly of Global Stiffness Matrix ---
% Calculate the base element stiffness matrix for a solid element with E=1
[Ke_solid, ~] = element_stiffness_matrix_3d_hex8(1.0, nu);

% Delegate the assembly process to a dedicated helper function
[global_stiffness_matrix, element_stiffnesses] = assemble_global_stiffness_3d(...
    nelx, nely, nelz, rho, p, E0, E_min, Ke_solid, ndof, nargout);

% --- 3. Apply Boundary Conditions and Solve ---
all_dofs = 1:ndof;
free_dofs = setdiff(all_dofs, fixed_dofs);

% Initialize force and displacement vectors
F = sparse(ndof, 1);
F(load_dofs) = load_vals;

displacement_vector = sparse(ndof, 1);

% Solve for displacements at free DOFs
displacement_vector(free_dofs) = global_stiffness_matrix(free_dofs, free_dofs) \ F(free_dofs);
end