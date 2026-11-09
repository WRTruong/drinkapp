# Ứng dụng đặt đồ uống

Ứng dụng di động Flutter cho phép khách xem menu, tuỳ chỉnh đồ uống, đặt hàng và theo dõi trạng thái. Backend dùng ASP.NET Core Web API và SQL Server; khu vực nhân viên dùng để quản lý tồn kho và xử lý đơn.

## ✨ Tính năng chính

- Xem menu, mô tả, tình trạng còn hàng và giá khởi điểm.
- Tuỳ chỉnh size, lượng đường, lượng đá và số lượng. Giá size S bằng giá gốc; size M cộng 5.000đ; size L cộng 10.000đ. App hiển thị giá theo size đã chọn; API tính lại giá khi tạo đơn.
- Thêm món vào giỏ hàng, cập nhật số lượng hoặc xoá món.
- Tạo đơn hàng với tên người nhận, số điện thoại và ghi chú.
- Xác nhận thanh toán demo trong app. Đây là thao tác giả lập, không thu tiền thật; đơn chưa xác nhận trong 10 phút sẽ tự huỷ.
- Theo dõi trạng thái đơn hàng; ứng dụng tự làm mới thông tin mỗi 15 giây.
- Xem lại tối đa 20 đơn gần nhất được lưu trên thiết bị (không cần đăng nhập).
- Nhận thông báo trên thiết bị về trạng thái đơn hàng.
- Nhân viên có thể cập nhật tình trạng món và trạng thái pha chế của đơn đã thanh toán.

## 🧰 Công nghệ sử dụng

- **Frontend:** Flutter, Dart, HTTP, Flutter Local Notifications.
- **Backend:** ASP.NET Core Web API, .NET 10, Entity Framework Core.
- **Cơ sở dữ liệu:** Microsoft SQL Server.
- **API docs:** Swagger UI.

## 💻 Yêu cầu hệ thống

- Windows, macOS hoặc Linux có thể chạy Flutter và .NET SDK.
- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0).
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.3.0 <4.0.0`).
- [SQL Server](https://www.microsoft.com/sql-server/) và công cụ chạy script SQL, ví dụ SQL Server Management Studio (SSMS).
- Android Studio hoặc thiết bị Android để chạy ứng dụng; cài đặt và khởi động Android Emulator nếu chạy trên máy ảo.

## 🚀 Hướng dẫn cài đặt

Thực hiện lần lượt các bước dưới đây. Các lệnh Flutter cần chạy từ thư mục `drink_app`, còn lệnh backend chạy từ `DrinkApi`.

### 1. Database

1. Khởi động SQL Server.
2. Mở file [`drinkDb.sql`](drinkDb.sql) bằng SSMS và thực thi toàn bộ script. Script tạo database `DrinkDb`, các bảng `Drinks`, `Orders`, `OrderItems` và một số dữ liệu đồ uống mẫu. Script **chạy lại nhiều lần vẫn an toàn**: chỉ tạo database/bảng khi chưa có, chỉ thêm món mẫu còn thiếu và không xoá dữ liệu đang có. File được lưu ở UTF-8 (có BOM) — giữ nguyên bảng mã này khi mở/sửa để tiếng Việt không bị lỗi. Ảnh món mẫu nằm ngay trong `DrinkApi/wwwroot/images` (nguồn: Wikimedia Commons, giấy phép tự do — xem `CREDITS.txt`), API phục vụ tại `/images/<tên>.jpg`; database lưu đường dẫn tương đối và app ghép với `API_BASE_URL`, nên ảnh tải từ chính API (nhanh, không cần internet).
3. Trong bước Backend, cập nhật chuỗi kết nối để trỏ tới đúng SQL Server instance trên máy của bạn.

### 2. Backend

1. [`DrinkApi/appsettings.json`](DrinkApi/appsettings.json) chứa chuỗi kết nối mặc định `Server=localhost`. Nếu SQL Server của bạn là một instance khác (ví dụ `TRUONG\SQLEXPRESS`), đặt chuỗi thật trong `DrinkApi/appsettings.Development.json` — file cấu hình riêng cho máy phát triển, không nên commit. Ví dụ:

   ```json
   {
     "ConnectionStrings": {
       "Default": "Server=localhost;Database=DrinkDb;Trusted_Connection=True;TrustServerCertificate=True;"
     }
   }
   ```

   Đảm bảo database `DrinkDb` đã được tạo ở bước 1. Khi chạy `dotnet run`, profile `http` trong `launchSettings.json` đặt `ASPNETCORE_ENVIRONMENT=Development` nên `appsettings.Development.json` sẽ được nạp.
2. Mở terminal tại thư mục `DrinkApi`, sau đó chạy:

   ```bash
   dotnet restore
   dotnet run
   ```

   API được cấu hình lắng nghe tại `http://localhost:5000`. Tài liệu Swagger có tại `http://localhost:5000/swagger`.

### 3. App

