# 🧋 Sổ tay sống còn khi bảo vệ đồ án Đặt đồ uống

Tài liệu này bám theo source hiện tại của dự án: Flutter, ASP.NET Core Web API và SQL Server. Mục tiêu không phải học vẹt từng dấu ngoặc, mà hiểu luồng dữ liệu để có thể viết lại và giải thích khi được hỏi.

## Sơ đồ luồng cần nhớ

```text
Menu Flutter
  -> ApiService.getDrinks()
  -> GET /api/drinks
  -> DrinksController
  -> SQL Server

Giỏ hàng Flutter
  -> ApiService.createOrder()
  -> POST /api/orders
  -> OrdersController kiểm tra món/giá/tồn kho
  -> Transaction + SaveChanges
  -> SQL Server

OrderStatusScreen
  -> GET /api/orders/{id} mỗi 15 giây
```

---

## Phần 1: Các đoạn code “tử huyệt” cần thuộc

### 1. Tạo đơn hàng — `DrinkApi/Controllers/OrdersController.cs`

Đây là phần backend quan trọng nhất: kiểm tra dữ liệu, đọc giá từ database, tính tổng, lưu đơn và các dòng chi tiết trong cùng một transaction.

```csharp
[HttpPost]
public async Task<IActionResult> Create(CreateOrderDto dto)
{
    if (string.IsNullOrWhiteSpace(dto.CustomerName) ||
        string.IsNullOrWhiteSpace(dto.Phone) ||
        dto.Items == null || dto.Items.Count == 0)
        return BadRequest(new { error = "Thiếu thông tin bắt buộc" });

    using var tx = await _db.Database.BeginTransactionAsync();
    try
    {
        var order = new Order
        {
            OrderCode = "ORD-" + DateTime.UtcNow.ToString("yyMMddHHmmss"),
            CustomerName = dto.CustomerName,
            Phone = dto.Phone,
            Note = dto.Note
        };

        foreach (var item in dto.Items)
        {
            var drink = await _db.Drinks.FindAsync(item.DrinkId);
            if (drink == null)
                return BadRequest(new { error = $"Không tìm thấy món #{item.DrinkId}" });
            if (!drink.IsAvailable)
                return BadRequest(new
                {
                    code = "DRINK_OUT_OF_STOCK",
                    error = $"Món \"{drink.Name}\" hiện đã tạm hết hàng."
                });
            if (item.Quantity <= 0)
                return BadRequest(new { error = "Số lượng phải > 0" });

            var line = new OrderItem
            {
                DrinkId = drink.Id,
                DrinkNameSnapshot = drink.Name,
                UnitPrice = drink.Price,
                Quantity = item.Quantity,
                Size = item.Size,
                SugarLevel = item.SugarLevel,
                IceLevel = item.IceLevel,
                LineTotal = drink.Price * item.Quantity
            };
            order.Items.Add(line);
            order.TotalAmount += line.LineTotal;
        }

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(new { order.Id, order.OrderCode, order.TotalAmount, order.Status });
    }
    catch
    {
        await tx.RollbackAsync();
        return StatusCode(500, new { error = "Lỗi tạo đơn" });
    }
}
```

**Giải thích theo từng đoạn**

- `[HttpPost]`: ánh xạ phương thức thành endpoint `POST /api/orders`.
- `CreateOrderDto dto`: ASP.NET Core đọc JSON request và binding thành DTO có kiểu rõ ràng.
- Kiểm tra tên, số điện thoại, danh sách món: từ chối dữ liệu thiếu trước khi ghi database.
- `BeginTransactionAsync()`: bắt đầu transaction để nhiều thao tác lưu được xem như một đơn vị.
- `await`: chờ tác vụ I/O database hoàn tất mà không chặn thread xử lý request trong lúc chờ.
- Tìm từng `Drink` trong database: không tin giá gửi từ app; backend lấy giá chuẩn từ database.
- Kiểm tra `IsAvailable` và `Quantity`: chặn đặt món hết hàng và số lượng không hợp lệ.
- `DrinkNameSnapshot` và `UnitPrice`: chụp lại tên/giá tại thời điểm đặt; nếu menu đổi sau này, chi tiết đơn cũ vẫn đúng lịch sử.
- `LineTotal` và `TotalAmount`: tính ở backend từ giá database nhân số lượng.
- `_db.Orders.Add(order)`: EF Core theo dõi order cùng các `Items` được gắn vào order.
- `SaveChangesAsync()`: gửi thay đổi tới SQL Server.
- `CommitAsync()`: xác nhận transaction sau khi lưu thành công.
- `RollbackAsync()`: hoàn tác nếu gặp exception để không để dữ liệu ghi dở.
- `BadRequest`: trả HTTP 400 cho dữ liệu hoặc món không hợp lệ; `Ok`: trả HTTP 200 khi tạo thành công.

