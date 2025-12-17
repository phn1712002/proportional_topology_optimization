function export_density_to_stl_3d(filename, rho, dx, dy, dz, isovalue, mode, title_str)
% EXPORT_DENSITY_TO_STL_3D Export 3D density field to STL format
%
%   EXPORT_DENSITY_TO_STL_3D(FILENAME, RHO, DX, DY, DZ, ISOVALUE, MODE, TITLE_STR)
%   exports a 3D density field to an STL file using isosurface extraction.
%
% Inputs:
%   filename    - Output STL filename (e.g., 'result.stl')
%   rho         - 3D density field (nely x nelx x nelz)
%   dx, dy, dz  - Element sizes in x, y, z directions (default: 1, 1, 1)
%   isovalue    - Isosurface threshold value (default: 0.5)
%   mode        - STL file mode: 'binary' (default) or 'ascii'
%   title_str   - Title/header for STL file (default: '3D Topology Optimization')
%
% Outputs:
%   None (writes STL file to disk)
%
% Example:
%   % Export final density from optimization
%   export_density_to_stl_3d('cantilever_3d.stl', rho_opt, 1, 1, 1, 0.5, 'binary', '3D Plate');
%
%   % Export with custom element sizes
%   export_density_to_stl_3d('result.stl', rho, 0.5, 0.5, 1.0, 0.3, 'ascii');
%
% Note:
%   This function requires the stlTools toolbox (specifically stlWrite.m)
%   which should be in the MATLAB path.

% Check inputs
if nargin < 8
    title_str = '3D Topology Optimization';
end
if nargin < 7
    mode = 'binary';
end
if nargin < 6
    isovalue = 0.5;
end
if nargin < 5
    dz = 1;
end
if nargin < 4
    dy = 1;
end
if nargin < 3
    dx = 1;
end

% Validate inputs
if ~ischar(filename)
    error('Filename must be a string');
end
if ~isnumeric(rho) || ndims(rho) ~= 3
    error('rho must be a 3D numeric array');
end
if ~isscalar(isovalue) || ~isnumeric(isovalue)
    error('isovalue must be a numeric scalar');
end
if ~ischar(mode) || ~any(strcmpi(mode, {'binary', 'ascii'}))
    error('mode must be either ''binary'' or ''ascii''');
end

% Get dimensions
[nely, nelx, nelz] = size(rho);

% Create coordinate grids scaled by element sizes
% Note: MATLAB's isosurface expects coordinates in meshgrid format
% We create coordinates at element centers
x = (0.5:nelx) * dx;  % Element centers in x direction
y = (0.5:nely) * dy;  % Element centers in y direction  
z = (0.5:nelz) * dz;  % Element centers in z direction

% Create meshgrid for isosurface
[X, Y, Z] = meshgrid(x, y, z);

% Extract isosurface at specified threshold
% isosurface returns faces and vertices of the surface
[faces, vertices] = isosurface(X, Y, Z, rho, isovalue);

% Check if surface was found
if isempty(faces) || isempty(vertices)
    warning('No surface found at isovalue = %.3f. Try adjusting isovalue.', isovalue);
    
    % Try to find a reasonable isovalue if none found
    rho_min = min(rho(:));
    rho_max = max(rho(:));
    suggested_isovalue = (rho_min + rho_max) / 2;
    
    if rho_min < rho_max
        fprintf('Density range: [%.3f, %.3f]\n', rho_min, rho_max);
        fprintf('Trying isovalue = %.3f\n', suggested_isovalue);
        
        [faces, vertices] = isosurface(X, Y, Z, rho, suggested_isovalue);
        
        if isempty(faces) || isempty(vertices)
            error('No surface found even with adjusted isovalue. Check density field.');
        end
    else
        error('Density field is constant (min = max = %.3f). Cannot extract surface.', rho_min);
    end
end

% Create structure for stlWrite
fv.faces = faces;
fv.vertices = vertices;

% Write STL file using stlWrite
try
    stlWrite(filename, fv, 'mode', mode, 'title', title_str);
    fprintf('Successfully exported STL file: %s\n', filename);
    fprintf('  Dimensions: %d x %d x %d elements\n', nelx, nely, nelz);
    fprintf('  Element sizes: dx=%.3f, dy=%.3f, dz=%.3f\n', dx, dy, dz);
    fprintf('  Isovalue: %.3f\n', isovalue);
    fprintf('  Number of faces: %d\n', size(faces, 1));
    fprintf('  Number of vertices: %d\n', size(vertices, 1));
    fprintf('  File mode: %s\n', mode);
catch ME
    error('Failed to write STL file: %s\nMake sure stlWrite.m is in your MATLAB path.', ME.message);
end

end
