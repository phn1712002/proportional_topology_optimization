# 📘 Hướng Dẫn Tạo Boundary Condition Mới Cho Proportional Topology Optimization

## 🎯 Mục Đích

Tài liệu này cung cấp quy tắc chung để AI hiểu cách mô tả và tạo một điều kiện biên (boundary condition) mới cho dự án Proportional Topology Optimization. Các boundary condition được sử dụng để định nghĩa bài toán tối ưu hóa cấu trúc 2D và 3D.

---

## 📁 Cấu Trúc File Boundary Condition

### 1. **Đặt Tên File**
- **Quy tắc**: `snake_case.m`
- **Ví dụ**: 
  - `cantilever_beam_boundary.m`
  - `l_bracket_boundary.m`
  - `mbb_beam_boundary.m`
  - `plate_3d_boundary.m`

### 2. **Cấu Trúc Hàm Cơ Bản**

#### **2D Problems (6 outputs):**
```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = function_name(plot_flag)
```

#### **3D Problems (7 outputs):**
```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz, designer_mask] = function_name(plot_flag)
```

---

## 📝 Phần Documentation (Docstring)

### **Template Chuẩn:**
```matlab
%% FUNCTION_NAME_IN_UPPERCASE Mô tả ngắn gọn về bài toán.
%   [FIXED_DOFS, LOAD_DOFS, LOAD_VALS, NELX, NELY, DESIGNER_MASK] = FUNCTION_NAME(PLOT_FLAG)
%   returns boundary conditions for [tên bài toán] topology optimization problem.
%   [Mô tả chi tiết về geometry, supports, và loads].
%
% Inputs:
%   plot_flag - (Optional) If true, displays a visualization of the boundary conditions.
%               Default is true.
%
% Outputs:
%   fixed_dofs    - Degrees of freedom (DOFs) that are fixed (zero displacement).
%   load_dofs     - Degrees of freedom where loads are applied.
%   load_vals     - Magnitudes of the corresponding loads.
%   nelx          - Number of elements in the x-direction.
%   nely          - Number of elements in the y-direction.
%   nelz          - Number of elements in the z-direction (chỉ cho 3D).
%   designer_mask - Logical matrix indicating the active design domain.
%                   Kích thước: (nely x nelx) cho 2D, (nely x nelx x nelz) cho 3D.
%
% Description:
%   - Geometry: [Mô tả hình học]
%   - Fixed boundary: [Mô tả điều kiện biên cố định]
%   - Load: [Mô tả tải trọng]
```

---

## 🔧 Cấu Trúc Code Bên Trong

### **1. Xử lý Input (plot_flag)**
```matlab
% Set default value for plot_flag if not provided
if nargin < 1
    plot_flag = true;
end
```

### **2. Cấu Hình Bài Toán (PROBLEM CONFIGURATION)**
```matlab
% --- PROBLEM CONFIGURATION ---
NELX = 120;                 % Number of elements in x-direction
NELY = 60;                  % Number of elements in y-direction
LOAD_VAL = -1;              % Normalized load magnitude (âm = downward)
CUTOUT_X = 60;              % Width of cutout (nếu có)
CUTOUT_Y = 60;              % Height of cutout (nếu có)

% Assign output variables
nelx = NELX;
nely = NELY;
```

### **3. Định Nghĩa Design Domain (DESIGNER_MASK)**
```matlab
% --- DEFINE DESIGN DOMAIN ---
% Trường hợp 1: Toàn bộ domain active
designer_mask = true(nely, nelx);

% Trường hợp 2: Có void region (ví dụ L-bracket)
designer_mask = true(nely, nelx);
void_rows = (nely - CUTOUT_Y + 1):nely;
void_cols = (nelx - CUTOUT_X + 1):nelx;
designer_mask(void_rows, void_cols) = false;

% Trường hợp 3D:
% designer_mask = true(nely, nelx, nelz);
```

### **4. Quy Ước Đánh Số Node và DOF**

#### **2D (Column-wise numbering):**
```matlab
% The mesh contains (nelx+1) x (nely+1) nodes.
% Nodes are numbered COLUMN-WISE, starting from the bottom-left corner.
% Node ID at (column, row): node_id = (col - 1) * (nely + 1) + row
% Degrees of freedom for node 'n': 2*n-1 (x-direction), 2*n (y-direction)
```

#### **3D (z varying fastest):**
```matlab
% The mesh contains (nelx+1) x (nely+1) x (nelz+1) nodes.
% Nodes are numbered with z varying fastest, then y, then x.
% Node ID formula: node_id = (k-1)*(ny+1)*(nx+1) + (j-1)*(ny+1) + i
% where i = y-index (1 to ny+1), j = x-index (1 to nx+1), k = z-index (1 to nz+1)
% Degrees of freedom for node 'n': 3*n-2 (x), 3*n-1 (y), 3*n (z)
```

