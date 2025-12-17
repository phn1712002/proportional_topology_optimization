function export_optimization_results_3d(rho_opt, problem_name, varargin)
% EXPORT_OPTIMIZATION_RESULTS_3D Export 3D optimization results to STL format
%
%   EXPORT_OPTIMIZATION_RESULTS_3D(RHO_OPT, PROBLEM_NAME) exports the final
%   3D density field from topology optimization to an STL file.
%
%   EXPORT_OPTIMIZATION_RESULTS_3D(RHO_OPT, PROBLEM_NAME, PARAM1, VAL1, ...)
%   allows specification of additional parameters.
%
% Inputs:
%   rho_opt     - Final 3D density field (nely x nelx x nelz)
%   problem_name - Name of the problem (e.g., 'cantilever_beam')
%
% Optional Parameters (name-value pairs):
%   'output_dir'    - Output directory (default: 'results/stl')
%   'isovalue'      - Isosurface threshold (default: 0.5)
%   'mode'          - STL file mode: 'binary' (default) or 'ascii'
%   'dx', 'dy', 'dz' - Element sizes (default: 1, 1, 1)
%   'volume_fraction' - Volume fraction for filename (optional)
%   'timestamp'     - Include timestamp in filename (default: true)
%   'title'         - STL file title/header (default: based on problem_name)
%
% Outputs:
%   filename    - Full path to exported STL file
%
% Example:
%   % Basic usage
%   filename = export_optimization_results_3d(rho_opt, 'cantilever_beam');
%
%   % With custom parameters
%   filename = export_optimization_results_3d(rho_opt, 'mbb_beam', ...
%       'output_dir', 'exports', 'isovalue', 0.3, 'mode', 'ascii');
%
%   % From simulation script
%   export_optimization_results_3d(rho_opt, '3D Cantilever Beam', ...
%       'volume_fraction', 0.3, 'dx', 1, 'dy', 1, 'dz', 1);
%
% Note:
%   This function requires export_density_to_stl_3d.m and stlWrite.m
%   from the stlTools toolbox.

% Parse input arguments
p = inputParser;
p.addRequired('rho_opt', @(x) isnumeric(x) && ndims(x) == 3);
p.addRequired('problem_name', @ischar);
p.addParameter('output_dir', 'results/stl', @ischar);
p.addParameter('isovalue', 0.5, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('mode', 'binary', @(x) ischar(x) && any(strcmpi(x, {'binary', 'ascii'})));
p.addParameter('dx', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('dy', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('dz', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('volume_fraction', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 0 && x <= 1));
p.addParameter('timestamp', true, @islogical);
p.addParameter('title', '', @ischar);

p.parse(rho_opt, problem_name, varargin{:});
params = p.Results;

% Get dimensions
[nely, nelx, nelz] = size(rho_opt);

% Create output directory if it doesn't exist
if ~exist(params.output_dir, 'dir')
    mkdir(params.output_dir);
    fprintf('Created directory: %s\n', params.output_dir);
end

% Generate filename
filename_base = lower(strrep(problem_name, ' ', '_'));
filename_base = regexprep(filename_base, '[^a-zA-Z0-9_-]', ''); % Remove special chars

% Add volume fraction to filename if provided
if ~isempty(params.volume_fraction)
    vol_str = sprintf('_%.2fvol', params.volume_fraction);
else
    vol_str = '';
end

% Add dimensions to filename
dim_str = sprintf('_%dx%dx%d', nelx, nely, nelz);

% Add timestamp if requested
if params.timestamp
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    time_str = ['_', timestamp];
else
    time_str = '';
end

% Construct full filename
filename = sprintf('%s%s%s%s.stl', filename_base, dim_str, vol_str, time_str);
full_path = fullfile(params.output_dir, filename);

% Generate title if not provided
if isempty(params.title)
    title_str = sprintf('%s (%.2f vol)', problem_name, mean(rho_opt(rho_opt > 0.1)));
else
    title_str = params.title;
end

% Display export information
fprintf('\n=== Exporting 3D Optimization Results ===\n');
fprintf('Problem: %s\n', problem_name);
fprintf('Dimensions: %d x %d x %d elements\n', nelx, nely, nelz);
fprintf('Element sizes: dx=%.3f, dy=%.3f, dz=%.3f\n', params.dx, params.dy, params.dz);
fprintf('Isovalue: %.3f\n', params.isovalue);
fprintf('Output file: %s\n', full_path);

% Export to STL using existing function
try
    export_density_to_stl_3d(full_path, rho_opt, ...
        params.dx, params.dy, params.dz, ...
        params.isovalue, params.mode, title_str);
    
    fprintf('Successfully exported STL file.\n');
    
    % Return filename if requested
    if nargout > 0
        varargout{1} = full_path;
    end
    
catch ME
    error('Failed to export STL file: %s\n%s', ME.message, ...
        'Make sure export_density_to_stl_3d.m and stlWrite.m are in your MATLAB path.');
end

end
