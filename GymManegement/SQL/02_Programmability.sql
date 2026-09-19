-- ============================================================
-- FILE: 02_Programmability.sql
-- Mô tả: Stored Procedures, Functions, Views cho GymDb
-- Chạy sau 01_Schema.sql. An toàn khi chạy lại (CREATE OR ALTER).
-- ============================================================

USE GymDb;
GO

-- ============================================================
-- SCALAR FUNCTION: fn_GetDaysRemaining
-- Tính số ngày còn lại của gói tập
-- ============================================================
CREATE OR ALTER FUNCTION dbo.fn_GetDaysRemaining(@EndDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT = DATEDIFF(DAY, GETDATE(), @EndDate);
    RETURN CASE WHEN @Days < 0 THEN 0 ELSE @Days END;
END;
GO

-- ============================================================
-- VIEW: vw_MemberDashboard
-- Dashboard tổng hợp cho từng hội viên
-- ============================================================
CREATE OR ALTER VIEW dbo.vw_MemberDashboard AS
    SELECT
        m.MemberId,
        m.FullName,
        m.Email,
        m.Phone,
        m.Status,
        m.QRCodeValue,
        ms.MembershipId,
        ms.MembershipType,
        ms.StartDate,
        ms.EndDate,
        ms.IsActive                                         AS MembershipActive,
        dbo.fn_GetDaysRemaining(ms.EndDate)                 AS DaysRemaining,
        (SELECT COUNT(*) FROM Checkins c WHERE c.MemberId = m.MemberId) AS TotalCheckins,
        (SELECT COUNT(*) FROM Invoices i WHERE i.MemberId = m.MemberId AND i.Status = 'Pending') AS PendingInvoices
    FROM Members m
    LEFT JOIN Memberships ms ON ms.MemberId = m.MemberId
        AND ms.IsActive = 1
        AND ms.EndDate >= CAST(GETDATE() AS DATE);
GO

-- ============================================================
-- ── MEMBER STORED PROCEDURES ─────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members
    ORDER BY FullName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetById
    @MemberId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE MemberId = @MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetByEmail
    @Email NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE Email = @Email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetByQRCode
    @QRCodeValue NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE QRCodeValue = @QRCodeValue;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetByStatus
    @Status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE Status = @Status ORDER BY FullName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Create
    @FullName       NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Email          NVARCHAR(150),
    @DateOfBirth    DATE,
    @JoinDate       DATE,
    @Status         NVARCHAR(20),
    @QRCodeValue    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Members (FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue)
    VALUES (@FullName, @Phone, @Email, @DateOfBirth, @JoinDate, @Status, @QRCodeValue);
    SELECT SCOPE_IDENTITY() AS MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Update
    @MemberId       INT,
    @FullName       NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Email          NVARCHAR(150),
    @DateOfBirth    DATE,
    @Status         NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Members
    SET FullName = @FullName, Phone = @Phone, Email = @Email,
        DateOfBirth = @DateOfBirth, Status = @Status
    WHERE MemberId = @MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Delete
    @MemberId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Members WHERE MemberId = @MemberId;
END;
GO

-- ============================================================
-- ── TRAINER STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT TrainerId, FullName, Phone, Email, Specialization FROM Trainers ORDER BY FullName;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Trainer_GetById @TrainerId INT
AS BEGIN SET NOCOUNT ON;
    SELECT TrainerId, FullName, Phone, Email, Specialization FROM Trainers WHERE TrainerId = @TrainerId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Trainer_Create
    @FullName NVARCHAR(100), @Phone NVARCHAR(20), @Email NVARCHAR(150), @Specialization NVARCHAR(100)
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Trainers (FullName, Phone, Email, Specialization)
    VALUES (@FullName, @Phone, @Email, @Specialization);
    SELECT SCOPE_IDENTITY() AS TrainerId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Trainer_Update
    @TrainerId INT, @FullName NVARCHAR(100), @Phone NVARCHAR(20), @Email NVARCHAR(150), @Specialization NVARCHAR(100)
AS BEGIN SET NOCOUNT ON;
    UPDATE Trainers SET FullName=@FullName, Phone=@Phone, Email=@Email, Specialization=@Specialization
    WHERE TrainerId = @TrainerId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Trainer_Delete @TrainerId INT
AS BEGIN SET NOCOUNT ON; DELETE FROM Trainers WHERE TrainerId = @TrainerId; END;
GO

-- ============================================================
-- ── FACILITY STORED PROCEDURES ───────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT FacilityId, Name, Description, IsActive FROM Facilities ORDER BY Name;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetById @FacilityId INT
AS BEGIN SET NOCOUNT ON;
    SELECT FacilityId, Name, Description, IsActive FROM Facilities WHERE FacilityId = @FacilityId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetActive
AS BEGIN SET NOCOUNT ON;
    SELECT FacilityId, Name, Description, IsActive FROM Facilities WHERE IsActive = 1 ORDER BY Name;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Facility_Create
    @Name NVARCHAR(100), @Description NVARCHAR(500), @IsActive BIT
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Facilities (Name, Description, IsActive) VALUES (@Name, @Description, @IsActive);
    SELECT SCOPE_IDENTITY() AS FacilityId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Facility_Update
    @FacilityId INT, @Name NVARCHAR(100), @Description NVARCHAR(500), @IsActive BIT
AS BEGIN SET NOCOUNT ON;
    UPDATE Facilities SET Name=@Name, Description=@Description, IsActive=@IsActive WHERE FacilityId = @FacilityId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Facility_Delete @FacilityId INT
AS BEGIN SET NOCOUNT ON; DELETE FROM Facilities WHERE FacilityId = @FacilityId; END;
GO

-- ============================================================
-- ── MEMBERSHIP STORED PROCEDURES ─────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetByMember @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive
    FROM Memberships WHERE MemberId = @MemberId ORDER BY StartDate DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetById @MembershipId INT
AS BEGIN SET NOCOUNT ON;
    SELECT MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive
    FROM Memberships WHERE MembershipId = @MembershipId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetActive @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive
    FROM Memberships
    WHERE MemberId = @MemberId AND IsActive = 1 AND EndDate >= CAST(GETDATE() AS DATE)
    ORDER BY EndDate DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetExpiringSoon @DaysAhead INT = 7
AS BEGIN SET NOCOUNT ON;
    SELECT ms.MembershipId, ms.MemberId, m.FullName, m.Email, ms.MembershipType,
           ms.EndDate, dbo.fn_GetDaysRemaining(ms.EndDate) AS DaysRemaining
    FROM Memberships ms
    INNER JOIN Members m ON m.MemberId = ms.MemberId
    WHERE ms.IsActive = 1
      AND ms.EndDate >= CAST(GETDATE() AS DATE)
      AND ms.EndDate <= DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE))
    ORDER BY ms.EndDate;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Membership_Create
    @MemberId INT, @MembershipType NVARCHAR(50), @Price DECIMAL(18,2), @StartDate DATE, @EndDate DATE