### **5. Định Nghĩa Fixed DOFs**
```matlab
% --- FIXED DOFs ---
% Ví dụ 1: Left edge fully fixed (2D)
fixed_dofs = 1:2*(nely+1);

% Ví dụ 2: Left edge x-direction only (symmetry)
symmetry_dofs = 1:2:2*(nely+1);

% Ví dụ 3: Multiple discrete supports
fixed_dofs = [];
support_positions = [0.2, 0.5, 0.8];  % Fractional positions
for i = 1:length(support_positions)
    support_col = round(support_positions(i) * nelx) + 1;
    support_node_id = (support_col - 1) * (nely + 1) + 1; % Bottom row
    fixed_dofs = [fixed_dofs, 2*support_node_id-1, 2*support_node_id];
end
fixed_dofs = sort(unique(fixed_dofs));

% Ví dụ 4: 3D fixed face
[I, K] = meshgrid(1:num_nodes_y, 1:num_nodes_z);
left_face_nodes = (K(:)-1)*(num_nodes_y*num_nodes_x) + (1-1)*num_nodes_y + I(:);
dof_x = 3 * left_face_nodes - 2;
dof_y = 3 * left_face_nodes - 1;
dof_z = 3 * left_face_nodes;
fixed_dofs = sort([dof_x; dof_y; dof_z]);
```

### **6. Định Nghĩa Load Application**
```matlab
% --- LOAD APPLICATION ---
% Ví dụ 1: Point load at specific node
load_node_col = floor(nelx/2) + 1;
load_node_row = nely + 1;
load_node_id = (load_node_col - 1) * (nely + 1) + load_node_row;
load_dofs = 2 * load_node_id;  % y-direction
load_vals = LOAD_VAL;

% Ví dụ 2: Distributed load over multiple nodes
num_load_nodes = 3;
start_row = (nely / 2 + 1) - (num_load_nodes / 2);
end_row = (nely / 2) + (num_load_nodes / 2);
load_rows = start_row:end_row;
load_node_ids = (right_col_index - 1) * (nely + 1) + load_rows;
load_dofs = 2 * load_node_ids;
load_vals = LOAD_VAL * ones(1, num_load_nodes);

% Ví dụ 3: Distributed load on top edge (uniform)
top_edge_nodes = (0:nelx) * (nely + 1) + (nely + 1);
load_per_node = TOTAL_LOAD / length(top_edge_nodes);
load_dofs = 2 * top_edge_nodes;
load_vals = repmat(load_per_node, 1, length(top_edge_nodes));
```

### **7. Hiển Thị Thông Tin (DISPLAY & VISUALIZATION)**
```matlab
% --- DISPLAY & VISUALIZATION ---
fprintf('--- [Tên Bài Toán] Configuration ---\n');
fprintf('Mesh: %d x %d elements\n', nelx, nely);
fprintf('Fixed DOFs count: %d\n', length(fixed_dofs));
fprintf('Total load magnitude: %.2f\n', sum(load_vals));
fprintf('[Thông tin bổ sung nếu cần]\n');

% Visualize boundary conditions if requested
if plot_flag
    % 2D: visualize_boundary_conditions
    visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, '[Tên Bài Toán]', designer_mask);
    
    % 3D: visualize_boundary_conditions_3d
    % visualize_boundary_conditions_3d(nelx, nely, nelz, fixed_dofs, load_dofs, designer_mask);
end
```

---

## 🎨 Các Loại Boundary Condition Phổ Biến

### **1. Cantilever Beam**
- **Fixed**: Left edge fully fixed
- **Load**: Vertical load at right edge (distributed or point)
- **Mask**: Full domain

### **2. MBB Beam (Half Symmetry)**
- **Fixed**: Left edge x-direction only (symmetry), bottom-right corner y-direction
- **Load**: Vertical load at top-left edge
- **Mask**: Full domain

### **3. L-Bracket**
- **Fixed**: Top edge of vertical arm
- **Load**: Vertical load at outer corner of horizontal arm
- **Mask**: L-shaped domain with cutout

### **4. Simply Supported Beam**
- **Fixed**: Left edge fully fixed, right edge y-direction only
- **Load**: Point load at center of top edge
- **Mask**: Full domain

### **5. 3D Plate/Block**
- **Fixed**: One face fully fixed (all 3 DOFs)
- **Load**: Distributed load on opposite face
- **Mask**: Full 3D domain

### **6. Multiple Supports**
- **Fixed**: Multiple discrete supports along bottom edge
- **Load**: Multiple point loads along top edge
- **Mask**: Full domain

---

## 🔍 Kiểm Tra và Debug

### **Các Lỗi Thường Gặp:**
1. **DOFs out of range**: Đảm bảo DOF indices nằm trong phạm vi hợp lệ
   - 2D: max DOF = 2 * (nelx+1) * (nely+1)
   - 3D: max DOF = 3 * (nelx+1) * (nely+1) * (nelz+1)

