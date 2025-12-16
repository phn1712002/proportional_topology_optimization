function [K_global, element_stiffness] = assemble_global_stiffness_3d(nelx, nely, nelz, rho, p, E0, E_min, Ke_solid, ndof, num_outputs)
% ASSEMBLE_GLOBAL_STIFFNESS_3D Assemble the global stiffness matrix for a 3D problem.

K_global = sparse(ndof, ndof);

% Pre-allocate if element stiffness matrices are requested
if num_outputs > 2
    element_stiffness = cell(nely, nelx, nelz);
else
    element_stiffness = {};
end

num_nodes_x = nelx + 1;
num_nodes_y = nely + 1;

for elz = 1:nelz
    for elx = 1:nelx
        for ely = 1:nely
            % --- Node Numbering ---
            % Get the 8 node numbers for the current hexahedral element
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
            edof = [dof_x(1), dof_y(1), dof_z(1), dof_x(2), dof_y(2), dof_z(2), ...
                    dof_x(3), dof_y(3), dof_z(3), dof_x(4), dof_y(4), dof_z(4), ...
                    dof_x(5), dof_y(5), dof_z(5), dof_x(6), dof_y(6), dof_z(6), ...
                    dof_x(7), dof_y(7), dof_z(7), dof_x(8), dof_y(8), dof_z(8)];
            
            % --- SIMP Interpolation ---
            E_element = E_min + rho(ely, elx, elz)^p * (E0 - E_min);
            Ke_element = E_element * Ke_solid;
            
            % --- Assembly ---
            K_global(edof, edof) = K_global(edof, edof) + Ke_element;
            
            % Store element stiffness matrix if requested
            if num_outputs > 2
                element_stiffness{ely, elx, elz} = Ke_element;
            end
        end
    end
end
end