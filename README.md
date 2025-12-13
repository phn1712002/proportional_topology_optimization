# Proportional Topology Optimization (PTO)
<p align="center">
  VN <a href="README.md">Tiếng Việt</a> |
  US <a href="README.en.md">English</a> |
</p>

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Tổng quan

**Proportional Topology Optimization (PTO)** là một phương pháp tối ưu hóa cấu trúc không dựa trên đạo hàm (non-sensitivity method) cho các bài toán tối ưu hóa topo trong cơ học vật rắn. Phương pháp này cung cấp một cách tiếp cận đơn giản, ổn định và dễ lập trình so với các phương pháp dựa trên độ nhạy truyền thống.

Dự án này triển khai hai biến thể chính của thuật toán PTO:

- **PTOc (Proportional Topology Optimization for compliance)**: Tối thiểu hóa độ tuân thủ (compliance) với ràng buộc thể tích cố định.
- **PTOs (Proportional Topology Optimization for stress constraints)**: Tối thiểu hóa thể tích với ràng buộc ứng suất không vượt quá giới hạn cho phép.

### 🎯 Tính năng nổi bật

- **Không cần tính đạo hàm**: Loại bỏ yêu cầu tính toán độ nhạy phức tạp, đơn giản hóa việc lập trình
- **Thuật toán ổn định**: Phương pháp tỷ lệ đảm bảo tính ổn định số học và hội tụ đáng tin cậy
- **Dễ triển khai**: Cấu trúc mã nguồn rõ ràng, module hóa cao, dễ tùy chỉnh và mở rộng
- **Hiệu quả cho mô hình tầm trung**: Tối ưu hóa hiệu suất cho các bài toán có kích thước vừa phải
- **Hỗ trợ đa dạng bài toán**: Cung cấp sẵn các bài toán mẫu phổ biến trong cơ học kết cấu

### ⚠️ Lưu ý quan trọng

**Đây là phiên bản nghiên cứu của thuật toán PTO.** Kết quả có thể thay đổi tùy thuộc vào tham số và bài toán cụ thể. Luôn kiểm tra và xác nhận kết quả trước khi áp dụng vào các ứng dụng thực tế.

## 🚀 Bắt đầu nhanh

### Yêu cầu hệ thống

- **MATLAB**: Phiên bản R2021b trở lên
- **Toolbox**: Không yêu cầu toolbox đặc biệt
- **Phần cứng**: Đủ bộ nhớ RAM cho ma trận độ cứng (khoảng 2-4GB cho bài toán 100×50 phần tử)

### Cài đặt

1. Clone repository:
```bash
git clone https://gitlab.com/phn1712002/proportional_topology_optimization.git
cd proportional_topology_optimization/code_ws
```

2. Thêm tất cả thư mục vào MATLAB path:
```matlab
add_lib(pwd);
```

### Chạy ví dụ mẫu

Dự án cung cấp 6 script mô phỏng cho các bài toán cơ bản trong cơ học kết cấu:

```matlab
% 1. Dầm console (Cantilever beam)
simulate_cantilever_beam_PTOc;    % Với PTOc
simulate_cantilever_beam_PTOs;    % Với PTOs

% 2. Dầm MBB (Michell-type structure)
simulate_mbb_beam_PTOc;           % Với PTOc
simulate_mbb_beam_PTOs;           % Với PTOs

% 3. Khung chữ L (L-bracket)
simulate_Lbracket_PTOc;           % Với PTOc
simulate_Lbracket_PTOs;           % Với PTOs
```

Mỗi script sẽ tự động chạy tối ưu hóa và hiển thị kết quả dưới dạng hình ảnh động, biểu đồ hội tụ, và phân bố mật độ cuối cùng.

## 📁 Cấu trúc dự án