2. **Load distribution**: Tổng load_vals phải bằng TOTAL_LOAD mong muốn

3. **Designer mask dimensions**: 
   - 2D: (nely x nelx)
   - 3D: (nely x nelx x nelz)

### **Debug Commands:**
```matlab
% Kiểm tra số lượng DOFs
total_nodes_2d = (nelx+1) * (nely+1);
total_dofs_2d = 2 * total_nodes_2d;

total_nodes_3d = (nelx+1) * (nely+1) * (nelz+1);
total_dofs_3d = 3 * total_nodes_3d;

% Kiểm tra load distribution
fprintf('Total load applied: %.4f (expected: %.4f)\n', sum(load_vals), TOTAL_LOAD);

% Kiểm tra designer mask
fprintf('Design domain: %d active elements out of %d total\n', ...
        sum(designer_mask(:)), numel(designer_mask));
```

---

## 📚 Ví Dụ Hoàn Chỉnh

### **2D Cantilever Beam:**
```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely, designer_mask] = new_cantilever_boundary(plot_flag)
%% NEW_CANTILEVER_BOUNDARY Define boundary conditions for a new cantilever problem.
%   [FIXED_DOFS, ..., DESIGNER_MASK] = NEW_CANTILEVER_BOUNDARY(PLOT_FLAG)
%   returns boundary conditions for a custom cantilever beam.
%
% Inputs:
%   plot_flag - (Optional) If true, displays visualization. Default is true.
%
% Outputs:
%   fixed_dofs    - DOFs that are fixed.
%   load_dofs     - DOFs where loads are applied.
%   load_vals     - Load magnitudes.
%   nelx          - Number of elements in x-direction (80).
%   nely          - Number of elements in y-direction (40).
%   designer_mask - Logical matrix (nely x nelx) for design domain.

    if nargin < 1
        plot_flag = true;
    end

    % Configuration
    NELX = 80;
    NELY = 40;
    LOAD_VAL = -1;
    LOAD_WIDTH = 5; % Load distributed over 5 elements
    
    nelx = NELX;
    nely = NELY;
    
    % Design domain (full)
    designer_mask = true(nely, nelx);
    
    % Fixed DOFs (left edge)
    fixed_dofs = 1:2*(nely+1);
    
    % Load application (distributed at right edge center)
    num_load_nodes = LOAD_WIDTH + 1;
    start_row = floor((nely+1)/2) - floor(LOAD_WIDTH/2);
    end_row = start_row + LOAD_WIDTH;
    load_rows = start_row:end_row;
    right_col = nelx + 1;
    load_node_ids = (right_col - 1) * (nely + 1) + load_rows;
    load_dofs = 2 * load_node_ids;
    load_vals = (LOAD_VAL / num_load_nodes) * ones(1, num_load_nodes);
    
    % Display
    fprintf('--- New Cantilever Configuration ---\n');
    fprintf('Mesh: %d x %d elements\n', nelx, nely);
    fprintf('Fixed DOFs: %d (left edge)\n', length(fixed_dofs));
    fprintf('Load: Distributed over %d nodes at right edge center\n', num_load_nodes);
    fprintf('Total load: %.2f\n', sum(load_vals));
    
    % Visualization
    if plot_flag
        visualize_boundary_conditions(nelx, nely, fixed_dofs, load_dofs, load_vals, 'New Cantilever', designer_mask);
    end
end
```

---

## 🚀 Best Practices

### **1. Tính Nhất Quán:**
- Sử dụng cùng quy ước đánh số node cho tất cả boundary conditions
- Đơn vị load nhất quán (thường normalized)
- Kích thước mesh hợp lý cho performance

### **2. Tính Tái Sử Dụng:**
- Đặt các tham số cấu hình thành biến constant
- Cho phép tùy chỉnh qua input parameters (nếu cần)
- Viết code rõ ràng, có comment giải thích

### **3. Tính Minh Bạch:**
- Hiển thị đầy đủ thông tin khi chạy
- Cung cấp visualization option
- Xử lý lỗi rõ ràng (ví dụ: load area vượt quá kích thước mesh)

### **4. Tính Tương Thích:**
- Đảm bảo output format tương thích với các hàm optimization (run_ptoc_iteration, run_ptos_iteration)
- Designer mask phải có kích thước chính xác
- DOF indices phải hợp lệ

---

## 📞 Hỗ Trợ và Liên Hệ

Khi tạo boundary condition mới:
1. **Kiểm tra**: Chạy thử với plot_flag = true để xem visualization
2. **Xác nhận**: Đảm bảo fixed DOFs và load DOFs hợp lệ
3. **Tích hợp**: Test với simulate script tương ứng

**Lưu ý quan trọng:**
- 2D problems: 2 DOFs per node (x, y)
- 3D problems: 3 DOFs per node (x, y, z)