AS BEGIN SET NOCOUNT ON;
    -- Deactivate previous memberships
    UPDATE Memberships SET IsActive = 0 WHERE MemberId = @MemberId AND IsActive = 1;
    INSERT INTO Memberships (MemberId, MembershipType, Price, StartDate, EndDate, IsActive)
    VALUES (@MemberId, @MembershipType, @Price, @StartDate, @EndDate, 1);
    SELECT SCOPE_IDENTITY() AS MembershipId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Membership_Update
    @MembershipId INT, @MembershipType NVARCHAR(50), @Price DECIMAL(18,2),
    @StartDate DATE, @EndDate DATE, @IsActive BIT
AS BEGIN SET NOCOUNT ON;
    UPDATE Memberships SET MembershipType=@MembershipType, Price=@Price,
        StartDate=@StartDate, EndDate=@EndDate, IsActive=@IsActive
    WHERE MembershipId = @MembershipId;
END;
GO

-- ============================================================
-- ── SCHEDULE STORED PROCEDURES ───────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT s.ScheduleId, s.MemberId, m.FullName AS MemberName,
           s.TrainerId, t.FullName AS TrainerName,
           s.FacilityId, f.Name AS FacilityName, s.StartTime, s.EndTime
    FROM Schedules s
    JOIN Members m ON m.MemberId = s.MemberId
    JOIN Trainers t ON t.TrainerId = s.TrainerId
    JOIN Facilities f ON f.FacilityId = s.FacilityId
    ORDER BY s.StartTime DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Schedule_GetById @ScheduleId INT
