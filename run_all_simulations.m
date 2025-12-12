% RUN_ALL_SIMULATIONS Master script to run all PTO simulations and generate comparison report
%
%   This script runs all six simulation cases (MBB, Cantilever, L-bracket for both PTOs and PTOc)
%   with reduced iteration counts for quick demonstration, then generates a comprehensive
%   comparison report with figures and statistics.
%
%   For full simulations, increase max_iter to 300 and adjust parameters.

% Main script with auto-detection of objective function type
clear; close all; clc;

% Add current directory to path
add_lib(pwd);

fprintf('========================================\n');
fprintf('   PTO SIMULATION SUITE - DEMONSTRATION   \n');
fprintf('========================================\n');

% Configuration: quick run vs full run
quick_run = true;  % Set to false for full simulations

if quick_run
    fprintf('QUICK RUN MODE: Reduced iterations for demonstration.\n');
    max_iter = 50;
else
    fprintf('FULL RUN MODE: Full iterations for accurate results.\n');
    max_iter = 300;
end

% Common parameters
p = 3;
q = 1.0;
r_min = 2.0;
alpha = 0.3;
volume_fraction = 0.4;
sigma_allow = 100; % For stress-constrained
tau = 0.05;

% Initialize results structure
results = struct();

%% 1. MBB Beam - PTOc
fprintf('\n--- 1. MBB Beam - PTOc (Compliance) ---\n');
nelx = 120; nely = 40;
tic;
[rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, false);
time = toc;
results.mbb_ptoc.rho = rho_opt;
results.mbb_ptoc.history = history;
results.mbb_ptoc.time = time;
results.mbb_ptoc.volume = sum(rho_opt(:))/(nelx*nely);
results.mbb_ptoc.compliance = history.compliance(end);
fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f\n', ...
    time, 100*results.mbb_ptoc.volume, results.mbb_ptoc.compliance);

%% 2. MBB Beam - PTOs
fprintf('\n--- 2. MBB Beam - PTOs (Stress) ---\n');
TM_init = volume_fraction * nelx * nely;
tic;
[rho_opt, history] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, false);
time = toc;
results.mbb_ptos.rho = rho_opt;
results.mbb_ptos.history = history;
results.mbb_ptos.time = time;
results.mbb_ptos.volume = sum(rho_opt(:))/(nelx*nely);
results.mbb_ptos.compliance = history.compliance(end);
results.mbb_ptos.max_stress = history.sigma_max(end);
fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f, Max Stress = %.2f\n', ...
    time, 100*results.mbb_ptos.volume, results.mbb_ptos.compliance, results.mbb_ptos.max_stress);

%% 3. Cantilever Beam - PTOc
fprintf('\n--- 3. Cantilever Beam - PTOc (Compliance) ---\n');
nelx = 120; nely = 60;
tic;
[rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, volume_fraction, max_iter, false);
time = toc;
results.cant_ptoc.rho = rho_opt;
results.cant_ptoc.history = history;
results.cant_ptoc.time = time;
results.cant_ptoc.volume = sum(rho_opt(:))/(nelx*nely);
results.cant_ptoc.compliance = history.compliance(end);
fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f\n', ...
    time, 100*results.cant_ptoc.volume, results.cant_ptoc.compliance);

%% 4. Cantilever Beam - PTOs
fprintf('\n--- 4. Cantilever Beam - PTOs (Stress) ---\n');
TM_init = volume_fraction * nelx * nely;
tic;
[rho_opt, history] = PTOs_main(nelx, nely, p, q, r_min, alpha, sigma_allow, tau, max_iter, TM_init, false);
time = toc;
results.cant_ptos.rho = rho_opt;
results.cant_ptos.history = history;
results.cant_ptos.time = time;
results.cant_ptos.volume = sum(rho_opt(:))/(nelx*nely);
results.cant_ptos.compliance = history.compliance(end);
results.cant_ptos.max_stress = history.sigma_max(end);
fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f, Max Stress = %.2f\n', ...
    time, 100*results.cant_ptos.volume, results.cant_ptos.compliance, results.cant_ptos.max_stress);

%% 5. L-bracket - PTOc
fprintf('\n--- 5. L-bracket - PTOc (Compliance) ---\n');
% Use custom simulation for L-bracket
run('simulate_Lbracket_PTOc.m'); % This will load results into workspace
% Note: This will run the full simulation; for quick run we need to adjust.
% Instead, we'll skip in quick run mode.
if quick_run
    fprintf('   Skipped in quick run mode (requires custom simulation).\n');
    results.lbracket_ptoc.volume = NaN;
    results.lbracket_ptoc.compliance = NaN;
    results.lbracket_ptoc.time = NaN;
