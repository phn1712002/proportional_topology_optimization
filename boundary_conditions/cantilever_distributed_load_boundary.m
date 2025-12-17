function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = cantilever_distributed_load_boundary(plot_flag)
%% CANTILEVER_DISTRIBUTED_LOAD_BOUNDARY Định nghĩa ĐK biên cho dầm console chịu tải phân bố.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = ...
%   cantilever_distributed_load_boundary(PLOT_FLAG) trả về các điều kiện biên
%   cho bài toán tối ưu hóa cấu trúc dầm console.
%
% Inputs:
%   plot_flag - (Tùy chọn) Nếu true, hiển thị trực quan hóa các điều kiện biên.
%               Mặc định là true.
%
% Outputs:
%   fixed_dofs    - Các bậc tự do (DOFs) bị cố định (chuyển vị bằng 0).
%   load_dofs     - Các bậc tự do nơi có tải trọng tác dụng.
%   load_vals     - Độ lớn của các tải trọng tương ứng.
%   nelx          - Số phần tử theo phương x.
%   nely          - Số phần tử theo phương y.
%   designer_mask - Ma trận logic chỉ định miền thiết kế hoạt động.
%                   Kích thước: (nely x nelx).
%
% Description:
%   - Geometry: Miền chữ nhật kích thước 120x60 phần tử.
%   - Fixed boundary (Ngàm): Toàn bộ cạnh trái bị ngàm cứng (vùng màu đỏ).
%   - Load (Tải trọng): Tải trọng phân bố đều trên một vùng ở giữa cạnh phải,
%     hướng xuống với tổng độ lớn là 10 (vùng màu xanh).

% --- XỬ LÝ INPUT ---
% Đặt giá trị mặc định cho plot_flag nếu không được cung cấp
if nargin < 1
    plot_flag = true;
end

% --- CẤU HÌNH BÀI TOÁN ---
NELX = 120;
NELY = 60;
TOTAL_LOAD = -10; % Tổng tải trọng, giá trị âm vì hướng xuống

% Gán các biến output
nelx = NELX;
nely = NELY;

% --- ĐỊNH NGHĨA MIỀN THIẾT KẾ (DESIGNER_MASK) ---
% Toàn bộ miền là vùng thiết kế (màu đen)
designer_mask = true(nely, nelx);

% --- ĐỊNH NGHĨA CÁC BẬC TỰ DO CỐ ĐỊNH (FIXED DOFs) ---
% Vùng màu đỏ: toàn bộ cạnh trái bị ngàm cứng.
% Các node ở cột 1 (từ node 1 đến node nely+1) bị cố định cả 2 phương x và y.
% Tổng số bậc tự do ở cạnh trái là 2 * (nely + 1).
fixed_dofs = 1:2*(nely+1);

% --- ĐỊNH NGHĨA TẢI TRỌNG (LOAD APPLICATION) ---
% Vùng màu xanh: tải phân bố trên một vùng ở giữa cạnh phải.
% Ước tính chiều cao vùng tải chiếm khoảng 1/6 chiều cao (10 phần tử).
LOAD_HEIGHT_ELEMENTS = 10;
num_load_nodes = LOAD_HEIGHT_ELEMENTS + 1;

% Xác định các node chịu tải ở giữa cạnh phải
right_col_index = nelx + 1;
center_row_index = round((nely + 1) / 2);
start_row = center_row_index - floor(LOAD_HEIGHT_ELEMENTS / 2);
end_row = start_row + LOAD_HEIGHT_ELEMENTS;
load_rows = start_row:end_row;

% Quy ước đánh số node theo cột: node_id = (col - 1) * (nely + 1) + row
load_node_ids = (right_col_index - 1) * (nely + 1) + load_rows;

% Tải trọng tác dụng theo phương y (DOF thứ 2 của mỗi node)
load_dofs = 2 * load_node_ids;

% Phân bố đều tổng tải trọng cho các node
load_per_node = TOTAL_LOAD / num_load_nodes;
load_vals = load_per_node * ones(1, num_load_nodes);

% --- HIỂN THỊ THÔNG TIN & TRỰC QUAN HÓA ---
fprintf('--- Cantilever Beam with Distributed Load Configuration ---\n');
fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Fixed DOFs: %d (Toàn bộ cạnh trái)\n', length(fixed_dofs));
fprintf('Load: Phân bố trên %d nodes ở giữa cạnh phải\n', num_load_nodes);
fprintf('Total load magnitude: %.2f (hướng xuống)\n', abs(sum(load_vals)));

% Trực quan hóa điều kiện biên nếu được yêu cầu
if plot_flag
    visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, ...
        'Cantilever with Distributed Load (120x60)', designer_mask);
end

end