AS BEGIN SET NOCOUNT ON;
    SELECT s.ScheduleId, s.MemberId, m.FullName AS MemberName,
           s.TrainerId, t.FullName AS TrainerName,
           s.FacilityId, f.Name AS FacilityName, s.StartTime, s.EndTime
    FROM Schedules s
    JOIN Members m ON m.MemberId = s.MemberId
    JOIN Trainers t ON t.TrainerId = s.TrainerId
    JOIN Facilities f ON f.FacilityId = s.FacilityId
    WHERE s.ScheduleId = @ScheduleId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Schedule_CheckConflict
    @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2, @ExcludeId INT = 0
AS BEGIN SET NOCOUNT ON;
    SELECT COUNT(*) AS ConflictCount FROM Schedules
    WHERE (TrainerId = @TrainerId OR FacilityId = @FacilityId)
      AND ScheduleId <> @ExcludeId
      AND StartTime < @EndTime AND EndTime > @StartTime;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Schedule_Create
    @MemberId INT, @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Schedules (MemberId, TrainerId, FacilityId, StartTime, EndTime)
    VALUES (@MemberId, @TrainerId, @FacilityId, @StartTime, @EndTime);
    SELECT SCOPE_IDENTITY() AS ScheduleId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Schedule_Update
    @ScheduleId INT, @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2
AS BEGIN SET NOCOUNT ON;
    UPDATE Schedules SET TrainerId=@TrainerId, FacilityId=@FacilityId,
        StartTime=@StartTime, EndTime=@EndTime WHERE ScheduleId = @ScheduleId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Schedule_Delete @ScheduleId INT
AS BEGIN SET NOCOUNT ON; DELETE FROM Schedules WHERE ScheduleId = @ScheduleId; END;
GO

-- ============================================================
-- ── SESSION STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Session_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT SessionId, ScheduleId, SessionDate, Status FROM Sessions ORDER BY SessionDate DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Session_GetById @SessionId INT
AS BEGIN SET NOCOUNT ON;
    SELECT SessionId, ScheduleId, SessionDate, Status FROM Sessions WHERE SessionId = @SessionId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Session_GetBySchedule @ScheduleId INT
AS BEGIN SET NOCOUNT ON;
    SELECT SessionId, ScheduleId, SessionDate, Status FROM Sessions WHERE ScheduleId = @ScheduleId ORDER BY SessionDate;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Session_Create
    @ScheduleId INT, @SessionDate DATE, @Status NVARCHAR(30)
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Sessions (ScheduleId, SessionDate, Status) VALUES (@ScheduleId, @SessionDate, @Status);
    SELECT SCOPE_IDENTITY() AS SessionId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Session_UpdateStatus @SessionId INT, @Status NVARCHAR(30)
AS BEGIN SET NOCOUNT ON;
    UPDATE Sessions SET Status = @Status WHERE SessionId = @SessionId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Session_Delete @SessionId INT
AS BEGIN SET NOCOUNT ON; DELETE FROM Sessions WHERE SessionId = @SessionId; END;
GO