**Từ khoá thần chú:** `[HttpPost]`, `CreateOrderDto`, `BeginTransactionAsync`, `FindAsync`, `IsAvailable`, `LineTotal`, `SaveChangesAsync`, `CommitAsync`, `RollbackAsync`.

> Source thật trả về thông báo hết hàng có `code = "DRINK_OUT_OF_STOCK"` cùng nội dung chi tiết. Một số server cũ có thể chỉ trả “Món không khả dụng”; Flutter hiện có xử lý tương thích thông báo cũ.

### 2. Gọi API tạo đơn — `drink_app/lib/services/api_service.dart`

```dart
Future<OrderResult> createOrder({
  required String customerName,
  required String phone,
  String? note,
  required List<Map<String, dynamic>> items,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/orders'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'customerName': customerName,
      'phone': phone,
      'note': note,
      'items': items,
    }),
  );

  if (res.statusCode != 200) {
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final message = decoded['error'] as String? ?? 'Đặt hàng thất bại';
    throw ApiException(message, code: decoded['code'] as String?);
  }

  return OrderResult.fromJson(
    jsonDecode(utf8.decode(res.bodyBytes)),
  );
}
```

**Giải thích**

- `Future<OrderResult>`: kết quả không có ngay; hàm trả về trong tương lai sau khi API phản hồi.
- `async/await`: viết luồng HTTP bất đồng bộ tuần tự, dễ đọc và không đóng băng giao diện.
- `Uri.parse(...)`: tạo URI request hoàn chỉnh từ base URL và route API.
- `Content-Type: application/json`: báo cho backend rằng body gửi lên là JSON.
- `jsonEncode(...)`: chuyển dữ liệu Dart thành chuỗi JSON để truyền qua HTTP.
- Không gửi giá từ client: backend tự tra giá chính thức trong database.
- `utf8.decode(res.bodyBytes)`: giải mã byte response theo UTF-8 để giữ nguyên tiếng Việt có dấu.
- Kiểm tra `statusCode`: không parse phản hồi lỗi như thể đó là đơn hàng thành công.
- `ApiException`: giữ cả thông báo và mã nghiệp vụ để checkout có thể phân biệt lỗi hết hàng.
- `OrderResult.fromJson`: chuyển JSON phản hồi thành model Dart.

**Từ khoá thần chú:** `Future`, `async`, `await`, `http.post`, `Uri.parse`, `Content-Type`, `jsonEncode`, `utf8.decode`, `statusCode`, `fromJson`.

> Đoạn trên là phiên bản rút gọn để học. Trong source, phần parse lỗi được viết có `try/catch FormatException` để xử lý cả response không phải JSON.

### 3. Quản lý giỏ hàng — `drink_app/lib/widgets/cart_store.dart`

```dart
class _CartNotifier extends ChangeNotifier {
  void cartChanged() => notifyListeners();
}

class CartStore {
  static final List<CartItem> items = [];
  static final _CartNotifier _notifier = _CartNotifier();

  static void addListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  static void removeListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  static double get total =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  static void add(CartItem item) {
    items.add(item);
    _notifier.cartChanged();
  }

  static void clear() {
    items.clear();
    _notifier.cartChanged();
  }
}
```

**Giải thích**

