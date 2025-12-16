function rho_filtered = density_filter_3d(rho, r_min, nelx, nely, nelz, dx, dy, dz)
% DENSITY_FILTER_3D Apply 3D cone-shaped density filter.
%
%   Prevents checkerboarding and ensures mesh-independence in 3D topology
%   optimization.
%
%   RHO_FILTERED = DENSITY_FILTER_3D(RHO, R_MIN, NELX, NELY, NELZ, DX, DY, DZ)
%   filters the 3D density field using a convolution with a spherical-cone
%   shaped kernel of radius R_MIN.
%
% Inputs:
%   rho         - 3D density field (nely x nelx x nelz)
%   r_min       - Filter radius (in physical units)
%   nelx, nely, nelz - Number of elements in x, y, z directions
%   dx, dy, dz  - Element sizes in x, y, z directions (optional, default to 1)
%
% Outputs:
%   rho_filtered - Filtered 3D density field (nely x nelx x nelz)
%
% Formula:
%   w_ijk = max(0, r_min - dist(i,j,k))
%   rho_filtered_i = sum_{j,k} w_ijk * rho_{j,k} / sum_{j,k} w_ijk
%
% Implementation uses MATLAB's `convn` for N-dimensional convolution.

% --- 1. Handle Default Arguments ---
if nargin < 6
    dx = 1;
    dy = 1;
    dz = 1;
end

% --- 2. Prepare Kernel ---
% Ensure input density field has the correct 3D shape
rho = reshape(rho, nely, nelx, nelz);

% Determine the size of the convolution kernel in elements
% This should be large enough to contain the sphere of radius r_min
kernel_half_size = ceil(r_min / min([dx, dy, dz]));
kernel_range = -kernel_half_size:kernel_half_size;

% Create a 3D grid of indices for the kernel
[ii, jj, kk] = meshgrid(kernel_range, kernel_range, kernel_range);

% Calculate the physical distance from the center for each point in the kernel
dist = sqrt((ii*dx).^2 + (jj*dy).^2 + (kk*dz).^2);

% Create the cone-shaped weight kernel
% The weight is linearly decreasing with distance
kernel = max(0, r_min - dist);

% Check if kernel sum is non-zero to avoid division by zero
if sum(kernel(:)) > 1e-9
    % Normalize the kernel to preserve the total volume (mass) of the material
    kernel = kernel / sum(kernel(:));
else
    % If r_min is too small, kernel might be all zeros. In this case,
    % filtering has no effect. To handle this, use a Dirac delta kernel.
    % This is an edge case but good to handle gracefully.
    center_idx = kernel_half_size + 1;
    kernel = zeros(size(kernel));
    kernel(center_idx, center_idx, center_idx) = 1;
end

% --- 3. Apply Convolution ---
% Use 'convn' for 3D convolution. The 'same' option ensures the output
% has the same size as the input 'rho' by handling boundaries appropriately.
rho_filtered = convn(rho, kernel, 'same');

% Ensure output shape is consistent (optional but good practice)
rho_filtered = reshape(rho_filtered, nely, nelx, nelz);

end