-- ============================================================
-- ── CHECKIN STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT c.CheckinId, c.MemberId, m.FullName AS MemberName,
           c.SessionId, c.CheckinTime, c.CheckinMethod
    FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId
    ORDER BY c.CheckinTime DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetById @CheckinId INT
AS BEGIN SET NOCOUNT ON;
    SELECT c.CheckinId, c.MemberId, m.FullName AS MemberName,
           c.SessionId, c.CheckinTime, c.CheckinMethod
    FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId
    WHERE c.CheckinId = @CheckinId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetByMember @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod
    FROM Checkins WHERE MemberId = @MemberId ORDER BY CheckinTime DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetByDateRange @From DATETIME2, @To DATETIME2
AS BEGIN SET NOCOUNT ON;
    SELECT c.CheckinId, c.MemberId, m.FullName AS MemberName,
           c.SessionId, c.CheckinTime, c.CheckinMethod
    FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId
    WHERE c.CheckinTime BETWEEN @From AND @To ORDER BY c.CheckinTime DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_Create
    @MemberId INT, @SessionId INT, @CheckinTime DATETIME2, @CheckinMethod NVARCHAR(50)
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Checkins (MemberId, SessionId, CheckinTime, CheckinMethod)
    VALUES (@MemberId, @SessionId, @CheckinTime, @CheckinMethod);
    SELECT SCOPE_IDENTITY() AS CheckinId;
END;
GO
-- Check-in bằng QR: tìm member qua QR rồi checkin
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_ByQRCode
    @QRCodeValue NVARCHAR(50), @SessionId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MemberId INT;
    DECLARE @MemberStatus NVARCHAR(20);
    DECLARE @HasActiveMembership BIT = 0;

    -- Tìm member theo QR
    SELECT @MemberId = MemberId, @MemberStatus = Status
    FROM Members WHERE QRCodeValue = @QRCodeValue;

    IF @MemberId IS NULL
    BEGIN
        SELECT -1 AS CheckinId, N'Không tìm thấy hội viên' AS Message; RETURN;
    END

    IF @MemberStatus <> 'Active'
    BEGIN
        SELECT -2 AS CheckinId, N'Hội viên không ở trạng thái Active' AS Message; RETURN;
    END

    -- Kiểm tra membership còn hạn
    IF EXISTS (
        SELECT 1 FROM Memberships
        WHERE MemberId = @MemberId AND IsActive = 1 AND EndDate >= CAST(GETDATE() AS DATE)
    )
        SET @HasActiveMembership = 1;

    IF @HasActiveMembership = 0
    BEGIN
        SELECT -3 AS CheckinId, N'Hội viên hết hạn gói tập' AS Message; RETURN;
    END

    -- Thực hiện check-in
    INSERT INTO Checkins (MemberId, SessionId, CheckinTime, CheckinMethod)
    VALUES (@MemberId, @SessionId, GETDATE(), 'QRCode');

    SELECT SCOPE_IDENTITY() AS CheckinId, N'Check-in thành công' AS Message;
END;
GO

-- ============================================================
-- ── INVOICE STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetAll
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status
    FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId
    ORDER BY i.InvoiceDate DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetById @InvoiceId INT
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status
    FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId
    WHERE i.InvoiceId = @InvoiceId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetByMember @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status
    FROM Invoices WHERE MemberId = @MemberId ORDER BY InvoiceDate DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetOverdue
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status
    FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId
    WHERE i.Status = 'Pending' AND i.DueDate < CAST(GETDATE() AS DATE)
    ORDER BY i.DueDate;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Invoice_Create
    @MemberId INT, @TotalAmount DECIMAL(18,2), @InvoiceDate DATE, @DueDate DATE
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Invoices (MemberId, TotalAmount, InvoiceDate, DueDate, Status)
    VALUES (@MemberId, @TotalAmount, @InvoiceDate, @DueDate, 'Pending');
    SELECT SCOPE_IDENTITY() AS InvoiceId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Invoice_UpdateStatus @InvoiceId INT, @Status NVARCHAR(30)
