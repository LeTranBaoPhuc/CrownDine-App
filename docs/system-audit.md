# Kiểm tra hệ thống và bản chạy local

Ngày kiểm tra: 08/11/2026. Nhánh: `feat/table-floor-api-orders`.

## Chạy và xem bàn ngay

- Flutter web: http://127.0.0.1:5175
- Backend CrownDine: http://127.0.0.1:8081/api/
- Database phát triển riêng: Docker container `crowndine-dev-mysql`, cổng `127.0.0.1:3307`, volume `crowndine-dev-mysql-data`.
- Tài khoản mẫu phát triển: `alice / 123456` (STAFF); `johndoe / 123456` (ADMIN).
- Đã đăng nhập thử bằng API và xác nhận **50 bàn, 2 tầng**. API bàn trống theo khung giờ trả đủ thông tin tầng/khu vực.

Nguyên nhân bàn không hiển thị: cổng 8080 đang thuộc ứng dụng khác, các API CrownDine trả 404; backend CrownDine còn không khởi động được trên schema mới do thiếu các bảng model. Đã bổ sung migration V4 và dùng cổng 8081. Dữ liệu hiện tại là dữ liệu khởi tạo từ migration của dự án trong database phát triển riêng. Database MySQL sẵn có tại cổng 3306 được giữ nguyên.

Trong Cấu hình máy chủ, URL cho web là `http://127.0.0.1:8081/api/`; Android Emulator dùng `http://10.0.2.2:8081/api/`. Cấu hình đã lưu trên thiết bị được ưu tiên hơn giá trị `--dart-define=API_BASE_URL=...`. Đổi máy chủ sẽ xóa phiên đăng nhập cũ.

Khởi động backend từ thư mục dự án bằng PowerShell:

```powershell
.\scripts\start-backend.ps1
```

Script build bản JAR với profile `dev`, chạy nền ở cổng 8081 và tắt DevTools restart. JAR đang chạy được chép ra `%LOCALAPPDATA%\CrownDine\local-runtime`, nên việc IDE/Maven làm mới `backend/target` không làm mất cấu hình hoặc dừng API. Script chỉ báo sẵn sàng sau khi gọi API tầng thành công; log và PID cũng ở thư mục runtime này. Khi đã có JAR có thể dùng `-SkipBuild`.

Script khởi động lại container `crowndine-dev-mysql` nếu container này đã tồn tại và đang dừng. Không tạo lại database hoặc xóa dữ liệu. Cần giữ file `.env` local. Mail/AI mặc định dùng cấu hình local; chỉ dùng `-EnableMail` / `-EnableAI` sau khi đã cấu hình dịch vụ thật.

Trong terminal khác tại thư mục chứa `pubspec.yaml`:

```powershell
flutter run -d web-server --no-pub --web-hostname 127.0.0.1 --web-port 5175 --dart-define=API_BASE_URL=http://127.0.0.1:8081/api/
```

Mail và Gemini trong lệnh chạy trên là cấu hình vô hiệu hóa cho local; cần cấu hình dịch vụ thật để kiểm tra OTP/AI. Không có email hay giao dịch PayOS thật nào được gửi bởi bộ test.

## Các lỗi ưu tiên đã sửa