```
.
├── README.md                          # Tài liệu hướng dẫn (bạn đang đọc)
├── LICENSE                           # Giấy phép MIT
├── add_lib.m                         # Thêm tất cả thư mục con vào MATLAB path
├── simulate_*.m                      # Script mô phỏng cho từng bài toán (6 files)
│
├── boundary_conditions/              # Thư viện điều kiện biên
│   ├── cantilever_beam_boundary.m    # Điều kiện biên cho dầm console
│   ├── l_bracket_boundary.m          # Điều kiện biên cho khung chữ L
│   ├── mbb_beam_boundary.m           # Điều kiện biên cho dầm MBB
│   └── visualize_boundary_conditions.m # Công cụ trực quan hóa điều kiện biên
│
├── core/                             # Thư viện thuật toán chính
│   ├── FEA_analysis.m                # Phân tích phần tử hữu hạn (FEA)
│   ├── compute_compliance.m          # Tính độ tuân thủ (compliance)
│   ├── compute_stress.m              # Tính ứng suất Von Mises
│   ├── density_filter.m              # Bộ lọc mật độ với kernel hình nón
│   ├── material_distribution_PTOc.m  # Phân phối vật liệu cho PTOc
│   ├── material_distribution_PTOs.m  # Phân phối vật liệu cho PTOs
│   ├── run_ptoc_iteration.m          # Vòng lặp tối ưu hóa PTOc
│   ├── run_ptos_iteration.m          # Vòng lặp tối ưu hóa PTOs
│   ├── update_density.m              # Cập nhật mật độ với move limit
│   └── check_convergence.m           # Kiểm tra điều kiện hội tụ
│
├── docs/                             # Tài liệu thuật toán chi tiết
│   ├── docs-ptoc.md                  # Tài liệu đầy đủ về thuật toán PTOc
│   └── docs-ptos.md                  # Tài liệu đầy đủ về thuật toán PTOs
│
└── rules/                            # Quy tắc phát triển dự án
    ├── create-flowchart.md           # Quy tắc tạo flowchart cho thuật toán
    ├── matlab-coding.md              # Quy tắc lập trình MATLAB
    └── general_rules.md              # Quy tắc chung cho dự án
```

## 🔧 Thuật toán chi tiết

### PTOc – Tối thiểu hóa độ tuân thủ

**Mục tiêu**
Tối thiểu hóa **độ tuân thủ**:

```
C = Uᵀ · K · U
```

trong đó:

* `U` : vector chuyển vị
* `K` : ma trận độ cứng toàn cục

với **ràng buộc thể tích cố định**.

---

**Luồng xử lý**

1. **Khởi tạo**
   Phân bố mật độ vật liệu đều nhau theo:

```
density = volume_fraction
```

2. **Vòng lặp chính** (lặp cho đến khi hội tụ)

   * Phân tích FEA để tính:

     ```
     U  (chuyển vị)
     K  (ma trận độ cứng)
     ```

   * Tính **độ tuân thủ phần tử**:

     ```
     Ce = Ueᵀ · Ke · Ue
     ```

   * **Phân phối vật liệu** theo lũy thừa độ tuân thủ:

     ```
     density ∝ Ce^q
     ```

     (`q` là số mũ điều chỉnh độ tập trung vật liệu)

   * **Lọc mật độ** với bán kính:

     ```
     r_min
     ```

   * **Cập nhật mật độ** với hệ số lịch sử (move limit):

     ```
     density_new = alpha · density_old + (1 - alpha) · density_update
     ```

   * **Kiểm tra hội tụ** dựa trên:

     ```
     max(|density_new - density_old|)
     ```

3. **Kết thúc**
   Trả về:

   * Phân bố mật độ tối ưu
   * Lịch sử hội tụ

---

### PTOs – Tối ưu hóa với ràng buộc ứng suất

**Mục tiêu**
Tối thiểu hóa **thể tích vật liệu**, với ràng buộc:

```
sigma_vm ≤ sigma_allow
```

trong đó:

* `sigma_vm` : ứng suất Von Mises
* `sigma_allow` : ứng suất cho phép

---

**Luồng xử lý**

1. **Khởi tạo**

   * Phân bố mật độ ban đầu
   * Xác định lượng vật liệu mục tiêu:

     ```
     TM
     ```

2. **Vòng lặp chính** (lặp cho đến khi hội tụ)

   * Phân tích FEA và tính:

     ```
     sigma_vm
     ```

   * So sánh ứng suất lớn nhất:

     ```
     sigma_max vs sigma_allow
     ```

   * **Điều chỉnh lượng vật liệu mục tiêu**:

     ```
     nếu sigma_max > sigma_allow → tăng TM
     nếu sigma_max < sigma_allow → giảm TM
     ```

   * **Phân phối vật liệu theo ứng suất**:

     ```
     density ∝ sigma_vm^q
     ```

   * **Lọc mật độ và cập nhật** tương tự PTOc:

     ```
     density_new = alpha · density_old + (1 - alpha) · density_update
     ```

   * **Kiểm tra hội tụ** dựa trên:

     ```
     |sigma_max - sigma_allow|
     và
     max(|density_new - density_old|)
     ```