- `static`: giỏ dùng chung trong phiên chạy app, không cần truyền cùng một instance qua nhiều màn hình.
- `List<CartItem>`: chứa từng món cùng size, đường, đá và số lượng đã chọn.
- `ChangeNotifier`: phát tín hiệu cho widget đang quan tâm khi dữ liệu giỏ đổi.
- `_CartNotifier`: subclass để gọi `notifyListeners()` hợp lệ; method này được bảo vệ trong Flutter API.
- `addListener`/`removeListener`: cho màn hình Giỏ đăng ký và dọn listener đúng vòng đời.
- `fold`: cộng `lineTotal` của từng món để tính tổng tiền hiện tại.
- `add`/`clear`: thay đổi dữ liệu rồi thông báo UI dựng lại.

**Từ khoá thần chú:** `static List`, `ChangeNotifier`, `addListener`, `removeListener`, `notifyListeners`, `fold`, `lineTotal`, `setState`.

### 4. Hiển thị và cập nhật giỏ — `drink_app/lib/screens/cart_screen.dart`

```dart
@override
void initState() {
  super.initState();
  CartStore.addListener(_onCartChanged);
}

@override
void dispose() {
  CartStore.removeListener(_onCartChanged);
  super.dispose();
}

void _onCartChanged() {
  if (mounted) setState(() {});
}

@override
Widget build(BuildContext context) {
  final items = CartStore.items;
  return items.isEmpty
      ? const Center(child: Text('Giỏ hàng trống'))
      : ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.drink.name),
              subtitle: Text('${item.drink.price} đ × ${item.quantity}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => items.removeAt(index)),
              ),
            );
          },
        );
}
```

**Giải thích**

- `initState`: đăng ký lắng nghe một lần khi state được tạo.
- `dispose`: gỡ listener để tránh giữ tham chiếu đến widget đã bị huỷ.
- `mounted`: chỉ gọi `setState` khi widget còn tồn tại trong cây giao diện.
- `ListView.builder`: tạo từng dòng giỏ theo nhu cầu, phù hợp khi danh sách dài.
- `setState`: báo Flutter rằng dữ liệu hiển thị vừa đổi và cần build lại widget.

**Từ khoá thần chú:** `initState`, `addListener`, `dispose`, `removeListener`, `mounted`, `setState`, `ListView.builder`.

> Trong source hiện tại, thêm món và xoá giỏ phát notifier. Các nút tăng/giảm/xoá từng món trong `CartScreen` gọi `setState` cục bộ.

### 5. Theo dõi trạng thái đơn — `drink_app/lib/screens/order_status_screen.dart`

```dart
@override
void initState() {
  super.initState();
  _fetch();
  _timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => _fetch(),
  );
}

Future<void> _fetch() async {
  try {
    final order = await _api.getOrder(widget.orderId);
    if (!mounted) return;

    setState(() {
      _status = order.status;
      _total = order.totalAmount;
      _error = null;
    });

    if (order.status == 'Completed' || order.status == 'Cancelled') {
      await _notif.cancelOrder(widget.orderId);
      _timer?.cancel();
    } else {
      await _notif.showOrderStatus(
        orderId: widget.orderId,
        orderCode: widget.orderCode,
        status: order.status,
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = '$e');
  }
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

**Giải thích**

- `Timer.periodic`: gọi `_fetch()` định kỳ mỗi 15 giây để lấy trạng thái mới.
- `await _api.getOrder(...)`: chờ HTTP hoàn tất trước khi cập nhật giao diện.
- `mounted`: tránh gọi `setState` sau khi người dùng rời màn hình.
- Khi đơn hoàn tất/huỷ: huỷ notification và dừng timer để không gọi API vô ích.
- `dispose` + `_timer?.cancel()`: huỷ tài nguyên nền khi widget bị huỷ.
- App giữ tab đơn trong `IndexedStack`, vì vậy chuyển tab hoặc mở Admin không tự huỷ màn hình này.

**Từ khoá thần chú:** `Timer.periodic`, `Duration(seconds: 15)`, `_fetch`, `mounted`, `setState`, `dispose`, `cancel`.

### 6. Đăng ký database — `DrinkApi/Program.cs`

```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("Default")));