AS BEGIN SET NOCOUNT ON;
    UPDATE Invoices SET Status = @Status WHERE InvoiceId = @InvoiceId;
END;
GO

-- ============================================================
-- ── PAYMENT STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Payment_GetByInvoice @InvoiceId INT
AS BEGIN SET NOCOUNT ON;
    SELECT PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status
    FROM Payments WHERE InvoiceId = @InvoiceId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Payment_GetById @PaymentId INT
AS BEGIN SET NOCOUNT ON;
    SELECT PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status
    FROM Payments WHERE PaymentId = @PaymentId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Payment_Create
    @InvoiceId INT, @Amount DECIMAL(18,2), @PaymentDate DATETIME2, @PaymentMethod NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Payments (InvoiceId, Amount, PaymentDate, PaymentMethod, Status)
    VALUES (@InvoiceId, @Amount, @PaymentDate, @PaymentMethod, 'Completed');
    -- Cập nhật invoice thành Paid
    UPDATE Invoices SET Status = 'Paid' WHERE InvoiceId = @InvoiceId;
    SELECT SCOPE_IDENTITY() AS PaymentId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Payment_UpdateStatus @PaymentId INT, @Status NVARCHAR(30)
AS BEGIN SET NOCOUNT ON;
    UPDATE Payments SET Status = @Status WHERE PaymentId = @PaymentId;
END;
GO

-- ============================================================
-- ── REPORT STORED PROCEDURES ─────────────────────────────────
-- ============================================================

-- Báo cáo hội viên đang hoạt động (có gói tập còn hạn)
CREATE OR ALTER PROCEDURE dbo.sp_Report_ActiveMembers
AS BEGIN SET NOCOUNT ON;
    SELECT m.MemberId, m.FullName, m.Email, m.Phone,
           ms.MembershipType, ms.EndDate,
           dbo.fn_GetDaysRemaining(ms.EndDate) AS DaysRemaining,
           (SELECT COUNT(*) FROM Checkins c WHERE c.MemberId = m.MemberId) AS TotalCheckins
    FROM Members m
    INNER JOIN Memberships ms ON ms.MemberId = m.MemberId
        AND ms.IsActive = 1 AND ms.EndDate >= CAST(GETDATE() AS DATE)
    WHERE m.Status = 'Active'
    ORDER BY m.FullName;
END;
GO

-- Báo cáo doanh thu theo tháng/năm
CREATE OR ALTER PROCEDURE dbo.sp_Report_Revenue
    @Month INT, @Year INT
AS BEGIN SET NOCOUNT ON;
    SELECT
        COUNT(*)                AS TotalInvoices,
        SUM(i.TotalAmount)     AS TotalRevenue,
        SUM(CASE WHEN i.Status = 'Paid' THEN i.TotalAmount ELSE 0 END) AS PaidRevenue,
        SUM(CASE WHEN i.Status = 'Pending' THEN i.TotalAmount ELSE 0 END) AS PendingRevenue
    FROM Invoices i
    WHERE MONTH(i.InvoiceDate) = @Month AND YEAR(i.InvoiceDate) = @Year;
END;
GO

-- Danh sách chi tiết thanh toán theo tháng
CREATE OR ALTER PROCEDURE dbo.sp_Report_RevenueDetail
    @Month INT, @Year INT
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.Status,
           p.Amount AS PaidAmount, p.PaymentMethod, p.PaymentDate
    FROM Invoices i
    JOIN Members m ON m.MemberId = i.MemberId
    LEFT JOIN Payments p ON p.InvoiceId = i.InvoiceId AND p.Status = 'Completed'
    WHERE MONTH(i.InvoiceDate) = @Month AND YEAR(i.InvoiceDate) = @Year
    ORDER BY i.InvoiceDate DESC;
END;
GO

PRINT 'Programmability created successfully.';
