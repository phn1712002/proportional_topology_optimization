% SIMULATE_MBB_PTOC Run PTOc on MBB beam problem
%
%   This script sets up the MBB beam (half symmetry) and runs the
%   compliance minimization PTO algorithm.
%
%   Results are saved to 'MBB_PTOc_results.mat' and figures are generated.

% Clear all
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

% Main
fprintf('=== MBB Beam - PTOc (Compliance minimization) ===\n');

% Boundary conditions for MBB beam (half symmetry)
[fixed_dofs, load_dofs, load_vals, nelx, nely] = mbb_beam_boundary(false);


% PTOc run
problem_def.nelx = nelx;
problem_def.nely = nely;
problem_def.dx = 1;
problem_def.dy = 1;
problem_def.fixed_dofs = fixed_dofs;
problem_def.load_dofs = load_dofs;
problem_def.load_vals = load_vals;

ptoc_params.E0 = 1.0;
ptoc_params.nu = 0.3;
ptoc_params.volume_fraction = 0.4;
ptoc_params.penalty = 3.0;        
ptoc_params.dist_exp = 1.0;       
ptoc_params.filter_radius = 2.0;  
ptoc_params.move_limit = 0.3;    

solver_config.max_iterations = 300;
solver_config.plot_flag = true;
solver_config.plot_frequency = 2;
disp('--- Starting PTOc Optimization ---');
[rho_opt, history, time_elapsed] = run_ptoc_optimization(problem_def, ptoc_params, solver_config);

% Save results
save('MBB_PTOc_results.mat', 'rho_opt', 'history', 'time_elapsed', 'problem_def', 'ptoc_params', 'solver_config');


% Save figure
saveas(gcf, 'MBB_PTOc_results.png');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Time elapsed: %.2f seconds\n', time_elapsed);
fprintf('Final volume fraction: %.4f\n', sum(rho_opt(:))/(nelx*nely));
fprintf('Final compliance: %.4f\n', history.compliance(end));
fprintf('Results saved to MBB_PTOc_results.mat and MBB_PTOc_results.png\n');
