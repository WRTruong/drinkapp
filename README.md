# 🧋 Ứng dụng Đặt đồ uống

Ứng dụng đặt đồ uống gồm ứng dụng di động Flutter, REST API xây dựng bằng ASP.NET Core và cơ sở dữ liệu SQL Server. Người dùng có thể xem menu, tuỳ chỉnh đồ uống, tạo đơn hàng và theo dõi trạng thái đơn.

## 📸 Ảnh chụp màn hình

> Thay các đường dẫn bên dưới bằng ảnh chụp màn hình của dự án. Có thể lưu ảnh trong thư mục `docs/screenshots/`.

| Menu đồ uống | Chi tiết đồ uống | Giỏ hàng |
|---|---|---|
| ![Menu đồ uống](docs/screenshots/menu.png) | ![Chi tiết đồ uống](docs/screenshots/drink-detail.png) | ![Giỏ hàng](docs/screenshots/cart.png) |

| Xác nhận đặt hàng | Trạng thái đơn hàng |
|---|---|
| ![Xác nhận đặt hàng](docs/screenshots/checkout.png) | ![Trạng thái đơn hàng](docs/screenshots/order-status.png) |

## ✨ Tính năng chính

- Xem danh sách đồ uống còn phục vụ, giá và mô tả.
- Tuỳ chỉnh size, lượng đường, lượng đá và số lượng.
- Thêm món vào giỏ hàng, cập nhật số lượng hoặc xoá món.
- Tạo đơn hàng với tên người nhận, số điện thoại và ghi chú.
- Theo dõi trạng thái đơn hàng; ứng dụng tự làm mới thông tin mỗi 15 giây.
- Nhận thông báo trên thiết bị về trạng thái đơn hàng.

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

Thực hiện lần lượt theo 3 bước sau. Các lệnh Flutter cần chạy từ thư mục `drink_app`, còn lệnh backend chạy từ `DrinkApi`.

### 1. Database

1. Khởi động SQL Server.
2. Mở file [`drinkDb.sql`](drinkDb.sql) bằng SSMS và thực thi toàn bộ script. Script tạo database `DrinkDb`, các bảng `Drinks`, `Orders`, `OrderItems` và một số dữ liệu đồ uống mẫu. Script **chạy lại nhiều lần vẫn an toàn**: chỉ tạo database/bảng khi chưa có, chỉ thêm món mẫu còn thiếu và không xoá dữ liệu đang có. File được lưu ở UTF-8 (có BOM) — giữ nguyên bảng mã này khi mở/sửa để tiếng Việt không bị lỗi.
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

## 📡 Danh sách API

Base URL mặc định: `http://localhost:5000` (khi gọi từ máy phát triển). Tất cả các endpoint bên dưới có tiền tố `/api`.

| Phương thức | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/drinks` | Lấy toàn bộ đồ uống, bao gồm cả món hết hàng. |
| `PATCH` | `/drinks/{id}/toggle-stock` 🔒 | Đảo trạng thái còn hàng/hết hàng cho đồ uống. |
| `GET` | `/orders` 🔒 | Lấy các đơn chưa hoàn thành hoặc chưa bị huỷ, mới tạo trước, kèm các món trong đơn. |
| `POST` | `/orders` | Tạo đơn hàng mới. |
| `GET` | `/orders/{id}` | Lấy thông tin đơn hàng và các món trong đơn. |
| `PATCH` | `/orders/{id}/status` 🔒 | Cập nhật trạng thái đơn hàng. |

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

## 👤 Tác giả

- **Tên:** `[Điền tên tác giả]`
- **Email/GitHub:** `[Điền thông tin liên hệ]`