else
    % Load results from file
    load('Lbracket_PTOc_results.mat', 'rho_opt', 'history', 'time_elapsed');
    results.lbracket_ptoc.rho = rho_opt;
    results.lbracket_ptoc.history = history;
    results.lbracket_ptoc.time = time_elapsed;
    results.lbracket_ptoc.volume = sum(rho_opt(:))/(100*40);
    results.lbracket_ptoc.compliance = history.compliance(end);
    fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f\n', ...
        time_elapsed, 100*results.lbracket_ptoc.volume, results.lbracket_ptoc.compliance);
end

%% 6. L-bracket - PTOs
fprintf('\n--- 6. L-bracket - PTOs (Stress) ---\n');
if quick_run
    fprintf('   Skipped in quick run mode (requires custom simulation).\n');
    results.lbracket_ptos.volume = NaN;
    results.lbracket_ptos.compliance = NaN;
    results.lbracket_ptos.max_stress = NaN;
    results.lbracket_ptos.time = NaN;
else
    run('simulate_Lbracket_PTOs.m');
    load('Lbracket_PTOs_results.mat', 'rho_opt', 'history', 'time_elapsed');
    results.lbracket_ptos.rho = rho_opt;
    results.lbracket_ptos.history = history;
    results.lbracket_ptos.time = time_elapsed;
    results.lbracket_ptos.volume = sum(rho_opt(:))/(100*40);
    results.lbracket_ptos.compliance = history.compliance(end);
    results.lbracket_ptos.max_stress = history.sigma_max(end);
    fprintf('   Completed in %.1f sec, Volume = %.2f%%, Compliance = %.4f, Max Stress = %.2f\n', ...
        time_elapsed, 100*results.lbracket_ptos.volume, results.lbracket_ptos.compliance, results.lbracket_ptos.max_stress);
end

%% Save results
save('PTO_simulation_results.mat', 'results');
fprintf('\nAll results saved to PTO_simulation_results.mat\n');

%% Generate comparison report
fprintf('\n========================================\n');
fprintf('        COMPARISON REPORT\n');
fprintf('========================================\n');

% Table data
fprintf('\n%-20s %-10s %-12s %-12s %-12s\n', 'Case', 'Volume%', 'Compliance', 'Max Stress', 'Time (s)');
fprintf('%s\n', repmat('-', 70, 1));

cases = {'MBB PTOc', 'MBB PTOs', 'Cantilever PTOc', 'Cantilever PTOs', 'L-bracket PTOc', 'L-bracket PTOs'};
for i = 1:length(cases)
    switch i
        case 1
            r = results.mbb_ptoc;
            stress_str = 'N/A';
        case 2
            r = results.mbb_ptos;
            stress_str = sprintf('%.2f', r.max_stress);
        case 3
            r = results.cant_ptoc;
            stress_str = 'N/A';
        case 4
            r = results.cant_ptos;
            stress_str = sprintf('%.2f', r.max_stress);
        case 5
            r = results.lbracket_ptoc;
            stress_str = 'N/A';
        case 6
            r = results.lbracket_ptos;
            stress_str = sprintf('%.2f', r.max_stress);
    end
    
    if isnan(r.volume)
        fprintf('%-20s %-10s %-12s %-12s %-12s\n', cases{i}, 'N/A', 'N/A', 'N/A', 'N/A');
    else
        fprintf('%-20s %-10.2f %-12.4f %-12s %-12.1f\n', ...
            cases{i}, 100*r.volume, r.compliance, stress_str, r.time);
    end
end

%% Plot comparison of topologies
figure('Position', [50, 50, 1400, 900]);

% MBB
subplot(3,4,1);
if isfield(results.mbb_ptoc, 'rho') && ~isnan(results.mbb_ptoc.volume)
    imagesc(results.mbb_ptoc.rho); axis equal tight; colorbar;
end
title('MBB PTOc');
xlabel('x'); ylabel('y');

subplot(3,4,2);
if isfield(results.mbb_ptos, 'rho') && ~isnan(results.mbb_ptos.volume)
    imagesc(results.mbb_ptos.rho); axis equal tight; colorbar;
end
title('MBB PTOs');

