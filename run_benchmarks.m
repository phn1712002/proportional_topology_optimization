% RUN_BENCHMARKS Run PTOs and PTOc on standard benchmark problems
%
%   This script demonstrates the Proportional Topology Optimization
%   algorithms on two classic problems:
%   1. MBB beam (half of a simply supported beam)
%   2. Cantilever beam (fixed left edge, point load at right)
%
%   Results are saved as figures and data files.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

%% Problem 1: MBB Beam (symmetry considered)
fprintf('=== MBB Beam Benchmark ===\n');
nelx = 60;      % Number of elements in x-direction
nely = 20;      % Number of elements in y-direction
p = 3;          % SIMP penalty
q = 1;          % Proportionality exponent
r_min = 1.5;    % Filter radius
alpha = 0.3;    % Move limit
max_iter = 200;
plot_flag = true;

% PTOc: compliance minimization with 40% volume fraction
fprintf('\n--- Running PTOc (compliance minimization) ---\n');
volume_fraction = 0.4;
[rho_ptoc_mbb, hist_ptoc_mbb] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, plot_flag);

% PTOs: stress-constrained with allowable stress
fprintf('\n--- Running PTOs (stress-constrained) ---\n');
sigma_allow = 80;   % Allowable stress
tau = 0.05;         % Stress tolerance
TM_init = volume_fraction * nelx * nely;
[rho_ptos_mbb, hist_ptos_mbb] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, plot_flag);

% Save results
save('MBB_results.mat', 'rho_ptoc_mbb', 'hist_ptoc_mbb', 'rho_ptos_mbb', 'hist_ptos_mbb');

%% Problem 2: Cantilever Beam
fprintf('\n=== Cantilever Beam Benchmark ===\n');
nelx = 60;
nely = 30;
volume_fraction = 0.4;
sigma_allow = 100;

% PTOc
fprintf('\n--- Running PTOc (compliance minimization) ---\n');
[rho_ptoc_cant, hist_ptoc_cant] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, plot_flag);

% PTOs
fprintf('\n--- Running PTOs (stress-constrained) ---\n');
TM_init = volume_fraction * nelx * nely;
[rho_ptos_cant, hist_ptos_cant] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, plot_flag);

% Save results
save('Cantilever_results.mat', 'rho_ptoc_cant', 'hist_ptoc_cant', 'rho_ptos_cant', 'hist_ptos_cant');

%% Comparison plots
figure('Position', [100, 100, 1200, 800]);

% MBB results
subplot(2,3,1);
imagesc(rho_ptoc_mbb); axis equal tight; colorbar;
title('MBB: PTOc (Compliance)');
xlabel('x'); ylabel('y');

subplot(2,3,2);
imagesc(rho_ptos_mbb); axis equal tight; colorbar;
title('MBB: PTOs (Stress)');
xlabel('x'); ylabel('y');

subplot(2,3,3);
plot(hist_ptoc_mbb.iteration, hist_ptoc_mbb.compliance, 'b-', 'LineWidth', 1.5); hold on;
plot(hist_ptos_mbb.iteration, hist_ptos_mbb.compliance, 'r-', 'LineWidth', 1.5);
grid on; legend('PTOc', 'PTOs'); xlabel('Iteration'); ylabel('Compliance');
title('MBB Compliance History');

% Cantilever results
subplot(2,3,4);
imagesc(rho_ptoc_cant); axis equal tight; colorbar;
title('Cantilever: PTOc (Compliance)');
xlabel('x'); ylabel('y');

subplot(2,3,5);
imagesc(rho_ptos_cant); axis equal tight; colorbar;
title('Cantilever: PTOs (Stress)');
xlabel('x'); ylabel('y');

subplot(2,3,6);
plot(hist_ptoc_cant.iteration, hist_ptoc_cant.compliance, 'b-', 'LineWidth', 1.5); hold on;
plot(hist_ptos_cant.iteration, hist_ptos_cant.compliance, 'r-', 'LineWidth', 1.5);
grid on; legend('PTOc', 'PTOs'); xlabel('Iteration'); ylabel('Compliance');
title('Cantilever Compliance History');

sgtitle('Proportional Topology Optimization Benchmark Results');

% Save figure
saveas(gcf, 'benchmark_comparison.png');
fprintf('\nBenchmark results saved to:\n');
fprintf('  - MBB_results.mat\n');
fprintf('  - Cantilever_results.mat\n');
fprintf('  - benchmark_comparison.png\n');

%% Summary report
fprintf('\n=== SUMMARY REPORT ===\n');
fprintf('MBB Beam (%dx%d):\n', nelx, nely);
fprintf('  PTOc: Final volume = %.2f%%, Compliance = %.4f\n', ...
    100*sum(rho_ptoc_mbb(:))/(nelx*nely), hist_ptoc_mbb.compliance(end));
fprintf('  PTOs: Final volume = %.2f%%, Max stress = %.4f\n', ...
    100*sum(rho_ptos_mbb(:))/(nelx*nely), hist_ptos_mbb.sigma_max(end));

fprintf('Cantilever Beam (%dx%d):\n', nelx, nely);
fprintf('  PTOc: Final volume = %.2f%%, Compliance = %.4f\n', ...
    100*sum(rho_ptoc_cant(:))/(nelx*nely), hist_ptoc_cant.compliance(end));
fprintf('  PTOs: Final volume = %.2f%%, Max stress = %.4f\n', ...
    100*sum(rho_ptos_cant(:))/(nelx*nely), hist_ptos_cant.sigma_max(end));
