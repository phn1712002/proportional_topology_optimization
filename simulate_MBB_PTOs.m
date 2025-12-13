% SIMULATE_MBB_PTOS Run PTOs on MBB beam problem
%
%   This script sets up the MBB beam (half symmetry) and runs the
%   stress-constrained PTO algorithm.
%
%   Results are saved to 'MBB_PTOs_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== MBB Beam - PTOs (Stress-constrained) ===\n');

% Boundary conditions for MBB beam (half symmetry)
[fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(false);

% Run PTOs
problem_def.nelx = nelx;
problem_def.nely = nely;
problem_def.dx = 1;
problem_def.dy = 1;
problem_def.fixed_dofs = fixed_dofs;
problem_def.load_dofs = load_dofs;
problem_def.load_vals = load_vals;

ptos_params.E0 = 1.0;
ptos_params.nu = 0.3;
ptos_params.penalty = 3.0;
ptos_params.dist_exp = 1.0;
ptos_params.filter_radius = 2.0;
ptos_params.move_limit = 0.3;

ptos_params.allowable_stress = 100;
ptos_params.stress_tau = 0.05;
ptos_params.initial_tm = 0.4 * nelx * nely;

solver_config.max_iterations = 300;
solver_config.plot_flag = true;
solver_config.plot_frequency = 2;

disp('--- Starting PTOs Optimization ---');
[rho_opt, history, time_elapsed] = run_ptos_optimization(problem_def, ptos_params, solver_config);

% Save results
save('MBB_PTOs_results.mat', 'rho_opt', 'history', 'time_elapsed', 'problem_def', 'ptoc_params', 'solver_config');

% Save figure
saveas(gcf, 'MBB_PTOs_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final max stress: %.4f\n', max(sigma_vm(:)));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to MBB_PTOs_results.mat and MBB_PTOs_results.png\n');