3. **Kết thúc**
   Trả về:

   * Phân bố mật độ tối ưu
   * Đảm bảo ứng suất không vượt giới hạn


## 📊 Tham số điều chỉnh

Bảng dưới đây liệt kê các tham số quan trọng cần điều chỉnh cho từng thuật toán:

| Tham số | PTOc | PTOs | Mô tả | Giá trị đề xuất |
|---------|------|------|-------|----------------|
| `q` | ✓ | ✓ | Số mũ tỷ lệ phân phối vật liệu | 1.0 - 2.0 |
| `r_min` | ✓ | ✓ | Bán kính bộ lọc mật độ | 1.25 - 2.0 |
| `alpha` | ✓ | ✓ | Hệ số lịch sử (giới hạn thay đổi mật độ) | 0.3 - 0.5 |
| `volume_fraction` | ✓ | - | Phân số thể tích (PTOc) | 0.3 - 0.5 |
| `sigma_allow` | - | ✓ | Giới hạn ứng suất cho phép (PTOs) | 0.8 - 1.2 |
| `tau` | - | ✓ | Dải dung sai ứng suất (PTOs) | 0.05 - 0.1 |
| `max_iter` | ✓ | ✓ | Số vòng lặp tối đa | 200 - 500 |
| `conv_tol` | ✓ | ✓ | Ngưỡng hội tụ cho thay đổi mật độ | 1e-4 |
| `p` | ✓ | ✓ | Số mũ penalization (SIMP) | 3.0 |

**Lưu ý**: Các giá trị đề xuất có thể thay đổi tùy thuộc vào bài toán cụ thể. Nên thử nghiệm với các giá trị khác nhau để đạt kết quả tối ưu.

## 🎮 Hướng dẫn sử dụng nâng cao

### Tạo bài toán tối ưu hóa mới

1. **Tạo file điều kiện biên mới** trong thư mục `boundary_conditions/`:

```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(plot_flag)
% NEW_PROBLEM_BOUNDARY Điều kiện biên cho bài toán mới
%
% Input:
%   plot_flag - Boolean: true để hiển thị hình ảnh điều kiện biên
%
% Output:
%   fixed_dofs - Các bậc tự do bị cố định (fixed displacement)
%   load_dofs  - Các bậc tự do chịu tải trọng
%   load_vals  - Giá trị tải trọng tương ứng
%   nelx, nely - Kích thước lưới phần tử
```

2. **Tạo script mô phỏng mới** theo mẫu `simulate_*.m`:

```matlab
% NEW_PROBLEM_PTOC Chạy PTOc cho bài toán mới
clear; close all; clc;
add_lib(pwd);

% Thiết lập tham số
nelx = 60; nely = 30;
volume_fraction = 0.4;
q = 2.0; r_min = 1.25; alpha = 0.5;
max_iter = 300; conv_tol = 1e-4;

% Gọi hàm điều kiện biên
[fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(true);

% Chạy tối ưu hóa PTOc
[rho_opt, history] = run_ptoc_iteration(nelx, nely, volume_fraction, ...
    fixed_dofs, load_dofs, load_vals, q, r_min, alpha, max_iter, conv_tol);

% Hiển thị kết quả
figure;
imagesc(1-rho_opt); colormap(gray); axis equal; axis off;
title('Phân bố mật độ tối ưu - Bài toán mới');
```

### Tùy chỉnh thuật toán

- **Điều chỉnh phân phối vật liệu**: Sửa đổi `material_distribution_PTOc.m` hoặc `material_distribution_PTOs.m`
- **Thay đổi bộ lọc mật độ**: Sửa đổi `density_filter.m` (kernel hình nón, kernel Gaussian, v.v.)
- **Thêm tiêu chí hội tụ**: Mở rộng `check_convergence.m` để bao gồm các tiêu chí mới
- **Tối ưu hóa FEA**: Sửa đổi `FEA_analysis.m` để cải thiện hiệu suất (ví dụ: sử dụng sparse matrix)
- **Thêm ràng buộc mới**: Tích hợp các ràng buộc bổ sung (nhiệt độ, tần số, v.v.)
- **Cải thiện visualization**: Thêm các công cụ trực quan hóa kết quả nâng cao

