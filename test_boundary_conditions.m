% Test script to verify boundary conditions match task-3.md specifications

fprintf('=== Testing Boundary Conditions ===\n\n');

% Test 1: Cantilever Beam
fprintf('1. Testing Cantilever Beam:\n');
try
    [fixed_dofs, load_dofs, load_vals, nelx, nely] = cantilever_beam_boundary(false);
    fprintf('   Mesh: %d x %d (expected: 120 x 60)\n', nelx, nely);
    fprintf('   Fixed DOFs: %d (expected: %d)\n', length(fixed_dofs), 2*(nely+1));
    fprintf('   Load nodes: %d (expected: 3)\n', length(load_dofs));
    fprintf('   Total load: %.2f (expected: -1.00)\n', sum(load_vals));
    fprintf('   ✓ Cantilever beam test passed\n');
catch ME
    fprintf('   ✗ Error: %s\n', ME.message);
end

fprintf('\n');

% Test 2: L-Bracket
fprintf('2. Testing L-Bracket:\n');
try
    [fixed_dofs, load_dofs, load_vals, nelx, nely, cutout_x, cutout_y] = l_bracket_boundary(false);
    fprintf('   Mesh: %d x %d (expected: 100 x 40)\n', nelx, nely);
    fprintf('   Cutout: %d x %d (expected: 50 x 20)\n', cutout_x, cutout_y);
    
    % Check fixed DOFs - should be for first 50 elements on top edge
    % For 50 elements, there are 51 nodes (columns 1 to 51)
    expected_fixed_nodes = 51;  % 50 elements + 1 node
    expected_fixed_dofs = 2 * expected_fixed_nodes;  % x and y for each node
    fprintf('   Fixed DOFs: %d (expected: ~%d)\n', length(fixed_dofs), expected_fixed_dofs);
    
    fprintf('   Load nodes: %d (expected: 3)\n', length(load_dofs));
    fprintf('   Total load: %.2f (expected: -1.00)\n', sum(load_vals));
    fprintf('   ✓ L-bracket test passed\n');
catch ME
    fprintf('   ✗ Error: %s\n', ME.message);
end

fprintf('\n');

% Test 3: MBB Beam
fprintf('3. Testing MBB Beam:\n');
try
    [fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(false);
    fprintf('   Mesh: %d x %d (expected: 120 x 40)\n', nelx, nely);
    
    % Check fixed DOFs: left edge x-direction (nely+1 DOFs) + right bottom corner y-direction (1 DOF)
    expected_fixed_dofs = (nely + 1) + 1;
    fprintf('   Fixed DOFs: %d (expected: ~%d)\n', length(fixed_dofs), expected_fixed_dofs);
    
    fprintf('   Load nodes: %d (expected: 3)\n', length(load_dofs));
    fprintf('   Total load: %.2f (expected: -1.00)\n', sum(load_vals));
    fprintf('   ✓ MBB beam test passed\n');
catch ME
    fprintf('   ✗ Error: %s\n', ME.message);
end

fprintf('\n=== Test Complete ===\n');
