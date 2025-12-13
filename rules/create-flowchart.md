# **1. MỤC TIÊU**

Khi nhận mã nguồn Python của thuật toán (hoặc module), hệ thống phải:

1. Phân tích luồng xử lý của thuật toán.
2. Xây dựng **sơ đồ thuật toán bằng Mermaid**, viết **tiếng Việt**.
3. Sinh file Markdown `{algorithm_name}-flowchart.md`.
4. Xin phản hồi và chỉnh sửa cho đến khi đạt yêu cầu.

---

# **2. QUY TRÌNH TỔNG QUÁT (WORKFLOW)**

### **Bước 1: Phân tích mã nguồn**

* Đọc toàn bộ hàm/ lớp/ module được cung cấp.
* Xác định:

  * Khởi tạo
  * Vòng lặp chính
  * Rẽ nhánh
  * Cập nhật trạng thái
  * Điều kiện dừng
  * Các bước tiền xử lý/ hậu xử lý
* Trích ra *luồng xử lý chính* (main pipeline).

---

### **Bước 2: Chuyển thành Flowchart Mermaid**

Sơ đồ phải:

* Dùng tiếng Việt.
* Phản ánh đúng 3 phần chính:

  1. **Khởi tạo**
  2. **Vòng lặp chính**
  3. **Kết thúc (Termination)**

---

### **Bước 3: Tạo File Markdown**

File `{algorithm_name}-flowchart.md` gồm 3 phần:

---

## **(1) Phần Tiêu Đề (H1)**

Format:

```
# Sơ đồ thuật toán {Algorithm Name}
```

---

## **(2) Phần Sơ Đồ Mermaid**

### **QUY TẮC BẮT BUỘC KHI VIẾT NODE**

* Mọi nội dung phải nằm trong `""`:

  * ✅ `A["Khởi tạo quần thể"]`
  * ❌ `A[Khởi tạo quần thể]`
* Nhánh phải dùng `"Chưa"` `"Rồi"` hoặc `"Có"` `"Không"` tùy ngữ cảnh.
* Không chứa ký tự xuống dòng `\n`.
* Được phép dùng công thức dạng ngắn gọn:

  * `"a = 2 - iter*(2/max_iter)"`
  * `"X_i = (X1 + X2 + X3)/3"`

### **Cấu trúc chung của flowchart**

* Có node “Bắt đầu”
* Khối khởi tạo
* Khối vòng lặp
* Khối kết thúc
* Tối thiểu phải có 1 điều kiện dừng (decision node)

---

## **(3) Phần Giải Thích Chi Tiết**

* Viết bằng tiếng Việt.
* Không rút gọn, không viết tắt.
* Giải thích rõ từng bước tương ứng với flowchart.
* Công thức nếu có → đặt trong block Python:

```python
a = 2 - iter * (2 / max_iter)
```

---

# **3. QUY TẮC LƯU TRỮ**
Tên file phải:

* chữ thường
* không dấu
* gạch dưới `_`

Ví dụ:

```
greywolf_optimizer-flowchart.md
```

---

# **4. QUY TẮC PHẢN HỒI – CẬP NHẬT**

Sau khi sinh file lần đầu:

1. Hỏi người dùng:
   **“Bạn có muốn chỉnh sửa, bổ sung hoặc mở rộng phần nào không?”**

2. Nếu có feedback:

   * Đọc lại toàn bộ file `.md`
   * Xác định vùng cần chỉnh sửa
   * Cập nhật lại flowchart hoặc phần mô tả
   * Gửi lại phiên bản đã cập nhật

3. Lặp lại cho đến khi người dùng xác nhận **Hoàn tất**.

---

# **5. NGUYÊN TẮC CHUNG ĐỂ TRIỂN KHAI**

* Chỉ dùng **tiếng Việt** trong sơ đồ và mô tả.
* Node phải ngắn gọn nhưng chính xác.
* Luồng thuật toán phải phản ánh đúng logic code.
* Không tự ý thêm logic không có trong code.
* Không làm đơn giản hóa quá mức (flowchart phải đủ bước).
* Luôn đảm bảo có:
  *Khởi tạo → Xử lý chính → Kiểm tra điều kiện → Lặp → Kết thúc*
---

