# Quy Tắc Chung Cho Dự Án Proportional Topology Optimization

## 1. Tổng Quan Dự Án

Dự án này triển khai các thuật toán **Proportional Topology Optimization (PTO)** cho bài toán tối ưu hóa cấu trúc trong cơ học vật rắn. Hai biến thể chính:

- **PTOc (Proportional Topology Optimization for compliance)**: Tối thiểu hóa độ tuân thủ (compliance) với ràng buộc thể tích cố định.
- **PTOs (Proportional Topology Optimization for stress constraints)**: Tối thiểu hóa thể tích với ràng buộc ứng suất không vượt quá giới hạn cho phép.

**Đặc điểm nổi bật:**
- Không dựa trên đạo hàm (non-sensitivity method)
- Đơn giản, dễ lập trình, ổn định
- Phù hợp cho các mô hình tầm trung

## 2. Cấu Trúc Thư Mục

```
.
├── add_lib.m                    # Thêm tất cả thư mục con vào MATLAB path
├── simulate_*.m                 # Các script chạy mô phỏng cho từng bài toán
├── boundary_conditions/         # Điều kiện biên cho các bài toán mẫu
│   ├── cantilever_beam_boundary.m
│   ├── l_bracket_boundary.m
│   ├── mbb_beam_boundary.m
│   └── visualize_boundary_conditions.m
├── core/                        # Core algorithms và utilities
│   ├── FEA_analysis.m           # Phân tích phần tử hữu hạn
│   ├── compute_compliance.m     # Tính độ tuân thủ
│   ├── compute_stress.m         # Tính ứng suất Von Mises
│   ├── density_filter.m         # Bộ lọc mật độ
│   ├── material_distribution_PTOc.m  # Phân phối vật liệu cho PTOc
│   ├── material_distribution_PTOs.m  # Phân phối vật liệu cho PTOs
│   ├── run_ptoc_iteration.m     # Vòng lặp tối ưu hóa PTOc
│   ├── run_ptos_iteration.m     # Vòng lặp tối ưu hóa PTOs
│   ├── update_density.m         # Cập nhật mật độ với move limit
│   └── check_convergence.m      # Kiểm tra điều kiện hội tụ
├── docs/                        # Tài liệu thuật toán
│   ├── docs-ptoc.md
│   └── docs-ptos.md
└── rules/                       # Quy tắc coding và documentation
    ├── create-flowchart.md      # Quy tắc tạo flowchart
    ├── matlab-coding.md         # Quy tắc lập trình MATLAB
    └── general_rules.md         (file này)
```

## 3. Các Thuật Toán Chính

### 3.1. PTOc (Compliance Minimization)

**Mục tiêu:** Tối thiểu hóa độ tuân thủ `C = U' * K * U` với ràng buộc thể tích cố định.

**Luồng xử lý:**
1. Khởi tạo mật độ đều theo `volume_fraction`
2. Vòng lặp chính:
   - Phân tích FEA để tính chuyển vị `U` và ma trận độ cứng `K`
   - Tính độ tuân thủ phần tử
   - Phân phối vật liệu tỷ lệ với `C^q`
   - Lọc mật độ với bán kính `r_min`
   - Cập nhật mật độ với hệ số lịch sử `alpha`
   - Kiểm tra hội tụ dựa trên thay đổi mật độ

### 3.2. PTOs (Stress-Constrained Optimization)

**Mục tiêu:** Tối thiểu hóa thể tích với ràng buộc `σ_vm ≤ σ_allow`.

**Luồng xử lý:**
1. Khởi tạo mật độ và lượng vật liệu mục tiêu `TM`
2. Vòng lặp chính:
   - Phân tích FEA và tính ứng suất Von Mises
   - Điều chỉnh `TM` dựa trên so sánh `σ_max` với `σ_allow`
   - Phân phối vật liệu tỷ lệ với `σ^q`
   - Lọc mật độ và cập nhật tương tự PTOc
   - Kiểm tra hội tụ dựa trên ứng suất và thay đổi mật độ

## 4. Cách Chạy Code

### 4.1. Thiết Lập Môi Trường

```matlab
% Thêm tất cả thư mục vào path
add_lib(pwd);
```

### 4.2. Chạy Bài Toán Mẫu

Có sẵn 6 script mô phỏng:
- `simulate_cantilever_beam_PTOc.m` - Dầm console với PTOc
- `simulate_cantilever_beam_PTOs.m` - Dầm console với PTOs
- `simulate_mbb_beam_PTOc.m` - Dầm MBB với PTOc
- `simulate_mbb_beam_PTOs.m` - Dầm MBB với PTOs
- `simulate_Lbracket_PTOc.m` - Khung chữ L với PTOc
- `simulate_Lbracket_PTOs.m` - Khung chữ L với PTOs

**Ví dụ:**
```matlab
% Chạy dầm console với PTOc
simulate_cantilever_beam_PTOc;
```

### 4.3. Tham Số Điều Chỉnh

Các tham số quan trọng cần điều chỉnh cho từng bài toán:

| Tham số | PTOc | PTOs | Mô tả |
|---------|------|------|-------|
| `q` | 1.0-2.0 | 1.0-2.0 | Số mũ tỷ lệ phân phối |
| `r_min` | 1.25-2.0 | 1.25-2.0 | Bán kính bộ lọc |
| `alpha` | 0.3-0.5 | 0.3-0.5 | Hệ số lịch sử (move limit) |
| `volume_fraction` | 0.3-0.5 | - | Phân số thể tích (PTOc) |
| `sigma_allow` | - | 0.8-1.2 | Giới hạn ứng suất (PTOs) |
| `tau` | - | 0.05-0.1 | Dải dung sai ứng suất |

