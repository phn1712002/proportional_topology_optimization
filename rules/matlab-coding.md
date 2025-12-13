# 📘 MATLAB Coding Standards – General Rules

## 📋 Overview

Tài liệu này định nghĩa quy chuẩn lập trình MATLAB chung, bao gồm: đặt tên, comment, cấu trúc hàm, tổ chức file, code style, và best practices.

---

## 🏷️ Naming Rules

### 1. Class Names
* **PascalCase**
* Ví dụ: `DataProcessor`, `SignalAnalyzer`, `UserProfile`

### 2. Function Names
* **snake_case**
* Ví dụ: `load_data`, `process_signal`, `save_results`

### 3. Variable Names
* **snake_case**
* Ví dụ: `user_id`, `config_path`, `max_iterations`

### 4. Constants
* **UPPER_SNAKE_CASE**
* Khai báo bằng `constant` property trong class hoặc file `constants.m`
* Ví dụ: `MAX_CONNECTIONS`, `DEFAULT_TIMEOUT`
---

## 💬 Commenting Rules

### 1. Function Help (Docstring)
* Sử dụng block comment `%%` và phần **H1 line** ngay sau khai báo hàm.

```matlab
function status = connect(url, timeout)
% CONNECT Establish a connection to a given URL
%   STATUS = CONNECT(URL, TIMEOUT) returns true if the connection succeeds,
%   false otherwise. Timeout defaults to 30 seconds.
%
% Inputs:
%   url     - Target URL (string)
%   timeout - Timeout in seconds (numeric, optional)
%
% Outputs:
%   status  - Boolean indicating success/failure
````

### 2. Inline Comments

* Viết ngắn gọn, rõ ràng sau `%`.

```matlab
for attempt = 1:MAX_RETRIES
    % Retry connection if request fails
end
```

### 3. TODO / FIXME

```matlab
% TODO: Add support for parallel processing
% FIXME: Handle empty input gracefully
```

---

## 📝 Function Writing Rules

1. **Function Signature**

```matlab
function out = function_name(param1, param2)
% FUNCTION_NAME One-line description
```

2. **Type Documentation**: MATLAB không có type hints bắt buộc → mô tả trong docstring.

3. **Function Length**: Không quá \~50 dòng. Chia nhỏ khi cần.

4. **Return Values**: Rõ ràng, thống nhất kiểu dữ liệu.

---

## 📁 File Organization Rules

### 1. Import Rules

* Dùng `import` khi cần, nhưng tránh lạm dụng.
* Import đặt ở đầu file sau comment.

```matlab
import matlab.io.*
import signal.*
```

### 2. File Naming

* **snake\_case**
* Mỗi file = 1 function chính hoặc 1 class.
* Ví dụ: `data_loader.m`, `user_service.m`

---

## 🔧 Code Style and Formatting

* **Indentation**: 4 spaces
* **Line Length**: ≤ 100 ký tự
* **Whitespace**:

  * Có 1 space quanh toán tử: `a + b`
  * Không có space trong ngoặc: `func(x, y)`

---

## 🚀 Best Practices

1. **Code Reusability**

   * Dùng function hoặc class thay vì script dài.

2. **Maintainability**

   * Tránh magic numbers → khai báo biến constant.
   * Tên biến/hàm rõ nghĩa.

3. **Extensibility**

   * Thiết kế module dễ mở rộng.
   * Cho phép truyền vào `varargin` khi cần thêm tham số.

4. **Documentation**

   * Đủ phần help cho function/class.
   * Thêm ví dụ usage nếu cần.

---

## 🔍 Code Review Checklist

* [ ] Đúng naming convention
* [ ] Có phần help (docstring)
* [ ] Không dùng magic numbers
* [ ] File ≤ 1 function/class chính
* [ ] Code dễ đọc, dễ maintain
* [ ] Performance hợp lý (vectorization thay vì loop khi có thể)
---