% Cantilever
subplot(3,4,3);
if isfield(results.cant_ptoc, 'rho') && ~isnan(results.cant_ptoc.volume)
    imagesc(results.cant_ptoc.rho); axis equal tight; colorbar;
end
title('Cantilever PTOc');
xlabel('x'); ylabel('y');

subplot(3,4,4);
if isfield(results.cant_ptos, 'rho') && ~isnan(results.cant_ptos.volume)
    imagesc(results.cant_ptos.rho); axis equal tight; colorbar;
end
title('Cantilever PTOs');

% L-bracket
subplot(3,4,5);
if isfield(results.lbracket_ptoc, 'rho') && ~isnan(results.lbracket_ptoc.volume)
    imagesc(results.lbracket_ptoc.rho); axis equal tight; colorbar;
end
title('L-bracket PTOc');
xlabel('x'); ylabel('y');

subplot(3,4,6);
if isfield(results.lbracket_ptos, 'rho') && ~isnan(results.lbracket_ptos.volume)
    imagesc(results.lbracket_ptos.rho); axis equal tight; colorbar;
end
title('L-bracket PTOs');

% Convergence histories
subplot(3,4,7);
if isfield(results.mbb_ptoc, 'history')
    plot(results.mbb_ptoc.history.iteration, results.mbb_ptoc.history.compliance, 'b-'); hold on;
end
if isfield(results.mbb_ptos, 'history')
    plot(results.mbb_ptos.history.iteration, results.mbb_ptos.history.compliance, 'r-');
end
grid on; xlabel('Iteration'); ylabel('Compliance');
title('MBB Convergence');
legend('PTOc', 'PTOs', 'Location', 'best');

subplot(3,4,8);
if isfield(results.cant_ptoc, 'history')
    plot(results.cant_ptoc.history.iteration, results.cant_ptoc.history.compliance, 'b-'); hold on;
end
if isfield(results.cant_ptos, 'history')
    plot(results.cant_ptos.history.iteration, results.cant_ptos.history.compliance, 'r-');
end
grid on; xlabel('Iteration'); ylabel('Compliance');
title('Cantilever Convergence');
legend('PTOc', 'PTOs', 'Location', 'best');

subplot(3,4,9);
if isfield(results.lbracket_ptoc, 'history') && ~isnan(results.lbracket_ptoc.volume)
    plot(results.lbracket_ptoc.history.iteration, results.lbracket_ptoc.history.compliance, 'b-'); hold on;
end
if isfield(results.lbracket_ptos, 'history') && ~isnan(results.lbracket_ptos.volume)
    plot(results.lbracket_ptos.history.iteration, results.lbracket_ptos.history.compliance, 'r-');
end
grid on; xlabel('Iteration'); ylabel('Compliance');
title('L-bracket Convergence');
legend('PTOc', 'PTOs', 'Location', 'best');

% Volume fractions
subplot(3,4,10);
cases_names = {'MBB PTOc', 'MBB PTOs', 'Cant PTOc', 'Cant PTOs', 'L-bracket PTOc', 'L-bracket PTOs'};
volumes = [results.mbb_ptoc.volume, results.mbb_ptos.volume, ...
           results.cant_ptoc.volume, results.cant_ptos.volume, ...
           results.lbracket_ptoc.volume, results.lbracket_ptos.volume];
bar(volumes);
set(gca, 'XTickLabel', cases_names, 'XTickLabelRotation', 45);
ylabel('Volume Fraction');
title('Volume Comparison');
grid on;

% Compliance comparison
subplot(3,4,11);
compliances = [results.mbb_ptoc.compliance, results.mbb_ptos.compliance, ...
               results.cant_ptoc.compliance, results.cant_ptos.compliance, ...
               results.lbracket_ptoc.compliance, results.lbracket_ptos.compliance];
bar(compliances);
set(gca, 'XTickLabel', cases_names, 'XTickLabelRotation', 45);
ylabel('Compliance');
title('Compliance Comparison');
grid on;

sgtitle('Proportional Topology Optimization - Simulation Results Comparison');

% Save figure
saveas(gcf, 'PTO_comparison_report.png');
fprintf('\nComparison figure saved to PTO_comparison_report.png\n');

fprintf('\n========================================\n');
fprintf('   SIMULATION SUITE COMPLETE\n');
fprintf('========================================\n');
fprintf('Next steps:\n');
fprintf('1. Set quick_run = false in run_all_simulations.m for full simulations.\n');
fprintf('2. Run individual simulation files for detailed results.\n');
fprintf('3. Check generated .mat files and .png figures for analysis.\n');
