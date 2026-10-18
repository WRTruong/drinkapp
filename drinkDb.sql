CREATE DATABASE DrinkDb;
GO
USE DrinkDb;
GO

CREATE TABLE Drinks (
    Id INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    Price DECIMAL(18,2) NOT NULL,
    ImageUrl NVARCHAR(255),
    IsAvailable BIT NOT NULL DEFAULT 1
);

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


INSERT INTO Drinks (Name, Description, Price, ImageUrl, IsAvailable) VALUES
(N'Cà phê đen', N'Cà phê phin truyền thống', 25000, 'https://i.imgur.com/1.jpg', 1),
(N'Cà phê sữa', N'Cà phê sữa đá', 30000, 'https://i.imgur.com/2.jpg', 1),
(N'Trà sữa trân châu', N'Trà sữa trân châu đường đen', 45000, 'https://i.imgur.com/3.jpg', 1),
(N'Trà đào cam sả', N'Trà đào tươi mát', 40000, 'https://i.imgur.com/4.jpg', 1),
(N'Matcha latte', N'Matcha Nhật Bản', 50000, 'https://i.imgur.com/5.jpg', 1),
(N'Bạc xỉu', N'Bạc xỉu đá', 30000, 'https://i.imgur.com/6.jpg', 1),
(N'Sinh tố xoài', N'Sinh tố xoài tươi', 45000, 'https://i.imgur.com/7.jpg', 1),
(N'Nước cam', N'Cam vắt nguyên chất', 35000, 'https://i.imgur.com/8.jpg', 1),
(N'Trà xanh', N'Trà xanh Thái Nguyên', 20000, 'https://i.imgur.com/9.jpg', 1),
(N'Sữa chua đá', N'Sữa chua pha đá', 25000, 'https://i.imgur.com/10.jpg', 1);


USE DrinkDb;
SELECT * FROM Orders;
SELECT * FROM OrderItems;