1. `baseUrl` mặc định là `http://10.0.2.2:5000`. Khi chạy trên thiết bị thật, không cần sửa code — truyền địa chỉ IP LAN của máy backend qua `--dart-define`:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
   ```

   `10.0.2.2` là địa chỉ đặc biệt để **Android Emulator** truy cập loopback của máy phát triển. Với iOS Simulator, web hoặc thiết bị thật, dùng địa chỉ mà thiết bị đó truy cập được (ví dụ IP LAN `192.168.1.10`). Giá trị này được đọc trong [`drink_app/lib/services/api_service.dart`](drink_app/lib/services/api_service.dart). Đảm bảo backend và thiết bị dùng chung mạng.
2. Mở terminal tại `drink_app`, tải dependencies và chạy ứng dụng:

   ```bash
   flutter pub get
   flutter run
   ```

### 4. Phân quyền nhân viên

Các API quản trị yêu cầu header `X-Admin-Key` khớp với giá trị `Admin:ApiKey` trong cấu hình backend.

- Mã mặc định khi phát triển: `nhanvien123`, đặt trong `DrinkApi/appsettings.Development.json`.
- `DrinkApi/appsettings.json` để trống `Admin:ApiKey`, nên khi triển khai phải cấu hình bằng biến môi trường `Admin__ApiKey=<mã mới>`.
- Trong app: long-press tiêu đề **Menu đồ uống** để mở khu vực nhân viên và nhập mã. Mã chỉ giữ trong bộ nhớ của phiên chạy hiện tại, không lưu xuống thiết bị.
- Thử trong Swagger: bấm **Authorize**, nhập mã, rồi gọi các API quản trị.

### 5. Lịch sử đơn

Ứng dụng chưa có tài khoản khách hàng:

- Backend lưu dữ liệu đơn trong SQL Server. Mỗi đơn có mã `ORD-...`, chi tiết món, giá đã tính theo size, tổng tiền và trạng thái.
- App lưu tối đa 20 đơn gần nhất trên thiết bị bằng `shared_preferences`. Khi mở một đơn hoặc kéo xuống làm mới, app lấy trạng thái mới nhất từ API.

Xoá dữ liệu hoặc gỡ ứng dụng sẽ xoá danh sách đơn lưu trên thiết bị; dữ liệu đơn trên server không bị ảnh hưởng.

### 6. Thanh toán demo

1. Khi khách đặt hàng, API tạo đơn ở trạng thái chưa thanh toán và bắt đầu thời gian giữ đơn (mặc định 10 phút, cấu hình bằng `Payment:WindowMinutes`).
2. Khách mở chi tiết đơn và chọn **Xác nhận thanh toán demo**, sau đó xác nhận trong hộp thoại.
3. App gọi `POST /api/orders/{id}/demo-payment/confirm`; API cập nhật trạng thái thanh toán, rồi app tải lại chi tiết đơn.
4. Chỉ đơn đã xác nhận mới xuất hiện trong hàng chờ nhân viên. Đơn chưa thanh toán quá hạn sẽ bị huỷ.

**Không có giao dịch tiền thật.** Endpoint xác nhận demo không có xác thực cổng thanh toán và chỉ phù hợp chạy đồ án/demo; không dùng trong môi trường thu tiền thật. Backend cũng có luồng cổng giả lập riêng (`POST /api/orders/{id}/pay` và `/pay/mock/...`) để thử chuyển hướng.

## 📡 Danh sách API

Base URL mặc định: `http://localhost:5000` cho backend và `http://10.0.2.2:5000` cho Android Emulator. Các endpoint API có tiền tố `/api`.

| Phương thức | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/drinks` | Lấy menu, gồm cả món đang hết hàng. |
| `PATCH` | `/api/drinks/{id}/toggle-stock` 🔒 | Đổi tình trạng còn hàng/hết hàng. |
| `GET` | `/api/orders` 🔒 | Lấy đơn đã thanh toán, chưa hoàn tất và chưa bị huỷ. |
| `POST` | `/api/orders` | Tạo đơn và tính giá theo size ở phía server. |
| `GET` | `/api/orders/{id}` | Lấy chi tiết và trạng thái đơn. |
| `POST` | `/api/orders/{id}/demo-payment/confirm` | Xác nhận thanh toán demo; không thu tiền thật. |
| `POST` | `/api/orders/{id}/pay` | Tạo phiên cho luồng cổng giả lập riêng. |
| `POST` | `/api/orders/{id}/cancel` | Khách huỷ đơn chưa thanh toán. |
| `PATCH` | `/api/orders/{id}/status` 🔒 | Nhân viên cập nhật trạng thái pha chế. |
| `GET` | `/pay/mock/{paymentRef}` | Trang cổng giả lập (không có tiền thật). |
| `GET` | `/pay/mock/{paymentRef}/confirm?ok=1` | Mô phỏng kết quả thanh toán cho luồng cổng giả lập. |

🔒 = yêu cầu header `X-Admin-Key` (xem mục [Phân quyền nhân viên](#4-phân-quyền-nhân-viên)).

### Ví dụ tạo đơn hàng

```json
{
  "customerName": "Nguyễn Văn A",
  "phone": "0900000000",
  "note": "Ít ngọt",
  "items": [
    {
      "drinkId": 1,
      "quantity": 2,
      "size": "M",
      "sugarLevel": "50%",
      "iceLevel": "100%"
    }
  ]
}
```

Các trạng thái đơn hàng được hỗ trợ: `Pending`, `Preparing`, `Ready`, `Completed`, `Cancelled`.