| Mức | Vấn đề | Kết quả |
|---|---|---|
| P0 | Khách đọc/sửa checkout, voucher hoặc tạo cọc cho đặt chỗ của người khác | Kiểm tra chủ sở hữu ở service, phân quyền danh sách toàn hệ thống và thao tác nhân viên |
| P0 | WebSocket cho phép cập nhật trạng thái hoặc đăng ký kênh nghiệp vụ thiếu quyền | Xác thực handshake, giới hạn SEND/SUBSCRIBE và bảo vệ kênh thông báo cá nhân |
| P0 | Khách tự xác nhận tiền mặt; nút hoàn tất bỏ qua thu tiền | CASH chỉ STAFF/ADMIN; hoàn tất đơn qua dịch vụ thanh toán |
| P0 | Webhook chỉ kiểm chữ ký, không kiểm mã thành công/số tiền/phương thức | Đối chiếu đầy đủ, khóa giao dịch, xử lý idempotent, rollback khi xử lý lỗi |
| P0 | Mất phản hồi tạo link có thể sinh giao dịch mới | Lưu intent trước khi gọi gateway, dùng lại mã pending; khôi phục/đối chiếu cùng mã |
| P0 | Gọi thêm món làm tính sai cọc đã trả; thay đổi báo giá khi đang thanh toán | Lưu phần cọc bàn tại lúc tạo; tất toán trừ tiền cọc món thực tế; khóa sửa giá khi pending |
| P0 | Thanh toán đến muộn khôi phục đặt chỗ đã hủy/hết hạn | Ghi nhận tiền nhưng không khôi phục đặt chỗ; hiển thị yêu cầu đối soát |
| P0 | Sửa/xóa món không tính lại đầy đủ giá; sửa đơn đã kết thúc; thay đổi ngược trạng thái món | Tính lại báo giá, giữ đơn giá đã nhận, kiểm trạng thái và giao dịch pending |
| P0 | Nhận bàn đè khách khác; hết hạn đặt trước giải phóng bàn đang phục vụ | Khóa phiên/bàn, kiểm tra đơn và lượt nhận bàn; không giải phóng bàn của phiên khác |
| P0 | Enum SQL thanh toán lệch Java, mapping User/Payment sai, thiếu bảng khiến backend không chạy | Sửa mapping, V3 chuẩn hóa enum và snapshot, V4 bổ sung bảng thiếu; đã chạy Flyway + Hibernate validate trên MySQL mới |
| P0 | Combo trùng ID món: sửa/xóa/đổi trạng thái nhầm món | Dùng API combo, giữ thành phần combo và phân biệt ID theo loại sản phẩm |
| P0 | Refresh đồng thời, đăng xuất/đổi máy chủ gây ghi lại token cũ hoặc gửi nhầm phiên | Một refresh dùng chung, chặn retry khác phiên, xóa token trước đổi URL và tách cache cá nhân |
| P0 | Google access token thiếu ràng buộc ứng dụng/email xác minh; OTP không giới hạn lần thử | Chỉ nhận ID token đúng audience/email_verified, kiểm tài khoản hoạt động; giới hạn lần thử, SecureRandom, thu hồi refresh sau đổi/reset mật khẩu |
| P0 | Khóa bí mật viết trực tiếp trong config; tài khoản demo mặc định ở production | Dùng biến môi trường; V5 production vô hiệu hóa tài khoản demo chưa đổi mật khẩu |

Khóa từng xuất hiện trong lịch sử Git cần được chủ tài khoản thay tại các nhà cung cấp trước khi triển khai công khai. Việc đổi khóa ngoài hệ thống chưa được thực hiện.

V3 giữ nguyên thông tin CANCELLED/EXPIRED/REFUNDED lịch sử. Không suy đoán phần cọc bàn của giao dịch cũ thiếu snapshot: các đơn liên quan phải đối soát trước khi tất toán.

## Giao diện và API đã bổ sung/hoàn thiện

- Nhân viên: màn tất toán tiền mặt/PayOS, xem cọc đã trả, chặn thu lại giao dịch pending, kiểm tra kết quả và mở lại cùng link.
- Nhân viên: hoàn tất/trả bàn cho lượt không gọi món; backend chặn đơn chưa thanh toán.
- Khách: chọn bàn theo ngày/giờ/số khách, dùng tên tầng thật và metadata đúng; khôi phục giao dịch từ server; thanh toán web bằng sao chép link PayOS và kiểm tra kết quả.
- Quản trị: Thiết lập nhà hàng → danh mục, combo và thành phần món, tầng/khu vực/bàn với thông số vị trí, ca làm việc. Dùng Card/Form/AppBar/theme chung; lỗi lưu giữ nguyên biểu mẫu.
- Hồ sơ: đổi ảnh, đổi email bằng OTP; giữ đúng ngày sinh/giới tính cũ khi chỉnh sửa.
- Chấm công, lịch làm, nhân sự, đặt bàn và dashboard: bỏ fallback thành dữ liệu giả/thông báo lưu thành công khi API lỗi. Hộp chấm công tải đúng nhân viên, ca và trạng thái thật.
- Cấu hình kết nối: kiểm tra đúng URL đang nhập, kiểm định dạng và không gửi bearer token khi kiểm tra máy chủ khác.

