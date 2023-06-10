-- ایجاد دیتابیس جدید
CREATE DATABASE CafeteriaDB;
GO

-- استفاده از دیتابیس ساخته شده
USE CafeteriaDB;
GO

-- جدول دانشجویان
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Department NVARCHAR(50)
);
GO

-- جدول منوی غذا
CREATE TABLE Menu (
    MenuItemID INT PRIMARY KEY,
    MenuItemName NVARCHAR(50),
    Price DECIMAL(10, 2),
    AvailableDate DATE
);
GO

-- جدول سفارشات
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    StudentID INT,
    MenuItemID INT,
    OrderDate DATETIME,
    CONSTRAINT FK_Orders_Students FOREIGN KEY (StudentID)
        REFERENCES Students (StudentID),
    CONSTRAINT FK_Orders_Menu FOREIGN KEY (MenuItemID)
        REFERENCES Menu (MenuItemID)
);
GO


-- ایجاد دانشجو جدید
CREATE PROCEDURE AddStudent
    @StudentID INT,
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Department NVARCHAR(50)
AS
BEGIN
    INSERT INTO Students (StudentID, FirstName, LastName, Department)
    VALUES (@StudentID, @FirstName, @LastName, @Department);
END
GO;
-- ایجاد غذای جدید در منو
CREATE PROCEDURE AddMenuItem
    @MenuItemID INT,
    @MenuItemName NVARCHAR(50),
    @Price DECIMAL(10, 2),
    @AvailableDate DATE
AS
BEGIN
    INSERT INTO Menu (MenuItemID, MenuItemName, Price, AvailableDate)
    VALUES (@MenuItemID, @MenuItemName, @Price, @AvailableDate);
END
GO;
-- ثبت سفارش جدید
CREATE PROCEDURE PlaceOrder
    @OrderID INT,
    @StudentID INT,
    @MenuItemID INT,
    @OrderDate DATETIME
AS
BEGIN
    INSERT INTO Orders (OrderID, StudentID, MenuItemID, OrderDate)
    VALUES (@OrderID, @StudentID, @MenuItemID, @OrderDate);
END
GO;
-- دریافت لیست دانشجویان
CREATE PROCEDURE GetStudents
AS
BEGIN
    SELECT * FROM Students;
END
GO;
-- دریافت لیست منوی غذا
CREATE PROCEDURE GetMenu
AS
BEGIN
    SELECT * FROM Menu;
END
GO;
-- دریافت جزئیات سفارش بر اساس شناسه سفارش
CREATE PROCEDURE GetOrderDetailsByID
    @OrderID INT
AS
BEGIN
    SELECT *
    FROM Orders
    WHERE OrderID = @OrderID;
END
GO;
-- دریافت سفارشات یک دانشجو بر اساس شناسه دانشجو
CREATE PROCEDURE GetOrdersByStudentID
    @StudentID INT
AS
BEGIN
    SELECT *
    FROM Orders
    WHERE StudentID = @StudentID;
END
GO;
-- به‌روزرسانی اطلاعات دانشجو بر اساس شناسه دانشجو
CREATE PROCEDURE UpdateStudent
    @StudentID INT,
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Department NVARCHAR(50)
AS
BEGIN
    UPDATE Students
    SET FirstName = @FirstName,
        LastName = @LastName,
        Department = @Department
    WHERE StudentID = @StudentID;
END
GO;
-- حذف یک سفارش بر اساس شناسه سفارش
CREATE PROCEDURE DeleteOrder
    @OrderID INT
AS
BEGIN
    DELETE FROM Orders
    WHERE OrderID = @OrderID;
END
GO;
-- حذف یک دانشجو بر اساس شناسه دانشجو
CREATE PROCEDURE DeleteStudent
    @StudentID INT
AS
BEGIN
    DELETE FROM Students
    WHERE StudentID = @StudentID;