builder.Services.AddControllers();
app.MapControllers();
```

- `AddDbContext`: đăng ký `AppDbContext` vào dependency injection để controller nhận qua constructor.
- `UseSqlServer`: cấu hình Entity Framework Core sử dụng SQL Server.
- `GetConnectionString("Default")`: lấy chuỗi kết nối từ cấu hình, không viết connection string trực tiếp trong controller.
- `AddControllers`/`MapControllers`: đăng ký và ánh xạ các API controller.

**Từ khoá thần chú:** `AddDbContext`, `UseSqlServer`, `GetConnectionString`, `AddControllers`, `MapControllers`.

---

## Phần 2: Kịch bản “Giảng viên xoá code”

### “Nếu xoá `BeginTransactionAsync()` thì hậu quả?”

Transaction đảm bảo toàn bộ thao tác thuộc một đơn hàng đi cùng nhau: hoặc tất cả được lưu, hoặc không có phần nào được xác nhận.

Nếu không có transaction mà hệ thống thực hiện nhiều lần lưu riêng—ví dụ lưu Order trước, rồi lưu từng OrderItem—một lỗi giữa chừng có thể để lại đơn thiếu chi tiết hoặc dữ liệu không nhất quán. Trong source hiện tại, các entity được `SaveChangesAsync()` cùng lúc; EF Core thường tự bao một lần `SaveChanges` trong transaction. Tuy nhiên transaction tường minh vẫn hữu ích nếu sau này thêm nhiều lần lưu hoặc thao tác database bên ngoài `SaveChanges`.

**Trả lời dứt khoát:** “Em dùng transaction để bảo vệ tính toàn vẹn của đơn. Nếu có nhiều bước ghi và lỗi ở giữa, rollback giúp không để lại dữ liệu nửa chừng. Với một `SaveChanges` duy nhất, EF Core đã có transaction nội bộ, nhưng transaction tường minh giúp luồng nghiệp vụ rõ và an toàn khi mở rộng.”

### “Nếu xoá `.Where(d => d.IsAvailable)` trong `DrinksController` thì sao?”

Điều này phụ thuộc mục đích giao diện:

- **Trong phiên bản hiện tại, `GET /api/drinks` cố ý trả tất cả món** bằng `_db.Drinks.ToListAsync()`. Flutter cần biết món hết hàng để làm mờ và hiện nhãn “Hết hàng”.
- Nếu API trước đó có `.Where(d => d.IsAvailable)`, bỏ điều kiện sẽ làm món hết hàng xuất hiện trong response và menu có thể hiển thị trạng thái đó.
- Nếu giữ `.Where(d => d.IsAvailable)`, món hết hàng bị ẩn hoàn toàn; khách không thấy thông tin “Hết hàng”.
- Bỏ điều kiện lọc không làm món hết hàng đặt được: `OrdersController` vẫn kiểm tra `drink.IsAvailable` trước khi tạo đơn.

**Trả lời dứt khoát:** “Em đang trả tất cả món có trạng thái để khách thấy món hết hàng. Kiểm tra tồn kho lần cuối vẫn được backend thực hiện khi POST đơn.”

### “Nếu xoá `dispose()` chứa `_timer?.cancel()` thì sao?”

Timer có thể tiếp tục chạy sau khi màn hình không còn tồn tại, gọi API định kỳ và giữ callback tham chiếu tới state cũ. Hậu quả là lãng phí tài nguyên/mạng, rò rỉ bộ nhớ theo thời gian và nguy cơ thực hiện công việc không cần thiết. `mounted` chặn một số `setState` sai vòng đời nhưng **không thay thế việc huỷ Timer**.

**Trả lời dứt khoát:** “Em huỷ Timer trong `dispose` để giải phóng tài nguyên nền. Nếu chỉ kiểm tra `mounted`, timer vẫn tiếp tục đánh thức callback và gọi API.”

### “Đổi `setState` sang Provider như thế nào?”

`setState` phù hợp state cục bộ của một màn hình. Provider hữu ích khi state cần chia sẻ xuyên nhiều widget/màn hình, như giỏ hàng.

Các bước chuyển:

1. Tạo `CartProvider extends ChangeNotifier`, chuyển `items`, `total`, `add`, `remove`, `clear` vào provider.
2. Sau khi thay đổi danh sách, gọi `notifyListeners()`.
3. Bọc ứng dụng hoặc khu vực cần dùng bằng `ChangeNotifierProvider(create: (_) => CartProvider())`.
4. Đọc state bằng `context.watch<CartProvider>()` hoặc `Consumer<CartProvider>`.
5. Gọi lệnh thay đổi bằng `context.read<CartProvider>().add(item)`.
6. Bỏ listener thủ công và `setState` cho dữ liệu giỏ đã chuyển sang provider; state giao diện riêng vẫn có thể dùng `setState`.

Ví dụ ngắn:

```dart
class CartProvider extends ChangeNotifier {
  final List<CartItem> items = [];

