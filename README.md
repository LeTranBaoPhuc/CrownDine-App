# 👑 CrownDine — Hệ Thống Đặt Bàn & Quản Lý Nhà Hàng Cao Cấp

**CrownDine** là giải pháp phần mềm toàn diện (Full-stack & Cross-platform) dành cho nhà hàng cao cấp, tích hợp quy trình từ trải nghiệm đặt bàn, chọn món trước, thanh toán trực tuyến của **Khách hàng**, đến điều phối sơ đồ bàn, bếp (KDS), đơn hàng của **Nhân viên** và quản trị doanh thu, nhân sự, khuyến mãi của **Quản trị viên (Admin)**.

---

## 📑 Mục Lục

- [Kiến Trúc Hệ Thống](#-kiến-trúc-hệ-thống)
- [Tính Năng Chính](#-tính-năng-chính)
- [Công Nghệ Sử Dụng](#-công-nghệ-sử-dụng)
- [Cấu Trúc Thư Mục](#-cấu-trúc-thư-mục)
- [Hướng Dẫn Cài Đặt & Chạy Dự Án](#-hướng-dẫn-cài-đặt--chạy-dự-án)
  - [1. Khởi chạy Backend (Spring Boot + MySQL)](#1-khởi-chạy-backend-spring-boot--mysql)
  - [2. Khởi chạy Ứng dụng Flutter (Mobile / Web / Desktop)](#2-khởi-chạy-ứng-dụng-flutter-mobile--web--desktop)
  - [3. Khởi chạy Web Frontend (React + Vite)](#3-khởi-chạy-web-frontend-react--vite)
- [Cấu Hình Môi Trường & Thanh Toán](#-cấu-hình-môi-trường--thanh-toán)
- [Kiểm Thử (Testing)](#-kiểm-thử-testing)

---

## 🏗 Kiến Trúc Hệ Thống

Repository được tổ chức theo mô hình đa nền tảng gồm 3 thành phần chính:

1. **Flutter Application (`lib/`, thư mục gốc)**: Ứng dụng đa nền tảng (Android, iOS, Web, Desktop) phục vụ đầy đủ 3 phân quyền `Customer`, `Staff`, và `Admin`. Hỗ trợ kết nối API thời gian thực hoặc tự động chuyển sang chế độ **Mock Fallback** khi chạy độc lập.
2. **Backend API (`backend/`)**: Hệ thống RESTful API & WebSocket xây dựng bằng **Spring Boot 3 (Java 21)**, quản lý nghiệp vụ, bảo mật JWT/OAuth2, tích hợp cổng thanh toán **PayOS**, lưu trữ đám mây **Cloudinary**, và trợ lý ảo **Spring AI (Google GenAI)**.
3. **Web Frontend (`frontend/`)**: Ứng dụng Web hiện đại viết bằng **React 19 + TypeScript + Vite**, tối ưu trải nghiệm đặt bàn trực tuyến, chat AI và bảng điều khiển quản trị.

---

## ✨ Tính Năng Chính

### 👤 Phân quyền Khách hàng (Customer)
- **Xác thực & Bảo mật**: Đăng ký/Đăng nhập với xác thực OTP qua Email, khôi phục mật khẩu, đăng nhập nhanh bằng **Google OAuth2**.
- **Khám phá Thực đơn**: Xem danh mục món ăn, combo ưu đãi, tìm kiếm/lọc món, lưu món ăn yêu thích (*Favorites*) và xem đánh giá thực tế từ thực khách.
- **Đặt bàn trực tuyến 4 bước**:
  1. Chọn ngày, khung giờ và số lượng khách.
  2. Chọn vị trí bàn trực quan trên sơ đồ tầng (*Floor Map*) theo trạng thái trống thời gian thực.
  3. Đặt món ăn trước (*Pre-order*) đồng bộ giỏ hàng với máy chủ.
  4. Xác nhận thông tin, áp dụng mã giảm giá từ ví Voucher và thanh toán tiền cọc qua cổng **PayOS** (hỗ trợ QR Code / chuyển khoản trong WebView).
- **Ví Voucher & Điểm thưởng**: Quản lý danh sách voucher cá nhân (*My Vouchers*), theo dõi lịch sử tích điểm thành viên (*Reward Points*), lịch sử đặt bàn và nhận thông báo mới nhất.
- **Trợ lý AI (Web)**: Tư vấn thực đơn và hỗ trợ giải đáp thông tin nhà hàng tự động.

### 🧑‍🍳 Phân quyền Nhân viên (Staff)
- **Sơ đồ bàn trực quan (*Floor Plan*)**: Theo dõi trạng thái bàn theo từng tầng (Trống, Đã đặt, Đang phục vụ) và điều phối khách.
- **Quản lý đặt bàn (*Reservations*)**: Xem danh sách đặt bàn theo dạng Lịch (*Calendar*) hoặc Danh sách (*List*), tạo đặt bàn trực tiếp cho khách vãng lai, thực hiện Check-in, đổi bàn hoặc hủy lịch.
- **Quản lý gọi món (*Order Management*)**: Tạo và cập nhật đơn hàng tại bàn.
- **Màn hình hiển thị bếp (*Kitchen Display System - KDS*)**: Tiếp nhận và cập nhật trạng thái chế biến từng món ăn theo thời gian thực.
- **Lịch làm việc (*Work Schedule*)**: Xem ca làm việc cá nhân theo bảng ma trận tuần hoặc lịch trình (*Agenda*).

### 🛠 Phân quyền Quản trị viên (Admin)
- **Bảng điều khiển (*Dashboard & Analytics*)**: Thống kê doanh thu, số lượng đơn hàng và hiệu suất kinh doanh theo thời gian.
- **Quản lý thực đơn (*Menu Management*)**: Thêm, sửa, xóa và bật/tắt trạng thái phục vụ của món ăn, danh mục, combo.
- **Quản lý nhân sự & Chấm công (*Staff & Attendance*)**: Quản lý hồ sơ nhân viên, phân ca làm việc, theo dõi bảng chấm công theo ca và tổng hợp theo nhân viên.
- **Quản lý khuyến mãi (*Voucher Management*)**: Tạo mã giảm giá (`PERCENTAGE` / `FIXED_AMOUNT`), cấu hình điều kiện đơn tối thiểu và phát hành voucher cho khách hàng.
- **Quản lý thanh toán & Đánh giá (*Payments & Feedbacks*)**: Tra cứu lịch sử giao dịch PayOS và kiểm duyệt phản hồi của khách hàng.

---

## 💻 Công Nghệ Sử Dụng

| Thành phần | Công nghệ / Thư viện tiêu biểu |
| :--- | :--- |
| **Mobile & Cross-platform** | Flutter (`SDK >=3.3.0 <4.0.0`), Dart, Riverpod (`flutter_riverpod`), Dio, Shared Preferences, Google Sign-In, WebView Flutter, Google Fonts, Intl |
| **Web Frontend** | React 19, TypeScript 5.9, Vite 7, Tailwind CSS 4, Radix UI, Zustand, TanStack React Query, React Hook Form, Zod, STOMP.js (WebSocket), Recharts |
| **Backend** | Java 21, Spring Boot 3.5.11, Spring Security, Spring Data JPA, WebSocket, Spring AI (`google-genai`), PayOS SDK, Cloudinary, Apache POI (Excel), Thymeleaf, JavaMail, SpringDoc OpenAPI (Swagger) |
| **Cơ sở dữ liệu & DevOps** | MySQL 8.0, Flyway Migration, Docker, Docker Compose |

---

## 📂 Cấu Trúc Thư Mục

```text
CrownDine-App/
├── lib/                          # Mã nguồn ứng dụng Flutter chính
│   ├── core/                     # Cấu hình API, Dio client, Theme (Light/Dark), Utils
│   ├── data/                     # Models, Repositories, Local Storage & Mock Data
│   ├── presentation/             # Giao diện người dùng (Screens & Widgets)
│   │   ├── screens/
│   │   │   ├── admin/            # Dashboard, Attendance, Menu, Staff, Voucher, Payment, Feedback
│   │   │   ├── auth/             # Login, Register, Forgot Password
│   │   │   ├── customer/         # Home, Menu, Reservation (4 steps + PayOS), Profile, Notification
│   │   │   ├── settings/         # Cấu hình máy chủ API & chế độ Mock trực tiếp trên App
│   │   │   └── staff/            # Floor Plan, Reservations, Orders, Kitchen (KDS), Work Schedule
│   │   └── widgets/              # Các thành phần UI dùng chung
│   ├── providers/                # Quản lý trạng thái với Riverpod Providers
│   └── main.dart                 # Điểm khởi đầu và điều hướng theo Role của ứng dụng Flutter
├── backend/                      # Mã nguồn máy chủ Spring Boot (Java 21)
│   ├── src/main/java/            # Controllers, Services, Repositories, Entities, Security, Configs
│   ├── src/main/resources/       # Cấu hình ứng dụng & kịch bản Flyway SQL Migration
│   ├── Dockerfile                # Cấu hình đóng gói Docker cho Backend
│   ├── docker-compose.yml        # Khởi chạy đồng bộ Backend + MySQL 8.0
│   └── pom.xml                   # Quản lý phụ thuộc Maven
├── frontend/                     # Mã nguồn ứng dụng Web (React 19 + TypeScript + Vite)
│   ├── src/                      # apis, components, hooks, layouts, pages, routes, stores, types
│   └── package.json              # Quản lý phụ thuộc NPM
├── assets/                       # Hình ảnh và tài nguyên tĩnh của ứng dụng Flutter
├── docs/                         # Tài liệu nghiệp vụ chi tiết (PayOS Checkout, Ví Voucher...)
├── test/                         # Unit tests & Widget tests cho ứng dụng Flutter
├── .env.example                  # Mẫu biến môi trường cho dự án
└── pubspec.yaml                  # Cấu hình package và dependencies của Flutter
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu cầu hệ thống
- **Flutter SDK**: `>= 3.3.0`
- **Java JDK**: `21` (và Maven hoặc dùng `mvnw` đi kèm)
- **Node.js**: `>= 20.x` (nếu chạy Web Frontend)
- **MySQL**: `8.0` hoặc **Docker Desktop**

---

### 1. Khởi chạy Backend (Spring Boot + MySQL)

#### Cách 1: Sử dụng Docker Compose (Khuyên dùng)
```bash
cd backend
# Tạo file .env chứa các biến môi trường cần thiết (Database, JWT, PayOS, Cloudinary, Mail...)
docker-compose up -d --build
```
- Backend API sẽ chạy tại: `http://localhost:8080`
- MySQL chạy tại cổng: `3306` (Database: `crowndine`)

#### Cách 2: Chạy trực tiếp bằng Maven Wrapper
```bash
cd backend
# Windows
.\mvnw.cmd spring-boot:run

# macOS / Linux
./mvnw spring-boot:run
```
- Tài liệu **Swagger UI** có thể truy cập tại: `http://localhost:8080/swagger-ui/index.html`

---

### 2. Khởi chạy Ứng dụng Flutter (Mobile / Web / Desktop)

Từ thư mục gốc của dự án (`CrownDine-App`):

```bash
# 1. Cài đặt các gói phụ thuộc
flutter pub get

# 2. Chạy ứng dụng (có thể truyền thêm biến môi trường nếu cần)
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
```

> 💡 **Mẹo cấu hình nhanh trong ứng dụng**:
> - Mặc định, ứng dụng tự động kết nối tới `http://10.0.2.2:8080/api/` (trên Android Emulator) hoặc `http://localhost:8080/api/` (trên Web/Desktop/iOS Simulator).
> - Bạn có thể thay đổi trực tiếp **Base URL** của máy chủ và bật/tắt chế độ **Mock Fallback** ngay trên giao diện **Server Config Screen** của ứng dụng mà không cần biên dịch lại.

---

### 3. Khởi chạy Web Frontend (React + Vite)

```bash
cd frontend

# 1. Cài đặt dependencies
npm install

# 2. Chạy môi trường phát triển (Development)
npm run dev

# 3. Build bản Production
npm run build
```

---

## ⚙️ Cấu Hình Môi Trường & Thanh Toán

1. **Google OAuth**:
   - Sao chép `.env.example` thành `.env` và điền `GOOGLE_CLIENT_ID`.
   - Khi chạy Flutter, truyền qua `--dart-define=GOOGLE_CLIENT_ID=...` hoặc cấu hình trong `config.json` (đối với bản Web).
2. **Luồng thanh toán PayOS (Bước 4 Đặt bàn)**:
   - Ứng dụng tạo liên kết thanh toán qua endpoint `POST /api/payments/create` với phương thức `PAYOS` và mở cổng thanh toán trong `WebView`.
   - Đường dẫn callback mặc định:
     - Thành công: `/thanh-toan/thanh-cong`
     - Thất bại / Hủy: `/thanh-toan/that-bai`
   - Có thể tùy chỉnh đường dẫn callback khi build Flutter bằng:
     ```bash
     --dart-define=PAYOS_SUCCESS_PATH=/thanh-toan/thanh-cong \
     --dart-define=PAYOS_CANCEL_PATH=/thanh-toan/that-bai
     ```
   - Trạng thái đơn đặt bàn chỉ được xác nhận hoàn tất khi máy chủ trả về trạng thái `SUCCESS` từ API kiểm tra giao dịch. Xem chi tiết tại [`docs/step4-payment-integration.md`](docs/step4-payment-integration.md) và [`docs/my-vouchers.md`](docs/my-vouchers.md).

---

## 🧪 Kiểm Thử (Testing)

Chạy bộ kiểm thử tự động (Unit test & Widget test) cho ứng dụng Flutter:

```bash
# Chạy toàn bộ test
flutter test

# Chạy kiểm thử tính năng Ví Voucher & Checkout
flutter test test/my_vouchers_test.dart

# Phân tích mã nguồn (Linting)
flutter analyze
```

---

## 📄 Giấy Phép

Dự án được phát triển phục vụ mục đích học tập và xây dựng hệ thống quản lý nhà hàng **CrownDine**.
