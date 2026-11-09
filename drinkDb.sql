-- Khởi tạo cơ sở dữ liệu DrinkDb.
-- Có thể chạy lại nhiều lần: chỉ tạo database/bảng khi chưa tồn tại và
-- chỉ thêm món mẫu còn thiếu, không xoá dữ liệu đang có.

IF DB_ID(N'DrinkDb') IS NULL
BEGIN
    CREATE DATABASE DrinkDb;
END
GO

USE DrinkDb;
GO

IF OBJECT_ID(N'dbo.Drinks', N'U') IS NULL
BEGIN
    CREATE TABLE Drinks (
        Id INT IDENTITY PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(255),
        Price DECIMAL(18,2) NOT NULL,
        ImageUrl NVARCHAR(255),
        IsAvailable BIT NOT NULL DEFAULT 1
    );
END
GO

IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE Orders (
        Id INT IDENTITY PRIMARY KEY,
        OrderCode NVARCHAR(20) NOT NULL UNIQUE,
        CustomerName NVARCHAR(100) NOT NULL,
        Phone NVARCHAR(20) NOT NULL,
        Note NVARCHAR(255),
        TotalAmount DECIMAL(18,2) NOT NULL,
        Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        PaymentMethod NVARCHAR(20) NOT NULL DEFAULT 'Online',
        PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'Unpaid',
        PaymentRef NVARCHAR(50),
        PaymentExpiresAt DATETIME2,
        PaidAt DATETIME2
    );
END
GO

-- Bổ sung cột thanh toán cho database đã tạo từ phiên bản trước.
IF COL_LENGTH('dbo.Orders', 'PaymentStatus') IS NULL
BEGIN
    ALTER TABLE dbo.Orders ADD
        PaymentMethod NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Orders_PaymentMethod DEFAULT 'Online',
        PaymentStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Orders_PaymentStatus DEFAULT 'Unpaid',
        PaymentRef NVARCHAR(50),
        PaymentExpiresAt DATETIME2,
        PaidAt DATETIME2;

    -- Đơn có sẵn trước khi có thanh toán online được coi như đã thu tiền tại quầy.
    -- Dùng EXEC để SQL Server biên dịch sau khi cột vừa được thêm trong cùng batch.
    EXEC(N'UPDATE dbo.Orders SET PaymentStatus = ''Paid'', PaidAt = CreatedAt;');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Orders_PaymentStatus' AND object_id = OBJECT_ID(N'dbo.Orders'))
    CREATE INDEX IX_Orders_PaymentStatus ON dbo.Orders (PaymentStatus, CreatedAt);
GO

IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
BEGIN
    CREATE TABLE OrderItems (
        Id INT IDENTITY PRIMARY KEY,
        OrderId INT NOT NULL FOREIGN KEY REFERENCES Orders(Id),
        DrinkId INT NOT NULL FOREIGN KEY REFERENCES Drinks(Id),
        DrinkNameSnapshot NVARCHAR(100) NOT NULL,
        UnitPrice DECIMAL(18,2) NOT NULL,
        Quantity INT NOT NULL,
        Size NVARCHAR(10),
        SugarLevel NVARCHAR(10),
        IceLevel NVARCHAR(10),
        LineTotal DECIMAL(18,2) NOT NULL
    );
END
GO

-- Dữ liệu mẫu. Ảnh món lưu trong DrinkApi/wwwroot/images (nguồn: Wikimedia Commons, CC)
-- và API phục vụ tại /images/<tên>.jpg nên app không phụ thuộc mạng ngoài.
DECLARE @SeedDrinks TABLE (
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255) NULL,
    Price DECIMAL(18,2) NOT NULL,
    ImageUrl NVARCHAR(255) NULL,
    IsAvailable BIT NOT NULL
);

INSERT INTO @SeedDrinks (Name, Description, Price, ImageUrl, IsAvailable) VALUES
    (N'Cà phê đen', N'Cà phê phin truyền thống', 25000, '/images/ca-phe-den.jpg', 1),
    (N'Cà phê sữa', N'Cà phê sữa đá', 30000, '/images/ca-phe-sua.jpg', 1),
    (N'Trà sữa trân châu', N'Trà sữa trân châu đường đen', 45000, '/images/tra-sua-tran-chau.jpg', 1),
    (N'Trà đào cam sả', N'Trà đào tươi mát', 40000, '/images/tra-dao-cam-sa.jpg', 1),
    (N'Matcha latte', N'Matcha Nhật Bản', 50000, '/images/matcha-latte.jpg', 1),
    (N'Bạc xỉu', N'Bạc xỉu đá', 30000, '/images/bac-xiu.jpg', 1),
    (N'Sinh tố xoài', N'Sinh tố xoài tươi', 45000, '/images/sinh-to-xoai.jpg', 1),
    (N'Nước cam', N'Cam vắt nguyên chất', 35000, '/images/nuoc-cam.jpg', 1),
    (N'Trà xanh', N'Trà xanh Thái Nguyên', 20000, '/images/tra-xanh.jpg', 1),
    (N'Sữa chua đá', N'Sữa chua pha đá', 25000, '/images/sua-chua-da.jpg', 1);

-- Chỉ thêm món mẫu còn thiếu (so khớp theo tên) nên chạy lại không bị nhân đôi.
INSERT INTO Drinks (Name, Description, Price, ImageUrl, IsAvailable)
SELECT s.Name, s.Description, s.Price, s.ImageUrl, s.IsAvailable
FROM @SeedDrinks s
WHERE NOT EXISTS (SELECT 1 FROM Drinks d WHERE d.Name = s.Name);

-- Với database đã tạo trước đây, thay link ảnh imgur (giả) và link ảnh ngoài
-- bằng ảnh nội bộ; ảnh do người dùng tự nhập thì giữ nguyên.
UPDATE d
SET d.ImageUrl = s.ImageUrl
FROM Drinks d
JOIN @SeedDrinks s ON s.Name = d.Name
WHERE d.ImageUrl IS NULL
   OR d.ImageUrl LIKE 'https://i.imgur.com/%'
   OR d.ImageUrl LIKE 'https://upload.wikimedia.org/%';
GO

-- Kiểm tra nhanh sau khi chạy.
SELECT Id, Name, Price, IsAvailable FROM Drinks ORDER BY Id;
GO
