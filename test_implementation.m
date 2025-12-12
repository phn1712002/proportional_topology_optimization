% TEST_IMPLEMENTATION Quick test of the PTO implementation
%
%   This script tests individual modules and ensures they run without errors.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

fprintf('Testing PTO implementation...\n');

%% Test 1: Element stiffness matrix
fprintf('\n1. Testing element stiffness matrix...\n');
try
    [Ke, B] = element_stiffness_matrix(1.0, 0.3);
    fprintf('   Success: Ke size = %dx%d\n', size(Ke,1), size(Ke,2));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 2: FEA analysis (small problem)
fprintf('\n2. Testing FEA analysis...\n');
nelx = 10; nely = 5;
rho = ones(nely, nelx) * 0.5;
p = 3; E0 = 1.0; nu = 0.3;
% Simple BCs
fixed_dofs = 1:2*(nely+1);
load_node = (nelx+1)*(nely+1);
load_dof = 2*load_node;
load_dofs = load_dof;
load_vals = -1;

try
    [U, K_global] = FEA_analysis(nelx, nely, rho, p, E0, nu, load_dofs, load_vals, fixed_dofs);
    fprintf('   Success: U size = %d, K_global nonzeros = %d\n', length(U), nnz(K_global));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 3: Stress computation
fprintf('\n3. Testing stress computation...\n');
try
    sigma_vm = compute_stress(nelx, nely, rho, p, E0, nu, U);
    fprintf('   Success: sigma_vm size = %dx%d, max = %.4f\n', size(sigma_vm,1), size(sigma_vm,2), max(sigma_vm(:)));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 4: Compliance computation
fprintf('\n4. Testing compliance computation...\n');
try
    [C, C_total] = compute_compliance(nelx, nely, rho, p, E0, nu, U, K_global);
    fprintf('   Success: C size = %dx%d, C_total = %.4f\n', size(C,1), size(C,2), C_total);
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 5: Density filter
fprintf('\n5. Testing density filter...\n');
try
    rho_filtered = density_filter(rho, 1.5, nelx, nely);
    fprintf('   Success: filtered density range = [%.4f, %.4f]\n', min(rho_filtered(:)), max(rho_filtered(:)));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 6: Material distribution PTOs
fprintf('\n6. Testing material distribution PTOs...\n');
try
    rho_opt_ptos = material_distribution_PTOs(sigma_vm, 0.5, 1.0, 1.0);
    fprintf('   Success: rho_opt sum = %.4f\n', sum(rho_opt_ptos(:)));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 7: Material distribution PTOc
fprintf('\n7. Testing material distribution PTOc...\n');
try
    rho_opt_ptoc = material_distribution_PTOc(C, 0.5, 1.0);
    fprintf('   Success: rho_opt sum = %.4f\n', sum(rho_opt_ptoc(:)));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 8: Update density
fprintf('\n8. Testing density update...\n');
try
    rho_new = update_density(rho, rho_opt_ptos, 0.3);
    fprintf('   Success: rho_new range = [%.4f, %.4f]\n', min(rho_new(:)), max(rho_new(:)));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 9: Convergence check
fprintf('\n9. Testing convergence check...\n');
try
    [converged, change] = check_convergence(rho_new, rho, 1, 100, 1e-3, 'PTOc');
    fprintf('   Success: converged = %d, change = %.4f\n', converged, change);
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 10: PTOc main (small problem)
fprintf('\n10. Testing PTOc main (small problem, 5 iterations)...\n');
try
    max_iter = 5;
    [rho_opt, history] = PTOc_main(20, 10, 3, 1, 1.5, 0.3, 0.4, max_iter, false);
    fprintf('   Success: completed %d iterations, final volume = %.4f\n', ...
        length(history.iteration), sum(rho_opt(:))/(20*10));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

%% Test 11: PTOs main (small problem)
fprintf('\n11. Testing PTOs main (small problem, 5 iterations)...\n');
try
    max_iter = 5;
    [rho_opt, history] = PTOs_main(20, 10, 3, 1, 1.5, 0.3, 50, 0.05, max_iter, 0.4*20*10, false);
    fprintf('   Success: completed %d iterations, final volume = %.4f\n', ...
        length(history.iteration), sum(rho_opt(:))/(20*10));
catch ME
    fprintf('   FAILED: %s\n', ME.message);
end

fprintf('\n=== TEST COMPLETE ===\n');
fprintf('If all tests passed, the implementation is ready for benchmarks.\n');

% Helper function (copy from FEA_analysis.m)
function [Ke, B] = element_stiffness_matrix(E, nu)
% ELEMENT_STIFFNESS_MATRIX Compute stiffness matrix for a bilinear quad element
%
%   [KE, B] = ELEMENT_STIFFNESS_MATRIX(E, NU) returns the 8x8 stiffness matrix
%   KE and strain-displacement matrix B for a unit square element under
%   plane stress conditions.
%
%   Uses 2x2 Gauss quadrature.

% Gauss points and weights
xi = [-1/sqrt(3), 1/sqrt(3)];
eta = xi;
w = [1, 1];

% Material matrix (plane stress)
D = E / (1 - nu^2) * [1, nu, 0; nu, 1, 0; 0, 0, (1 - nu)/2];

% Initialize
Ke = zeros(8, 8);

% Shape functions and derivatives
for i = 1:2
    for j = 1:2
        % Natural coordinates
        xi_i = xi(i);
        eta_j = eta(j);
        
        % Shape functions
        N = 0.25 * [(1 - xi_i)*(1 - eta_j);
                    (1 + xi_i)*(1 - eta_j);
                    (1 + xi_i)*(1 + eta_j);
                    (1 - xi_i)*(1 + eta_j)];
        
        % Derivatives of shape functions w.r.t xi and eta
        dN_dxi = 0.25 * [-(1 - eta_j),  (1 - eta_j), (1 + eta_j), -(1 + eta_j)];
        dN_deta = 0.25 * [-(1 - xi_i), -(1 + xi_i), (1 + xi_i),  (1 - xi_i)];
        
        % Jacobian matrix (for unit square, J = 0.5*I)
        J = [dN_dxi; dN_deta] * [0, 0; 1, 0; 1, 1; 0, 1];
        detJ = abs(det(J));
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
        
        % Element stiffness contribution
        Ke = Ke + w(i) * w(j) * B' * D * B * detJ;
    end
end
end