## Bằng chứng kiểm tra

- Backend: **53 test** qua, gồm phân quyền HTTP thực, STOMP, mapping/migration, tiền cọc/tất toán, webhook lặp/sai tiền, vòng đời đặt bàn, chỉnh món và OTP limiter.
- Flutter: **60 test** qua, gồm refresh đồng thời/đăng xuất, combo API, trạng thái pending không báo thanh toán thành công, biểu mẫu lỗi và luồng đặt bàn/voucher/bàn ăn.
- `flutter analyze --no-pub --no-fatal-infos`: không error/warning; còn các lint info, phần lớn liên quan API Flutter deprecated và dấu ngoặc điều kiện.
- `flutter build web --no-pub`: thành công; bản debug đang phục vụ tại cổng 5175.
- Runtime MySQL: Flyway V1–V4 thành công, Hibernate `ddl-auto=validate` qua, backend khởi động, API floors/tables/available truy vấn được dữ liệu thật.
- Android APK: chưa build được vì tải Gradle 9.3.1 trả HTTP 504. Chưa xác nhận trên emulator/điện thoại thật.

## Phần cần kiểm tra trước khi nộp/triển khai

1. Chạy end-to-end Android trên thiết bị thật khi tải được Gradle: đặt bàn → cọc → nhận bàn → gọi thêm → bếp → thu tiền → trả bàn.
2. Cấu hình và kiểm tra Mail/Google/Cloudinary/PayOS bằng môi trường thử của nhóm. Chưa xác nhận thanh toán tiền thật, callback công khai hay gửi OTP thật.
3. Đối soát các khoản cọc lịch sử thiếu snapshot và tiền đến sau khi đặt chỗ hết hạn/hủy; hoàn tiền cần quy trình vận hành rõ ràng, chưa có luồng hoàn tiền tự động.
4. App hiện cập nhật bếp/bàn qua refresh; chưa có subscriber realtime Flutter. Các danh sách lịch sử cần phân trang đầy đủ nếu dùng dữ liệu lớn.
5. OTP limiter đang lưu trong một tiến trình; triển khai nhiều replica cần bộ đếm dùng chung. Access JWT đã cấp có TTL 15 phút; thu hồi refresh không thay thế cơ chế thu hồi tức thời từng access JWT.
6. Các model Banner/Chat/Review phụ trợ chưa đồng nghĩa có đầy đủ nghiệp vụ và màn quản trị mobile; cần chốt phạm vi môn học trước khi mở rộng thành chức năng chính.

Không coi bộ unit/widget test hoặc bản web chạy được là bằng chứng toàn bộ hệ thống đã hoàn thành kiểm thử tích hợp thực tế.

### Sự cố kết nối khi chạy thử

Nếu console báo `ERR_CONNECTION_REFUSED` ở mọi API `8081`, kiểm tra tiến trình backend trước khi sửa giao diện. Trong lần chạy thử, DevTools đã thấy 445 file bị xóa khỏi classpath, tự restart giữa lúc thư mục build đang được làm mới, rồi khởi động thiếu profile `dev` và báo thiếu `jwt.access-key`. Lệnh chạy JAR ở trên loại bỏ sự phụ thuộc đó. Các dòng `enable_copy.js` thuộc extension trình duyệt; DDC tải module là log khởi động Flutter web.