END
GO;
-- ایجاد View برای نمایش لیست دانشجویانی که سفارش داده‌اند
CREATE VIEW View_StudentOrders AS
SELECT Students.StudentID, Students.FirstName, Students.LastName, Orders.OrderID, Orders.MenuItemID, Orders.OrderDate
FROM Students
INNER JOIN Orders ON Students.StudentID = Orders.StudentID;
GO;
-- ایجاد View برای نمایش جزئیات سفارشات هر دانشجو
CREATE VIEW View_OrderDetails AS
SELECT Students.StudentID, Students.FirstName, Students.LastName, Orders.OrderID, Orders.MenuItemID, Menu.MenuItemName, Menu.Price, Orders.OrderDate
FROM Students
INNER JOIN Orders ON Students.StudentID = Orders.StudentID
INNER JOIN Menu ON Orders.MenuItemID = Menu.MenuItemID;

-- ایجاد View برای نمایش لیست منوی غذا با تعداد سفارش هر غذا
CREATE VIEW View_MenuOrderCount AS
SELECT Menu.MenuItemID, Menu.MenuItemName, COUNT(Orders.OrderID) AS OrderCount
FROM Menu
LEFT JOIN Orders ON Menu.MenuItemID = Orders.MenuItemID
GROUP BY Menu.MenuItemID, Menu.MenuItemName;
GO;
-- ایجاد View برای نمایش لیست دانشجویانی که هنوز سفارش نداده‌اند
CREATE VIEW View_StudentsWithoutOrders AS
SELECT Students.StudentID, Students.FirstName, Students.LastName, Students.Department
FROM Students
LEFT JOIN Orders ON Students.StudentID = Orders.StudentID
WHERE Orders.OrderID IS NULL;
GO;
-- ایجاد View برای نمایش تعداد سفارشات هر دانشجو
CREATE VIEW View_StudentOrderCount AS
SELECT Students.StudentID, Students.FirstName, Students.LastName, COUNT(Orders.OrderID) AS OrderCount
FROM Students
LEFT JOIN Orders ON Students.StudentID = Orders.StudentID
GROUP BY Students.StudentID, Students.FirstName, Students.LastName;


GO;

-- ایجاد Trigger برای بروزرسانی قیمت کل سفارش هنگام درج سفارش جدید
CREATE TRIGGER UpdateTotalPrice
ON Orders
AFTER INSERT
AS
BEGIN
    UPDATE Orders
    SET TotalPrice = Menu.Price * INSERTED.Quantity
    FROM Orders
    INNER JOIN INSERTED ON Orders.OrderID = INSERTED.OrderID
    INNER JOIN Menu ON Orders.MenuItemID = Menu.MenuItemID;
END;
GO;
-- ایجاد Trigger برای حذف سفارشات یک دانشجو در صورت حذف دانشجو
CREATE TRIGGER DeleteStudentOrders
ON Students
AFTER DELETE
AS
BEGIN
    DELETE FROM Orders
    WHERE StudentID IN (SELECT StudentID FROM DELETED);
END;

GO;
-- ایجاد Trigger برای به‌روزرسانی تعداد سفارشات هر دانشجو هنگام درج یا حذف سفارش
CREATE TRIGGER UpdateStudentOrderCount
ON Orders
AFTER INSERT, DELETE
AS
BEGIN
    UPDATE Students
    SET OrderCount = (SELECT COUNT(OrderID) FROM Orders WHERE Orders.StudentID = Students.StudentID)
    FROM Students
    INNER JOIN INSERTED ON Students.StudentID = INSERTED.StudentID
    INNER JOIN DELETED ON Students.StudentID = DELETED.StudentID;
END;
GO;
CREATE TRIGGER UpdateStudentOrderCountOnDelete
ON Orders
AFTER DELETE
AS
BEGIN
    DECLARE @StudentID INT;
    SELECT @StudentID = DELETED.StudentID
    FROM DELETED;
    
    UPDATE Students
    SET OrderCount = (SELECT COUNT(OrderID) FROM Orders WHERE Orders.StudentID = @StudentID)
    WHERE StudentID = @StudentID;
END;

GO;
-- ایجاد Trigger برای اعتبارسنجی تعداد سفارشات یک دانشجو هنگام درج سفارش جدید
CREATE TRIGGER ValidateStudentOrderCount
ON Orders
AFTER INSERT
AS
BEGIN
    DECLARE @StudentID INT;
    SELECT @StudentID = INSERTED.StudentID
    FROM INSERTED;
    
    IF (SELECT COUNT(OrderID) FROM Orders WHERE Orders.StudentID = @StudentID) > 5
    BEGIN
        RAISERROR ('تعداد سفارشات این دانشجو بیش از 5 است.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;


