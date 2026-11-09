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
- Thanh toán trước qua cổng thanh toán; đơn chưa trả tiền trong 10 phút sẽ tự huỷ để tránh đơn ảo.
- Theo dõi trạng thái đơn hàng; ứng dụng tự làm mới thông tin mỗi 15 giây.
- Xem lại lịch sử các đơn đã đặt (lưu trên thiết bị, không cần đăng nhập).
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

### 5. Lịch sử đơn khi chưa có đăng nhập

Đồ án chưa có tài khoản khách hàng, nên đơn được lưu theo hai lớp:

- **Server là nguồn chính thức:** mỗi lần bấm *Xác nhận đặt hàng*, API tạo bản ghi trong `Orders`/`OrderItems` với mã đơn ngẫu nhiên (`ORD-...`), trạng thái `Pending`, tổng tiền và trạng thái thanh toán. Đơn nằm trong database vĩnh viễn, không phụ thuộc app; nhưng quán chỉ nhận đơn sau khi khách thanh toán (xem mục [Thanh toán trước](#6-thanh-toán-trước-và-chống-bom-đơn)).
- **Thiết bị dùng để khách tự xem lại:** app lưu tối đa 20 đơn gần nhất vào bộ nhớ máy (`shared_preferences`), gồm mã đơn, tổng tiền, số món, thời điểm và trạng thái gần nhất. Tab **Đơn** hiển thị danh sách này; mở một đơn sẽ lấy trạng thái mới nhất từ API rồi cập nhật lại danh sách, kéo xuống để làm mới tất cả.

Giới hạn: gỡ app hoặc xoá dữ liệu ứng dụng thì mất danh sách trên máy (đơn vẫn còn trên server, xem ở màn quản trị hoặc bảng `Orders`). Các đơn đặt trước khi có tính năng này cũng không xuất hiện trong danh sách máy.

### 6. Thanh toán trước và chống "bom" đơn

Vì app để khách đặt trước, quán chỉ nhận đơn khi khách đã trả tiền. Nếu cho trả khi nhận hàng, một người có thể tạo nhiều đơn ảo trong lúc quán đã pha chế xong.

Quy trình:

1. Khách bấm **Đặt hàng (demo)**: API tạo đơn với `PaymentStatus = Unpaid` và `PaymentExpiresAt = now + 10 phút` (đổi bằng `Payment:WindowMinutes` trong `appsettings.json`).
2. Ở màn hình chi tiết đơn, khách bấm **Xác nhận thanh toán demo** và xác nhận trong hộp thoại. Thao tác này chỉ mô phỏng thanh toán, không chuyển hay thu tiền thật.
3. App gọi `POST /api/orders/{id}/demo-payment/confirm`; server đặt `PaymentStatus = Paid`, `PaidAt = now`, sau đó app tải lại trạng thái đơn.
4. App tự kiểm tra trạng thái mỗi 15 giây, kèm đồng hồ đếm ngược thời gian giữ đơn.
5. Quá hạn mà chưa trả tiền: đơn tự chuyển `Cancelled` (kiểm tra ở mọi truy vấn đơn/danh sách), không vào hàng chờ pha chế, khách phải đặt lại.
6. `GET /api/orders` của màn nhân viên **chỉ trả đơn `Paid`**, nên đơn chưa trả tiền không chiếm chỗ trong hàng chờ.

Có thể dùng trang cổng giả lập `/pay/mock/{mã}` để mô phỏng luồng chuyển hướng riêng; không cần đăng ký merchant.

Muốn dùng cổng thật (VNPay sandbox): đăng ký tại `https://sandbox.vnpayment.vn/devreg` để nhận `vnp_TmnCode` và `vnp_HashSecret`, rồi thay luồng demo bằng URL có chữ ký HMAC-SHA512 (tham số sắp xếp tăng dần, `vnp_Amount` nhân 100), thêm endpoint nhận Return URL/IPN có kiểm tra chữ ký để đặt `PaymentStatus = Paid` và cập nhật app để mở cổng rồi tải lại trạng thái đơn. Không dùng endpoint xác nhận demo cho thanh toán thật.

Lưu ý: xác nhận thanh toán trong app và trang giả lập đều không có chữ ký/xác thực; chỉ dùng cho demo, không triển khai để thu tiền thật.

## 📡 Danh sách API

Base URL mặc định: `http://localhost:5000` (khi gọi từ máy phát triển). Các endpoint bên dưới có tiền tố `/api`, trừ các route `/pay/mock/...` của trang thanh toán giả lập.

| Phương thức | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/drinks` | Lấy toàn bộ đồ uống, bao gồm cả món hết hàng. |
| `PATCH` | `/drinks/{id}/toggle-stock` 🔒 | Đảo trạng thái còn hàng/hết hàng cho đồ uống. |
| `GET` | `/orders` 🔒 | Lấy các đơn **đã thanh toán**, chưa hoàn thành hoặc chưa bị huỷ, mới tạo trước, kèm các món trong đơn. |
| `POST` | `/orders` | Tạo đơn hàng mới (trạng thái chờ thanh toán, giữ đơn 10 phút). |
| `GET` | `/orders/{id}` | Lấy thông tin đơn hàng, các món và trạng thái thanh toán. |
| `POST` | `/orders/{id}/pay` | Tạo giao dịch thanh toán, trả `paymentUrl` và hạn giữ đơn mới. |
| `POST` | `/orders/{id}/demo-payment/confirm` | Xác nhận thanh toán giả lập trong app (không thu tiền thật). |
| `POST` | `/orders/{id}/cancel` | Khách tự huỷ đơn khi chưa thanh toán. |
| `PATCH` | `/orders/{id}/status` 🔒 | Cập nhật trạng thái đơn hàng. |
| `GET` | `/pay/mock/{mã}` | Trang cổng thanh toán giả lập (không có tiền tố `/api`). |
| `GET` | `/pay/mock/{mã}/confirm?ok=1` | Cổng giả lập báo kết quả thanh toán về server (`ok=0` là huỷ giao dịch). |

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
