function export_to_stl_from_density(rho, filename, varargin)
% EXPORT_TO_STL_FROM_DENSITY Creates a 3D mesh and saves it as an STL file.
%
%   Takes a 3D density field (a matrix), generates a triangular mesh using
%   an isosurface, scales it to physical dimensions, and exports it to an
%   STL file for 3D printing or further analysis in CAD software.
%
% Inputs:
%   rho        - A 3D matrix (nely x nelx x nelz) representing the density field.
%   filename   - The full path and name for the output STL file (e.g., 'results/my_model.stl').
%
% Optional Inputs (Name-Value Pairs):
%   'Threshold'   - The density value at which to create the surface (scalar).
%                   Represents the boundary between solid and void.
%                   Default is 0.5.
%   'ElementSize' - A 1x3 vector [dx, dy, dz] specifying the physical size of
%                   a single element. Used for scaling the final geometry.
%                   Default is [1, 1, 1].
%
% Usage Example:
%   % 1. Simple export with default settings
%   export_to_stl_from_density(rho_final, 'output.stl');
%
%   % 2. Export with custom threshold and element scaling
%   element_dims = [0.1, 0.1, 0.1]; % Each element is 0.1mm
%   export_to_stl_from_density(rho_final, 'output_scaled.stl', ...
%                              'Threshold', 0.4, 'ElementSize', element_dims);

% --- 1. Parse Optional Inputs ---
p = inputParser;
addParameter(p, 'Threshold', 0.5, @isnumeric);
addParameter(p, 'ElementSize', [1, 1, 1], @(x) isnumeric(x) && isvector(x) && length(x)==3);
parse(p, varargin{:});

threshold = p.Results.Threshold;
element_size = p.Results.ElementSize;
dx = element_size(1);
dy = element_size(2);
dz = element_size(3);

% --- 2. Main Export Logic ---
try
    % Check if the input is a valid 3D array
    if ndims(rho) < 3 || size(rho, 3) <= 1
        fprintf('STL export skipped: Input density field is not 3D.\n');
        return;
    end
    
    [nely, nelx, nelz] = size(rho);
    
    % Create a grid. Isosurface expects grid inputs corresponding to the
    % dimensions of the data volume 'rho'.
    [X, Y, Z] = meshgrid(1:nelx, 1:nely, 1:nelz);
    
    fprintf('Generating isosurface at threshold %.2f...\n', threshold);
    % Generate triangular faces and vertices from the density data
    [faces, verts] = isosurface(X, Y, Z, rho, threshold);
    
    % Check if any geometry was created
    if isempty(faces)
        fprintf('STL export skipped: No surface found at the specified threshold (%.2f).\n', threshold);
        return;
    end

    % Scale vertices to reflect actual physical dimensions
    verts(:,1) = verts(:,1) * dx; % Scale X coordinates
    verts(:,2) = verts(:,2) * dy; % Scale Y coordinates
    verts(:,3) = verts(:,3) * dz; % Scale Z coordinates
    
    % Ensure the directory for the output file exists
    output_dir = fileparts(filename);
    if ~isempty(output_dir) && ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Write to the STL file
    stlwrite(filename, faces, verts);
    
    fprintf('STL file exported successfully to: %s\n', filename);

catch ME % Catch any error that occurs
    fprintf('ERROR: Could not export STL file.\n');
    fprintf('Please ensure the ''stlwrite'' function from the MATLAB File Exchange is on your path.\n');
    fprintf('Error details: %s\n', ME.message);
end

end