## 🔍 Gỡ lỗi và Khắc phục sự cố

### Vấn đề thường gặp

1. **Ma trận suy biến (singular matrix) trong phân tích FEA**:
   - Kiểm tra giá trị `E_min = 1e-9 * E0` trong `FEA_analysis.m`
   - Đảm bảo `rho_min > 0` để tránh phần tử có độ cứng bằng 0
   - Xác minh điều kiện biên đã được áp dụng đúng cách

2. **Thuật toán không hội tụ**:
   - Giảm hệ số `alpha` (ví dụ: từ 0.5 xuống 0.3)
   - Tăng `max_iter` để cho phép nhiều vòng lặp hơn
   - Kiểm tra và điều chỉnh tham số `q`, `r_min`
   - Xác minh ngưỡng hội tụ `conv_tol` phù hợp

3. **Kết quả không mịn hoặc có hiện tượng checkerboard**:
   - Tăng bán kính bộ lọc `r_min` (ví dụ: từ 1.25 lên 2.0)
   - Kiểm tra hiệu quả của bộ lọc trong `density_filter.m`
   - Xem xét sử dụng bộ lọc sensitivity thay vì chỉ lọc mật độ

4. **Ứng suất vượt quá giới hạn trong PTOs**:
   - Điều chỉnh `sigma_allow` và `tau` phù hợp
   - Kiểm tra phương pháp điều chỉnh `TM` trong `run_ptos_iteration.m`
   - Xác minh tính chính xác của phép tính ứng suất Von Mises

### Công cụ hỗ trợ gỡ lỗi

- **`visualize_boundary_conditions.m`**: Hiển thị trực quan điều kiện biên để xác minh
- **Lịch sử hội tụ**: Các biến `history` trong `run_ptoc_iteration.m` và `run_ptos_iteration.m` cung cấp dữ liệu để phân tích quá trình hội tụ
- **Figure tự động**: Các hình ảnh được tạo tự động trong quá trình chạy giúp theo dõi tiến độ
- **Kiểm tra từng bước**: Chạy từng hàm riêng lẻ để xác minh đầu ra

## 📚 Bài báo nghiên cứu gốc

Phương pháp Proportional Topology Optimization được giới thiệu trong bài báo:

**Biyikli, E., & To, A. C. (2015).** *Proportional Topology Optimization: A New Non-Sensitivity Method for Solving Stress Constrained and Minimum Compliance Problems and Its Implementation in MATLAB.* PLoS ONE, 10(12), e0145041.

- **Link**: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0145041
- **Tóm tắt**: Bài báo giới thiệu phương pháp PTO không dựa trên độ nhạy, cung cấp thuật toán đơn giản cho cả bài toán tối thiểu hóa độ tuân thủ và bài toán với ràng buộc ứng suất.

### Lời cảm ơn tác giả

Chúng tôi xin gửi lời cảm ơn chân thành đến các tác giả **Emre Biyikli** và **Albert C. To** vì đã phát triển và công bố phương pháp Proportional Topology Optimization.

## 📄 Giấy phép

Dự án này được phân phối dưới giấy phép **MIT**. Xem file `LICENSE` để biết đầy đủ chi tiết.

**Tóm tắt giấy phép MIT**:
- Được phép sử dụng, sao chép, sửa đổi, hợp nhất, xuất bản, phân phối, cấp phép lại và/hoặc bán các bản sao của phần mềm
- Phải bao gồm thông báo bản quyền và giấy phép trong tất cả các bản sao hoặc phần quan trọng của phần mềm
- PHẦN MỀM ĐƯỢC CUNG CẤP "NHƯ HIỆN CÓ", KHÔNG CÓ BẢO HÀNH

## 📞 Liên hệ
* **Tác giả**: Pham Hoang Nam
* **Email**: [phn1712002@gmail.com](mailto:phn1712002@gmail.com)
