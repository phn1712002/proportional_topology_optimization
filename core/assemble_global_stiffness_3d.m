function [K_global, element_stiffness] = assemble_global_stiffness_3d(nelx, nely, nelz, rho, p, E0, E_min, Ke_solid, ndof, num_outputs)
%% ASSEMBLE_GLOBAL_STIFFNESS_3D Assembles the global stiffness matrix for a 3D FEA problem
%   This function constructs the global stiffness matrix by iterating through all
%   finite elements in a 3D domain. It uses the SIMP (Solid Isotropic
%   Material with Penalization) method to determine the stiffness of each element
%   based on its material density.
%
%   [K_GLOBAL, ELEMENT_STIFFNESS] = ASSEMBLE_GLOBAL_STIFFNESS_3D(...) assembles
%   the matrix and optionally returns the stiffness matrix for each individual element.
%
% Inputs:
%   nelx            - Number of elements in the x-direction (integer)
%   nely            - Number of elements in the y-direction (integer)
%   nelz            - Number of elements in the z-direction (integer)
%   rho             - 3D matrix of element densities (nely x nelx x nelz)
%   p               - SIMP penalization factor (double)
%   E0              - Young's modulus for solid material (double)
%   E_min           - Young's modulus for void material (double, a small non-zero value)
%   Ke_solid        - Base element stiffness matrix for a solid element (24x24 matrix)
%   ndof            - Total number of degrees of freedom in the system (integer)
%   num_outputs     - Number of requested outputs (typically nargout from the caller)
%
% Outputs:
%   K_global        - The assembled global stiffness matrix (sparse, ndof x ndof)
%   element_stiffness - Cell array of individual element stiffness matrices (optional)
%
% TODO: Vectorize this triple loop for significant performance improvement.

    % Initialize the global stiffness matrix as a sparse matrix for memory efficiency
    K_global = sparse(ndof, ndof);

    % Pre-allocate storage for element stiffness matrices if requested as an output
    if num_outputs > 1 % Based on function signature, checking for more than 1 output
        element_stiffness = cell(nely, nelx, nelz);
    else
        element_stiffness = {};
    end

    % Calculate number of nodes along each dimension
    num_nodes_x = nelx + 1;
    num_nodes_y = nely + 1;

    % Loop over all elements in the design domain to assemble K_global
    for elz = 1:nelz
        for elx = 1:nelx
            for ely = 1:nely
                % --- Node Numbering ---
                % Get the 8 global node numbers for the current hexahedral element
                n1 = (elz-1)*num_nodes_x*num_nodes_y + (elx-1)*num_nodes_y + ely;
                n2 = (elz-1)*num_nodes_x*num_nodes_y + elx*num_nodes_y + ely;
                n3 = n2 + 1;
                n4 = n1 + 1;
                n5 = n1 + num_nodes_x*num_nodes_y;
                n6 = n2 + num_nodes_x*num_nodes_y;
                n7 = n3 + num_nodes_x*num_nodes_y;
                n8 = n4 + num_nodes_x*num_nodes_y;
                node_numbers = [n1, n2, n3, n4, n5, n6, n7, n8];
                
                % --- DOF Mapping ---
                % Map node numbers to global DOFs (3 DOFs per node: x, y, z)
                dof_x = 3*node_numbers - 2;
                dof_y = 3*node_numbers - 1;
                dof_z = 3*node_numbers;
                % Assemble the element's 24 DOFs vector (edof)
                edof = [dof_x(1), dof_y(1), dof_z(1), dof_x(2), dof_y(2), dof_z(2), ...
                        dof_x(3), dof_y(3), dof_z(3), dof_x(4), dof_y(4), dof_z(4), ...
                        dof_x(5), dof_y(5), dof_z(5), dof_x(6), dof_y(6), dof_z(6), ...
                        dof_x(7), dof_y(7), dof_z(7), dof_x(8), dof_y(8), dof_z(8)];
                
                % --- SIMP Interpolation ---
                % Apply SIMP material interpolation to find the element's Young's Modulus
                E_element = E_min + rho(ely, elx, elz)^p * (E0 - E_min);
                % Scale the base element stiffness matrix with the calculated modulus
                Ke_element = E_element * Ke_solid;
                
                % --- Assembly ---
                % Add the element's stiffness matrix to the corresponding location in the global matrix
                K_global(edof, edof) = K_global(edof, edof) + Ke_element;
                
                % Store the calculated element stiffness matrix if it was requested
                if num_outputs > 1
                    element_stiffness{ely, elx, elz} = Ke_element;
                end
            end
        end
    end
end