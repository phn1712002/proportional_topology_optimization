function K_global = assemble_global_stiffness(nelx, nely, rho, p, E0, E_min, Ke, ndof)
%% ASSEMBLE_GLOBAL_STIFFNESS Assembles the global stiffness matrix for a 2D problem
%   This function constructs the global stiffness matrix for a 2D finite element
%   analysis. It iterates through each element, calculates its stiffness using
%   the SIMP (Solid Isotropic Material with Penalization) method, and adds it
%   to the global matrix.
%
%   K_GLOBAL = ASSEMBLE_GLOBAL_STIFFNESS(...) returns the fully assembled
%   global stiffness matrix.
%
% Inputs:
%   nelx    - Number of elements in the x-direction (integer)
%   nely    - Number of elements in the y-direction (integer)
%   rho     - Matrix of element densities (nely x nelx)
%   p       - SIMP penalization factor (double)
%   E0      - Young's modulus for solid material (double)
%   E_min   - Young's modulus for void material (double, a small non-zero value)
%   Ke      - Base element stiffness matrix for a solid element (8x8 matrix)
%   ndof    - Total number of degrees of freedom in the system (integer)
%
% Outputs:
%   K_global - The assembled global stiffness matrix (sparse, ndof x ndof)
%
% TODO: Vectorize the nested loops to improve performance.

    % Initialize the global stiffness matrix as a sparse matrix for efficiency
    K_global = sparse(ndof, ndof);

    % Loop through all elements to assemble the global stiffness matrix
    for elx = 1:nelx
        for ely = 1:nely
            % --- Node Numbering ---
            % Get the global node numbers for the current element's nodes
            % (bottom-left, top-left, top-right, bottom-right)
            n1 = (nely + 1) * (elx - 1) + ely;
            n2 = (nely + 1) * elx + ely;
            
            % --- DOF Mapping ---
            % Map the 4 node numbers to the element's 8 degrees of freedom (edof)
            % Each node has 2 DOFs (x and y displacement)
            edof = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
            
            % --- SIMP Interpolation ---
            % Calculate the element's Young's Modulus based on its density
            E = E_min + rho(ely, elx)^p * (E0 - E_min);
            
            % --- Assembly ---
            % Add the element's stiffness contribution to the global matrix
            K_global(edof, edof) = K_global(edof, edof) + E * Ke;
        end
    end
end