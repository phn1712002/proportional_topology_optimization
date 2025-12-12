function rho_filtered = density_filter(rho, r_min, nelx, nely, dx, dy)
% DENSITY_FILTER Apply cone-shaped density filter to prevent checkerboarding
%
%   RHO_FILTERED = DENSITY_FILTER(RHO, R_MIN, NELX, NELY, DX, DY)
%   filters the density field using a convolution with a cone-shaped kernel
%   of radius R_MIN. The filter preserves volume and ensures mesh-independence.
%
% Inputs:
%   rho         - Density field (nely x nelx)
%   r_min       - Filter radius (in physical units)
%   nelx, nely  - Number of elements in x and y directions
%   dx, dy      - Element sizes in x and y directions (default: dx=1, dy=1)
%
% Outputs:
%   rho_filtered - Filtered density field (nely x nelx)
%
% Formula:
%   w_ij = max(0, r_min - dist(i,j))
%   rho_filtered_i = sum_j w_ij * rho_j / sum_j w_ij
%
% Implementation uses a convolution kernel for efficiency.

% Default element sizes
if nargin < 5
    dx = 1;
    dy = 1;
end

% Ensure rho is matrix
rho = reshape(rho, nely, nelx);

% Determine kernel size in elements
kernel_half = ceil(r_min / min(dx, dy));

% Create coordinate grids
[ii, jj] = meshgrid(-kernel_half:kernel_half, -kernel_half:kernel_half);

% Physical distances
dist = sqrt((ii*dx).^2 + (jj*dy).^2);

% Cone-shaped weight kernel
kernel = max(0, r_min - dist);

% Normalize kernel (sum of weights)
kernel = kernel / sum(kernel(:));

% Apply convolution (same boundary, zero-padded)
rho_filtered = conv2(rho, kernel, 'same');

% Ensure same shape
rho_filtered = reshape(rho_filtered, nely, nelx);
end