  void add(CartItem item) {
    items.add(item);
    notifyListeners();
  }
}
```

Trong dự án hiện tại, giỏ dùng `CartStore` static + `ChangeNotifier` riêng để giữ thay đổi nhỏ, không phụ thuộc thư viện Provider. Không nên nói `ValueKey` là cơ chế đang cập nhật giỏ: source hiện tại cập nhật bằng listener và `setState`.

### “Nếu xoá kiểm tra `IsAvailable` ở backend?”

Flutter có thể đang giữ menu/giỏ cũ hoặc request được gửi trực tiếp. Nếu backend bỏ kiểm tra, khách vẫn có thể tạo đơn với món đã hết hàng. Quy tắc quan trọng phải được kiểm tra ở server, không chỉ dựa vào UI.

### “Nếu xoá `jsonEncode`?”

Body request sẽ không còn được serialize thành JSON đúng chuẩn. Backend không thể binding ổn định dữ liệu thành `CreateOrderDto`; có thể trả lỗi 400 hoặc không đọc được body.

### “Nếu xoá `await` khi lưu?”

Nếu không chờ thao tác database, code có thể trả response trước khi ghi xong, khó xử lý lỗi và transaction có thể bị đóng trước khi câu lệnh hoàn thành. Với API I/O, cần `await` để đảm bảo thứ tự nghiệp vụ và bắt lỗi đúng luồng.

---

## Phần 3: 10 câu hỏi “xoáy” về code

### 1. Tại sao `ApiService` dùng `10.0.2.2` thay vì `localhost`?

“App đang chạy trong Android Emulator. `localhost` bên trong emulator là chính emulator, không phải máy tính chạy backend. Android Emulator dùng `10.0.2.2` làm địa chỉ đặc biệt trỏ về loopback của máy host. Nếu chạy trên thiết bị thật, em thay bằng IP LAN của máy backend.”

### 2. Tại sao `CartStore` dùng `static List`? Nhược điểm là gì?

“`static` giúp các màn hình truy cập cùng một giỏ mà không phải truyền object qua nhiều route. Nhược điểm là đây là state toàn cục, khó cô lập khi test, không tự reactive nếu chỉ sửa List trực tiếp, và dữ liệu mất khi app bị đóng. Dự án bọc thao tác thêm/xoá bằng notifier để báo UI cập nhật. Cách mở rộng sạch hơn là Provider/Riverpod hoặc repository state.”

### 3. Khác biệt giữa `GET` và `PATCH` trong code?

“`GET` đọc tài nguyên, ví dụ lấy menu hoặc chi tiết đơn, không chủ đích sửa dữ liệu. `PATCH` cập nhật một phần tài nguyên; dự án dùng PATCH để đổi trạng thái đơn hoặc đảo trạng thái còn hàng của một món.”

### 4. Backend biết giá tiền để tính tổng bằng cách nào?

“Backend nhận `DrinkId` và số lượng, sau đó dùng `_db.Drinks.FindAsync(item.DrinkId)` lấy món và giá chuẩn trong SQL Server. Tổng dòng là `drink.Price * item.Quantity`; tổng đơn cộng các `LineTotal`. Em không tin giá do client gửi vì client có thể bị sửa.”

### 5. `jsonDecode(utf8.decode(res.bodyBytes))` dùng để làm gì?

“HTTP trả body dạng byte. `utf8.decode` chuyển byte UTF-8 thành chuỗi đúng, giữ tiếng Việt có dấu; `jsonDecode` parse chuỗi JSON thành Map/List Dart. Nếu giải mã sai encoding, ký tự tiếng Việt có thể bị lỗi.”

### 6. Tại sao dùng `async/await` cho API và database?

“HTTP và database là I/O có độ trễ. `async/await` cho phép chờ kết quả mà không chặn luồng giao diện hoặc thread xử lý trong lúc chờ. Nó cũng giúp kiểm tra lỗi bằng `try/catch` và giữ thứ tự các bước rõ ràng.”

### 7. Vì sao kiểm tra hết hàng ở backend nếu menu đã làm mờ và chặn nhấn?

“UI chỉ hỗ trợ trải nghiệm; nó không phải ranh giới tin cậy. Menu có thể cũ, request có thể được gửi từ phiên bản app khác hoặc gọi trực tiếp bằng Swagger. Backend kiểm tra `IsAvailable` tại thời điểm tạo đơn để bảo vệ quy tắc nghiệp vụ.”

### 8. Transaction giải quyết điều gì? Có phải `SaveChangesAsync` tự an toàn không?

“Một lần `SaveChangesAsync` của EF Core thường được thực hiện trong transaction nội bộ. Transaction tường minh giúp em điều khiển commit/rollback quanh luồng nghiệp vụ, đặc biệt nếu sau này có nhiều lần lưu hoặc thêm thao tác database khác. Với implementation hiện tại, Order và Items được lưu trong một lần `SaveChanges`.”

### 9. Tại sao phải huỷ Timer trong `dispose()`?

“Timer là công việc định kỳ ngoài vòng đời build của widget. Nếu không huỷ, callback tiếp tục chạy và gọi API sau khi màn hình đã biến mất. Huỷ Timer giải phóng tài nguyên; `mounted` chỉ là guard trước cập nhật UI, không dừng callback.”

### 10. Đơn hàng đổi trạng thái ở đâu và app thấy trạng thái mới thế nào?

“Nhân viên gọi `PATCH /api/orders/{id}/status`; backend kiểm tra trạng thái hợp lệ rồi lưu xuống database. `OrderStatusScreen` gọi `GET /api/orders/{id}` mỗi 15 giây, cập nhật UI và notification. Timer dừng khi đơn `Completed` hoặc `Cancelled`.”

---

## Bài tập ôn nhanh trước khi bảo vệ

1. Viết lại từ trí nhớ endpoint `POST /api/orders`: validate → transaction → tra món/giá → tính tổng → save → commit.
2. Viết lại lời gọi `http.post`: URI → header JSON → `jsonEncode` → kiểm tra status → parse model.
3. Giải thích bằng một câu vì sao giá phải lấy từ backend.
4. Chỉ ra nơi nào phát tín hiệu giỏ đổi và nơi nào lắng nghe.
5. Phân biệt lỗi do UI với kiểm tra nghiệp vụ bắt buộc ở server.
6. Mở Swagger và thử `GET /api/drinks`, `PATCH /api/drinks/{id}/toggle-stock`, `POST /api/orders`.

### File source tham khảo

- [OrdersController.cs](./DrinkApi/Controllers/OrdersController.cs)
- [DrinksController.cs](./DrinkApi/Controllers/DrinksController.cs)
- [Program.cs](./DrinkApi/Program.cs)
- [api_service.dart](./drink_app/lib/services/api_service.dart)
- [cart_store.dart](./drink_app/lib/widgets/cart_store.dart)
- [cart_screen.dart](./drink_app/lib/screens/cart_screen.dart)
- [order_status_screen.dart](./drink_app/lib/screens/order_status_screen.dart)
