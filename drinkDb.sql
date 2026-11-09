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
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
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

-- Chỉ thêm món mẫu chưa có (so khớp theo tên) nên chạy lại không bị nhân đôi.
INSERT INTO Drinks (Name, Description, Price, ImageUrl, IsAvailable)
SELECT v.Name, v.Description, v.Price, v.ImageUrl, v.IsAvailable
FROM (VALUES
    (N'Cà phê đen', N'Cà phê phin truyền thống', CAST(25000 AS DECIMAL(18,2)), 'https://i.imgur.com/1.jpg', CAST(1 AS BIT)),
    (N'Cà phê sữa', N'Cà phê sữa đá', CAST(30000 AS DECIMAL(18,2)), 'https://i.imgur.com/2.jpg', CAST(1 AS BIT)),
    (N'Trà sữa trân châu', N'Trà sữa trân châu đường đen', CAST(45000 AS DECIMAL(18,2)), 'https://i.imgur.com/3.jpg', CAST(1 AS BIT)),
    (N'Trà đào cam sả', N'Trà đào tươi mát', CAST(40000 AS DECIMAL(18,2)), 'https://i.imgur.com/4.jpg', CAST(1 AS BIT)),
    (N'Matcha latte', N'Matcha Nhật Bản', CAST(50000 AS DECIMAL(18,2)), 'https://i.imgur.com/5.jpg', CAST(1 AS BIT)),
    (N'Bạc xỉu', N'Bạc xỉu đá', CAST(30000 AS DECIMAL(18,2)), 'https://i.imgur.com/6.jpg', CAST(1 AS BIT)),
    (N'Sinh tố xoài', N'Sinh tố xoài tươi', CAST(45000 AS DECIMAL(18,2)), 'https://i.imgur.com/7.jpg', CAST(1 AS BIT)),
    (N'Nước cam', N'Cam vắt nguyên chất', CAST(35000 AS DECIMAL(18,2)), 'https://i.imgur.com/8.jpg', CAST(1 AS BIT)),
    (N'Trà xanh', N'Trà xanh Thái Nguyên', CAST(20000 AS DECIMAL(18,2)), 'https://i.imgur.com/9.jpg', CAST(1 AS BIT)),
    (N'Sữa chua đá', N'Sữa chua pha đá', CAST(25000 AS DECIMAL(18,2)), 'https://i.imgur.com/10.jpg', CAST(1 AS BIT))
) AS v(Name, Description, Price, ImageUrl, IsAvailable)
WHERE NOT EXISTS (SELECT 1 FROM Drinks d WHERE d.Name = v.Name);
GO

-- Kiểm tra nhanh sau khi chạy.
SELECT Id, Name, Price, IsAvailable FROM Drinks ORDER BY Id;
GO
