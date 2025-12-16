function K_global = assemble_global_stiffness(nelx, nely, rho, p, E0, E_min, Ke, ndof)
    % Initialize global stiffness matrix
    K_global = sparse(ndof, ndof);

    % Assembly
    for elx = 1:nelx
        for ely = 1:nely
            % Element index
            n1 = (nely + 1) * (elx - 1) + ely;
            n2 = (nely + 1) * elx + ely;
            
            % Element degrees of freedom
            edof = [2*n1-1, 2*n1, 2*n2-1, 2*n2, 2*n2+1, 2*n2+2, 2*n1+1, 2*n1+2];
            
            % SIMP interpolation
            E = E_min + rho(ely, elx)^p * (E0 - E_min);
            
            % Add to global stiffness
            K_global(edof, edof) = K_global(edof, edof) + E * Ke;
        end
    end
end