## 5. Quy Ước Coding

**Tham khảo file `matlab-coding.md`** cho quy tắc chi tiết về:
- Đặt tên (PascalCase, snake_case, UPPER_SNAKE_CASE)
- Comment và documentation
- Cấu trúc hàm
- Formatting (indentation 4 spaces, line length ≤ 100)

**Nguyên tắc bổ sung cho dự án này:**
1. **Modularity**: Mỗi hàm thực hiện một nhiệm vụ cụ thể
2. **Reusability**: Các hàm trong `core/` có thể tái sử dụng cho bài toán mới
3. **Documentation**: Mọi hàm đều có docstring mô tả inputs/outputs
4. **Consistency**: Sử dụng đơn vị nhất quán (E0 = 1.0, kích thước phần tử = 1)

## 6. Các File Quan Trọng Và Chức Năng

### 6.1. Core Functions

| File | Chức năng | Inputs chính | Outputs |
|------|-----------|--------------|---------|
| `FEA_analysis.m` | Phân tích FEA 2D plane stress | `nelx, nely, rho, p, E0, nu` | `U, K_global` |
| `compute_compliance.m` | Tính độ tuân thủ phần tử | `U, K_global` | `C` (nely×nelx) |
| `compute_stress.m` | Tính ứng suất Von Mises | `U, rho, p, E0, nu` | `sigma_vm` |
| `density_filter.m` | Lọc mật độ với kernel hình nón | `rho, r_min` | `rho_filtered` |
| `material_distribution_PTOc.m` | Phân phối vật liệu theo độ tuân thủ | `C, TM, q` | `rho_opt` |
| `material_distribution_PTOs.m` | Phân phối vật liệu theo ứng suất | `sigma, TM, q` | `rho_opt` |

### 6.2. Boundary Conditions

| File | Bài toán | Mô tả |
|------|----------|-------|
| `cantilever_beam_boundary.m` | Dầm console | Cố định cạnh trái, tải điểm góc phải |
| `mbb_beam_boundary.m` | Dầm MBB | Đối xứng, tải điểm giữa |
| `l_bracket_boundary.m` | Khung chữ L | Cố định trên, tải góc dưới phải |

## 7. Mở Rộng Và Thêm Bài Toán Mới

### 7.1. Thêm Bài Toán Geometry Mới

1. Tạo file boundary condition mới trong `boundary_conditions/`:
   ```matlab
   function [fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(plot_flag)
   % NEW_PROBLEM_BOUNDARY Boundary conditions for new problem
   %
   % Returns:
   %   fixed_dofs - Degrees of freedom with fixed displacement
   %   load_dofs  - DOFs where loads are applied
   %   load_vals  - Corresponding load values
   %   nelx, nely - Mesh dimensions
   ```

2. Tạo script mô phỏng mới (theo mẫu `simulate_*.m`):
   ```matlab
   % NEW_PROBLEM_PTOC Run PTOc on new problem
   clear; close all; clc;
   add_lib(pwd);
   
   % Thiết lập tham số
   % ... (tương tự các script có sẵn)
   
   % Gọi hàm boundary
   [fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(false);
   
   % Chạy optimization
   [rho_opt, history] = run_ptoc_iteration(...);
   ```

### 7.2. Tùy Chỉnh Thuật Toán

1. **Điều chỉnh phân phối vật liệu**: Sửa `material_distribution_PTOc.m` hoặc `material_distribution_PTOs.m`
2. **Thay đổi bộ lọc**: Sửa `density_filter.m`
3. **Thêm tiêu chí hội tụ**: Sửa `check_convergence.m`
4. **Thay đổi FEA**: Sửa `FEA_analysis.m` (cẩn thận với hiệu năng)

## 8. Debugging và Troubleshooting

### 8.1. Vấn Đề Thường Gặp

1. **Singular matrix trong FEA**:
   - Kiểm tra `E_min = 1e-9 * E0`
   - Đảm bảo `rho_min > 0`

2. **Không hội tụ**:
   - Giảm `alpha` (vd: 0.3)
   - Tăng `max_iter`
   - Kiểm tra tham số `q`, `r_min`

3. **Kết quả không mịn**:
   - Tăng `r_min` (vd: 2.0)
   - Kiểm tra bộ lọc trong `density_filter.m`

### 8.2. Công Cụ Hỗ Trợ

- `visualize_boundary_conditions.m`: Hiển thị điều kiện biên
- Lưu history trong `run_ptoc_iteration.m` và `run_ptos_iteration.m` để phân tích
- Các figure tự động sinh trong quá trình chạy

## 9. Tài Liệu Tham Khảo

1. **Tài liệu thuật toán**: `docs/docs-ptoc.md` và `docs/docs-ptos.md`
2. **Quy tắc flowchart**: `rules/create-flowchart.md`
3. **Quy tắc MATLAB**: `rules/matlab-coding.md`
4. **Code examples**: Các script `simulate_*.m`

## 10. Liên Hệ và Đóng Góp

- Source code: GitLab repository
- Cấu trúc dự án tuân theo modular design, dễ mở rộng
- Đề xuất cải tiến: Tạo issue hoặc merge request

---

*Lưu ý: Khi thêm tính năng mới, đảm bảo tuân thủ quy tắc trong `matlab-coding.md` và cập nhật tài liệu tương ứng.*
