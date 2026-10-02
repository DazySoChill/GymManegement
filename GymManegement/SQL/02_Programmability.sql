-- ============================================================
-- FILE: 02_Programmability.sql
-- Mô tả: Stored Procedures, Functions, Views cho GymDb
-- Chạy sau 01_Schema.sql. An toàn khi chạy lại (CREATE OR ALTER).
-- Đã cập nhật: IsDeleted filters, pagination, search, filter, sorting
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
        (SELECT COUNT(*) FROM Checkins c WHERE c.MemberId = m.MemberId AND c.IsDeleted = 0) AS TotalCheckins,
        (SELECT COUNT(*) FROM Invoices i WHERE i.MemberId = m.MemberId AND i.IsDeleted = 0 AND i.Status = 'Pending') AS PendingInvoices
    FROM Members m
    LEFT JOIN Memberships ms ON ms.MemberId = m.MemberId
        AND ms.IsActive = 1
        AND ms.EndDate >= CAST(GETDATE() AS DATE)
        AND ms.IsDeleted = 0
    WHERE m.IsDeleted = 0;
GO

-- ============================================================
-- VIEW: vw_ActiveSchedules
-- Lịch tập đang hoạt động (chưa bị xóa mềm)
-- ============================================================
CREATE OR ALTER VIEW dbo.vw_ActiveSchedules AS
    SELECT 
        s.ScheduleId, s.MemberId, m.FullName AS MemberName,
        s.TrainerId, t.FullName AS TrainerName,
        s.FacilityId, f.Name AS FacilityName, 
        s.StartTime, s.EndTime
    FROM Schedules s
    JOIN Members m ON m.MemberId = s.MemberId AND m.IsDeleted = 0
    JOIN Trainers t ON t.TrainerId = s.TrainerId AND t.IsDeleted = 0
    JOIN Facilities f ON f.FacilityId = s.FacilityId AND f.IsDeleted = 0
    WHERE s.IsDeleted = 0;
GO

-- ============================================================
-- ── PAGINATION & SEARCH HELPER PROCEDURES ──────────────────
-- ============================================================

-- Generic pagination parameters: @PageNumber (1-based), @PageSize, @SearchTerm, @SortBy, @SortDir (ASC/DESC)
-- Returns: TotalCount as OUTPUT parameter

-- ============================================================
-- ── MEMBER STORED PROCEDURES ─────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SearchTerm NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = NULL,
    @SortBy NVARCHAR(50) = 'FullName',
    @SortDir NVARCHAR(4) = 'ASC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SearchTerm IS NOT NULL AND @SearchTerm <> ''
        SET @Where += ' AND (FullName LIKE ''%' + @SearchTerm + '%'' OR Email LIKE ''%' + @SearchTerm + '%'' OR Phone LIKE ''%' + @SearchTerm + '%'' OR QRCodeValue LIKE ''%' + @SearchTerm + '%'')';
    
    IF @Status IS NOT NULL AND @Status <> ''
        SET @Where += ' AND Status = ''' + @Status + '''';
    
    -- Validate sort column to prevent SQL injection
    IF @SortBy NOT IN ('MemberId', 'FullName', 'Email', 'Phone', 'DateOfBirth', 'JoinDate', 'Status', 'CreatedAt')
        SET @SortBy = 'FullName';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'ASC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    -- Count total
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Members ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    -- Get paged data
    SET @Sql = 'SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedAt, UpdatedAt
                FROM Members ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetById
    @MemberId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Members WHERE MemberId = @MemberId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetByEmail
    @Email NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE Email = @Email AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_GetByQRCode
    @QRCodeValue NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue
    FROM Members WHERE QRCodeValue = @QRCodeValue AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Create
    @FullName       NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Email          NVARCHAR(150),
    @DateOfBirth    DATE,
    @JoinDate       DATE,
    @Status         NVARCHAR(20),
    @QRCodeValue    NVARCHAR(50),
    @CreatedBy      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Members (FullName, Phone, Email, DateOfBirth, JoinDate, Status, QRCodeValue, CreatedBy)
    VALUES (@FullName, @Phone, @Email, @DateOfBirth, @JoinDate, @Status, @QRCodeValue, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Update
    @MemberId       INT,
    @FullName       NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Email          NVARCHAR(150),
    @DateOfBirth    DATE,
    @Status         NVARCHAR(20),
    @UpdatedBy      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Members
    SET FullName = @FullName, Phone = @Phone, Email = @Email,
        DateOfBirth = @DateOfBirth, Status = @Status,
        UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy
    WHERE MemberId = @MemberId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_SoftDelete
    @MemberId INT,
    @DeletedBy  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Members
    SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE MemberId = @MemberId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Member_Restore
    @MemberId INT,
    @RestoredBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Members
    SET IsDeleted = 0, DeletedAt = NULL, DeletedBy = NULL,
        UpdatedAt = GETDATE(), UpdatedBy = @RestoredBy
    WHERE MemberId = @MemberId AND IsDeleted = 1;
END;
GO

-- ============================================================
-- ── TRAINER STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SearchTerm NVARCHAR(100) = NULL,
    @SortBy NVARCHAR(50) = 'FullName',
    @SortDir NVARCHAR(4) = 'ASC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SearchTerm IS NOT NULL AND @SearchTerm <> ''
        SET @Where += ' AND (FullName LIKE ''%' + @SearchTerm + '%'' OR Email LIKE ''%' + @SearchTerm + '%'' OR Specialization LIKE ''%' + @SearchTerm + '%'')';
    
    IF @SortBy NOT IN ('TrainerId', 'FullName', 'Phone', 'Email', 'Specialization', 'CreatedAt')
        SET @SortBy = 'FullName';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'ASC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Trainers ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT TrainerId, FullName, Phone, Email, Specialization, CreatedAt, UpdatedAt
                FROM Trainers ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_GetById @TrainerId INT
AS BEGIN SET NOCOUNT ON;
    SELECT TrainerId, FullName, Phone, Email, Specialization,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Trainers WHERE TrainerId = @TrainerId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_Create
    @FullName NVARCHAR(100), @Phone NVARCHAR(20), @Email NVARCHAR(150), @Specialization NVARCHAR(100), @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Trainers (FullName, Phone, Email, Specialization, CreatedBy)
    VALUES (@FullName, @Phone, @Email, @Specialization, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS TrainerId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_Update
    @TrainerId INT, @FullName NVARCHAR(100), @Phone NVARCHAR(20), @Email NVARCHAR(150), @Specialization NVARCHAR(100), @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Trainers SET FullName=@FullName, Phone=@Phone, Email=@Email, Specialization=@Specialization,
        UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy
    WHERE TrainerId = @TrainerId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Trainer_SoftDelete @TrainerId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Trainers SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE TrainerId = @TrainerId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── FACILITY STORED PROCEDURES ───────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SearchTerm NVARCHAR(100) = NULL,
    @IsActive BIT = NULL,
    @SortBy NVARCHAR(50) = 'Name',
    @SortDir NVARCHAR(4) = 'ASC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @SearchTerm IS NOT NULL AND @SearchTerm <> ''
        SET @Where += ' AND (Name LIKE ''%' + @SearchTerm + '%'' OR Description LIKE ''%' + @SearchTerm + '%'')';
    
    IF @IsActive IS NOT NULL
        SET @Where += ' AND IsActive = ' + CAST(@IsActive AS NVARCHAR(1));
    
    IF @SortBy NOT IN ('FacilityId', 'Name', 'Description', 'IsActive', 'CreatedAt')
        SET @SortBy = 'Name';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'ASC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Facilities ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT FacilityId, Name, Description, IsActive, CreatedAt, UpdatedAt
                FROM Facilities ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetById @FacilityId INT
AS BEGIN SET NOCOUNT ON;
    SELECT FacilityId, Name, Description, IsActive,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Facilities WHERE FacilityId = @FacilityId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Facility_GetActive
AS BEGIN SET NOCOUNT ON;
    SELECT FacilityId, Name, Description, IsActive FROM Facilities WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Facility_Create
    @Name NVARCHAR(100), @Description NVARCHAR(500), @IsActive BIT, @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Facilities (Name, Description, IsActive, CreatedBy) VALUES (@Name, @Description, @IsActive, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS FacilityId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Facility_Update
    @FacilityId INT, @Name NVARCHAR(100), @Description NVARCHAR(500), @IsActive BIT, @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Facilities SET Name=@Name, Description=@Description, IsActive=@IsActive,
        UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy
    WHERE FacilityId = @FacilityId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Facility_SoftDelete @FacilityId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Facilities SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE FacilityId = @FacilityId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── MEMBERSHIP STORED PROCEDURES ─────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @MemberId INT = NULL,
    @MembershipType NVARCHAR(50) = NULL,
    @IsActive BIT = NULL,
    @SortBy NVARCHAR(50) = 'StartDate',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @MemberId IS NOT NULL
        SET @Where += ' AND MemberId = ' + CAST(@MemberId AS NVARCHAR(10));
    
    IF @MembershipType IS NOT NULL AND @MembershipType <> ''
        SET @Where += ' AND MembershipType = ''' + @MembershipType + '''';
    
    IF @IsActive IS NOT NULL
        SET @Where += ' AND IsActive = ' + CAST(@IsActive AS NVARCHAR(1));
    
    IF @SortBy NOT IN ('MembershipId', 'MemberId', 'MembershipType', 'Price', 'StartDate', 'EndDate', 'IsActive', 'Version', 'CreatedAt')
        SET @SortBy = 'StartDate';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Memberships ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version, CreatedAt, UpdatedAt
                FROM Memberships ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetById @MembershipId INT
AS BEGIN SET NOCOUNT ON;
    SELECT MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Memberships WHERE MembershipId = @MembershipId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetActive @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 MembershipId, MemberId, MembershipType, Price, StartDate, EndDate, IsActive, Version
    FROM Memberships
    WHERE MemberId = @MemberId AND IsDeleted = 0 AND IsActive = 1 AND EndDate >= CAST(GETDATE() AS DATE)
    ORDER BY EndDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_GetExpiringSoon @DaysAhead INT = 7
AS BEGIN SET NOCOUNT ON;
    SELECT ms.MembershipId, ms.MemberId, m.FullName, m.Email, ms.MembershipType,
           ms.EndDate, dbo.fn_GetDaysRemaining(ms.EndDate) AS DaysRemaining
    FROM Memberships ms
    INNER JOIN Members m ON m.MemberId = ms.MemberId AND m.IsDeleted = 0
    WHERE ms.IsActive = 1
      AND ms.IsDeleted = 0
      AND ms.EndDate >= CAST(GETDATE() AS DATE)
      AND ms.EndDate <= DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE))
    ORDER BY ms.EndDate;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_Create
    @MemberId INT, @MembershipType NVARCHAR(50), @Price DECIMAL(18,2), @StartDate DATE, @EndDate DATE, @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    -- Deactivate previous memberships
    UPDATE Memberships SET IsActive = 0, UpdatedAt = GETDATE(), UpdatedBy = @CreatedBy 
    WHERE MemberId = @MemberId AND IsActive = 1 AND IsDeleted = 0;
    
    INSERT INTO Memberships (MemberId, MembershipType, Price, StartDate, EndDate, IsActive, CreatedBy)
    VALUES (@MemberId, @MembershipType, @Price, @StartDate, @EndDate, 1, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS MembershipId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_Update
    @MembershipId INT, @MembershipType NVARCHAR(50), @Price DECIMAL(18,2),
    @StartDate DATE, @EndDate DATE, @IsActive BIT, @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Memberships SET 
        MembershipType=@MembershipType, Price=@Price,
        StartDate=@StartDate, EndDate=@EndDate, IsActive=@IsActive,
        Version = Version + 1,
        UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy
    WHERE MembershipId = @MembershipId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Membership_SoftDelete @MembershipId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Memberships SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE MembershipId = @MembershipId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── SCHEDULE STORED PROCEDURES ───────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @MemberId INT = NULL,
    @TrainerId INT = NULL,
    @FacilityId INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @SortBy NVARCHAR(50) = 'StartTime',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE s.IsDeleted = 0 AND m.IsDeleted = 0 AND t.IsDeleted = 0 AND f.IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @MemberId IS NOT NULL
        SET @Where += ' AND s.MemberId = ' + CAST(@MemberId AS NVARCHAR(10));
    IF @TrainerId IS NOT NULL
        SET @Where += ' AND s.TrainerId = ' + CAST(@TrainerId AS NVARCHAR(10));
    IF @FacilityId IS NOT NULL
        SET @Where += ' AND s.FacilityId = ' + CAST(@FacilityId AS NVARCHAR(10));
    IF @FromDate IS NOT NULL
        SET @Where += ' AND CAST(s.StartTime AS DATE) >= ''' + CAST(@FromDate AS NVARCHAR(10)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND CAST(s.StartTime AS DATE) <= ''' + CAST(@ToDate AS NVARCHAR(10)) + '''';
    
    IF @SortBy NOT IN ('ScheduleId', 'MemberId', 'TrainerId', 'FacilityId', 'StartTime', 'EndTime', 'CreatedAt')
        SET @SortBy = 'StartTime';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Schedules s
                JOIN Members m ON m.MemberId = s.MemberId
                JOIN Trainers t ON t.TrainerId = s.TrainerId
                JOIN Facilities f ON f.FacilityId = s.FacilityId ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT s.ScheduleId, s.MemberId, m.FullName AS MemberName,
                       s.TrainerId, t.FullName AS TrainerName,
                       s.FacilityId, f.Name AS FacilityName, s.StartTime, s.EndTime, s.CreatedAt
                FROM Schedules s
                JOIN Members m ON m.MemberId = s.MemberId
                JOIN Trainers t ON t.TrainerId = s.TrainerId
                JOIN Facilities f ON f.FacilityId = s.FacilityId ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_GetById @ScheduleId INT
AS BEGIN SET NOCOUNT ON;
    SELECT s.ScheduleId, s.MemberId, m.FullName AS MemberName,
           s.TrainerId, t.FullName AS TrainerName,
           s.FacilityId, f.Name AS FacilityName, s.StartTime, s.EndTime,
           s.CreatedAt, s.CreatedBy, s.UpdatedAt, s.UpdatedBy, s.IsDeleted, s.DeletedAt, s.DeletedBy, s.RowVersion
    FROM Schedules s
    JOIN Members m ON m.MemberId = s.MemberId
    JOIN Trainers t ON t.TrainerId = s.TrainerId
    JOIN Facilities f ON f.FacilityId = s.FacilityId
    WHERE s.ScheduleId = @ScheduleId AND s.IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_CheckConflict
    @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2, @ExcludeId INT = 0
AS BEGIN SET NOCOUNT ON;
    SELECT COUNT(*) AS ConflictCount FROM Schedules
    WHERE (TrainerId = @TrainerId OR FacilityId = @FacilityId)
      AND ScheduleId <> @ExcludeId
      AND IsDeleted = 0
      AND StartTime < @EndTime AND EndTime > @StartTime;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_Create
    @MemberId INT, @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2, @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Schedules (MemberId, TrainerId, FacilityId, StartTime, EndTime, CreatedBy)
    VALUES (@MemberId, @TrainerId, @FacilityId, @StartTime, @EndTime, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS ScheduleId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_Update
    @ScheduleId INT, @TrainerId INT, @FacilityId INT, @StartTime DATETIME2, @EndTime DATETIME2, @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Schedules SET TrainerId=@TrainerId, FacilityId=@FacilityId,
        StartTime=@StartTime, EndTime=@EndTime,
        UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy
    WHERE ScheduleId = @ScheduleId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Schedule_SoftDelete @ScheduleId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Schedules SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE ScheduleId = @ScheduleId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── SESSION STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Session_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @ScheduleId INT = NULL,
    @Status NVARCHAR(30) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @SortBy NVARCHAR(50) = 'SessionDate',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @ScheduleId IS NOT NULL
        SET @Where += ' AND ScheduleId = ' + CAST(@ScheduleId AS NVARCHAR(10));
    IF @Status IS NOT NULL AND @Status <> ''
        SET @Where += ' AND Status = ''' + @Status + '''';
    IF @FromDate IS NOT NULL
        SET @Where += ' AND SessionDate >= ''' + CAST(@FromDate AS NVARCHAR(10)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND SessionDate <= ''' + CAST(@ToDate AS NVARCHAR(10)) + '''';
    
    IF @SortBy NOT IN ('SessionId', 'ScheduleId', 'SessionDate', 'Status', 'CreatedAt')
        SET @SortBy = 'SessionDate';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Sessions ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT SessionId, ScheduleId, SessionDate, Status, CreatedAt, UpdatedAt
                FROM Sessions ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Session_GetById @SessionId INT
AS BEGIN SET NOCOUNT ON;
    SELECT SessionId, ScheduleId, SessionDate, Status,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Sessions WHERE SessionId = @SessionId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Session_GetBySchedule @ScheduleId INT
AS BEGIN SET NOCOUNT ON;
    SELECT SessionId, ScheduleId, SessionDate, Status FROM Sessions WHERE ScheduleId = @ScheduleId AND IsDeleted = 0 ORDER BY SessionDate;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Session_Create
    @ScheduleId INT, @SessionDate DATE, @Status NVARCHAR(30), @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    INSERT INTO Sessions (ScheduleId, SessionDate, Status, CreatedBy) VALUES (@ScheduleId, @SessionDate, @Status, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS SessionId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Session_UpdateStatus @SessionId INT, @Status NVARCHAR(30), @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    UPDATE Sessions SET Status = @Status, UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy WHERE SessionId = @SessionId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Session_SoftDelete @SessionId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    UPDATE Sessions SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE SessionId = @SessionId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── CHECKIN STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @MemberId INT = NULL,
    @SessionId INT = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate DATETIME2 = NULL,
    @CheckinMethod NVARCHAR(50) = NULL,
    @SortBy NVARCHAR(50) = 'CheckinTime',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE c.IsDeleted = 0 AND m.IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @MemberId IS NOT NULL
        SET @Where += ' AND c.MemberId = ' + CAST(@MemberId AS NVARCHAR(10));
    IF @SessionId IS NOT NULL
        SET @Where += ' AND c.SessionId = ' + CAST(@SessionId AS NVARCHAR(10));
    IF @FromDate IS NOT NULL
        SET @Where += ' AND c.CheckinTime >= ''' + CAST(@FromDate AS NVARCHAR(30)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND c.CheckinTime <= ''' + CAST(@ToDate AS NVARCHAR(30)) + '''';
    IF @CheckinMethod IS NOT NULL AND @CheckinMethod <> ''
        SET @Where += ' AND c.CheckinMethod = ''' + @CheckinMethod + '''';
    
    IF @SortBy NOT IN ('CheckinId', 'MemberId', 'SessionId', 'CheckinTime', 'CheckinMethod', 'CreatedAt')
        SET @SortBy = 'CheckinTime';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT c.CheckinId, c.MemberId, m.FullName AS MemberName,
                       c.SessionId, c.CheckinTime, c.CheckinMethod, c.CreatedAt
                FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetById @CheckinId INT
AS BEGIN SET NOCOUNT ON;
    SELECT c.CheckinId, c.MemberId, m.FullName AS MemberName,
           c.SessionId, c.CheckinTime, c.CheckinMethod,
           c.CreatedAt, c.CreatedBy, c.UpdatedAt, c.UpdatedBy, c.IsDeleted, c.DeletedAt, c.DeletedBy, c.RowVersion
    FROM Checkins c JOIN Members m ON m.MemberId = c.MemberId
    WHERE c.CheckinId = @CheckinId AND c.IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Checkin_GetByMember @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT CheckinId, MemberId, SessionId, CheckinTime, CheckinMethod
    FROM Checkins WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY CheckinTime DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Checkin_Create
    @MemberId INT, @SessionId INT, @CheckinTime DATETIME2, @CheckinMethod NVARCHAR(50), @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Checkins (MemberId, SessionId, CheckinTime, CheckinMethod, CreatedBy)
    VALUES (@MemberId, @SessionId, @CheckinTime, @CheckinMethod, @CreatedBy);
    SELECT SCOPE_IDENTITY() AS CheckinId;
END;
GO

-- Check-in bằng QR: tìm member qua QR rồi checkin
CREATE OR ALTER PROCEDURE dbo.sp_Checkin_ByQRCode
    @QRCodeValue NVARCHAR(50), @SessionId INT, @CreatedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    DECLARE @MemberId INT;
    DECLARE @MemberStatus NVARCHAR(20);
    DECLARE @HasActiveMembership BIT = 0;

    -- Tìm member theo QR
    SELECT @MemberId = MemberId, @MemberStatus = Status
    FROM Members WHERE QRCodeValue = @QRCodeValue AND IsDeleted = 0;

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
        WHERE MemberId = @MemberId AND IsActive = 1 AND EndDate >= CAST(GETDATE() AS DATE) AND IsDeleted = 0
    )
        SET @HasActiveMembership = 1;

    IF @HasActiveMembership = 0
    BEGIN
        SELECT -3 AS CheckinId, N'Hội viên hết hạn gói tập' AS Message; RETURN;
    END

    -- Thực hiện check-in
    INSERT INTO Checkins (MemberId, SessionId, CheckinTime, CheckinMethod, CreatedBy)
    VALUES (@MemberId, @SessionId, GETDATE(), 'QRCode', @CreatedBy);

    SELECT SCOPE_IDENTITY() AS CheckinId, N'Check-in thành công' AS Message;
END;
GO

-- ============================================================
-- ── INVOICE STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @MemberId INT = NULL,
    @Status NVARCHAR(30) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @SortBy NVARCHAR(50) = 'InvoiceDate',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE i.IsDeleted = 0 AND m.IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @MemberId IS NOT NULL
        SET @Where += ' AND i.MemberId = ' + CAST(@MemberId AS NVARCHAR(10));
    IF @Status IS NOT NULL AND @Status <> ''
        SET @Where += ' AND i.Status = ''' + @Status + '''';
    IF @FromDate IS NOT NULL
        SET @Where += ' AND i.InvoiceDate >= ''' + CAST(@FromDate AS NVARCHAR(10)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND i.InvoiceDate <= ''' + CAST(@ToDate AS NVARCHAR(10)) + '''';
    
    IF @SortBy NOT IN ('InvoiceId', 'MemberId', 'TotalAmount', 'InvoiceDate', 'DueDate', 'Status', 'CreatedAt')
        SET @SortBy = 'InvoiceDate';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
                       i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status, i.CreatedAt
                FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetById @InvoiceId INT
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status,
           i.CreatedAt, i.CreatedBy, i.UpdatedAt, i.UpdatedBy, i.IsDeleted, i.DeletedAt, i.DeletedBy, i.RowVersion
    FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId
    WHERE i.InvoiceId = @InvoiceId AND i.IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetByMember @MemberId INT
AS BEGIN SET NOCOUNT ON;
    SELECT InvoiceId, MemberId, TotalAmount, InvoiceDate, DueDate, Status
    FROM Invoices WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY InvoiceDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_GetOverdue
AS BEGIN SET NOCOUNT ON;
    SELECT i.InvoiceId, i.MemberId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.DueDate, i.Status
    FROM Invoices i JOIN Members m ON m.MemberId = i.MemberId
    WHERE i.Status = 'Pending' AND i.DueDate < CAST(GETDATE() AS DATE) AND i.IsDeleted = 0
    ORDER BY i.DueDate;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_Create
    @MemberId INT, @TotalAmount DECIMAL(18,2), @InvoiceDate DATE, @DueDate DATE, @CreatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    INSERT INTO Invoices (MemberId, TotalAmount, InvoiceDate, DueDate, Status, CreatedBy)
    VALUES (@MemberId, @TotalAmount, @InvoiceDate, @DueDate, 'Pending', @CreatedBy);
    SELECT SCOPE_IDENTITY() AS InvoiceId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_UpdateStatus @InvoiceId INT, @Status NVARCHAR(30), @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Invoices SET Status = @Status, UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy WHERE InvoiceId = @InvoiceId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Invoice_SoftDelete @InvoiceId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Invoices SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE InvoiceId = @InvoiceId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── PAYMENT STORED PROCEDURES ────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Payment_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @InvoiceId INT = NULL,
    @PaymentMethod NVARCHAR(30) = NULL,
    @Status NVARCHAR(30) = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate DATETIME2 = NULL,
    @SortBy NVARCHAR(50) = 'PaymentDate',
    @SortDir NVARCHAR(4) = 'DESC',
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE p.IsDeleted = 0 AND i.IsDeleted = 0';
    DECLARE @OrderBy NVARCHAR(100);
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @InvoiceId IS NOT NULL
        SET @Where += ' AND p.InvoiceId = ' + CAST(@InvoiceId AS NVARCHAR(10));
    IF @PaymentMethod IS NOT NULL AND @PaymentMethod <> ''
        SET @Where += ' AND p.PaymentMethod = ''' + @PaymentMethod + '''';
    IF @Status IS NOT NULL AND @Status <> ''
        SET @Where += ' AND p.Status = ''' + @Status + '''';
    IF @FromDate IS NOT NULL
        SET @Where += ' AND p.PaymentDate >= ''' + CAST(@FromDate AS NVARCHAR(30)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND p.PaymentDate <= ''' + CAST(@ToDate AS NVARCHAR(30)) + '''';
    
    IF @SortBy NOT IN ('PaymentId', 'InvoiceId', 'Amount', 'PaymentDate', 'PaymentMethod', 'Status', 'CreatedAt')
        SET @SortBy = 'PaymentDate';
    IF @SortDir NOT IN ('ASC', 'DESC')
        SET @SortDir = 'DESC';
    SET @OrderBy = 'ORDER BY ' + @SortBy + ' ' + @SortDir;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Payments p JOIN Invoices i ON i.InvoiceId = p.InvoiceId ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT p.PaymentId, p.InvoiceId, p.Amount, p.PaymentDate, p.PaymentMethod, p.Status, p.CreatedAt
                FROM Payments p JOIN Invoices i ON i.InvoiceId = p.InvoiceId ' + @Where + ' ' + @OrderBy + 
                ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Payment_GetByInvoice @InvoiceId INT
AS BEGIN SET NOCOUNT ON;
    SELECT PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status
    FROM Payments WHERE InvoiceId = @InvoiceId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Payment_GetById @PaymentId INT
AS BEGIN SET NOCOUNT ON;
    SELECT PaymentId, InvoiceId, Amount, PaymentDate, PaymentMethod, Status,
           CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted, DeletedAt, DeletedBy, RowVersion
    FROM Payments WHERE PaymentId = @PaymentId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Payment_Create
    @InvoiceId INT, @Amount DECIMAL(18,2), @PaymentDate DATETIME2, @PaymentMethod NVARCHAR(30), @CreatedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Payments (InvoiceId, Amount, PaymentDate, PaymentMethod, Status, CreatedBy)
        VALUES (@InvoiceId, @Amount, @PaymentDate, @PaymentMethod, 'Completed', @CreatedBy);
        
        DECLARE @PaymentId INT = SCOPE_IDENTITY();
        
        -- Cập nhật invoice thành Paid
        UPDATE Invoices SET Status = 'Paid', UpdatedAt = GETDATE(), UpdatedBy = @CreatedBy WHERE InvoiceId = @InvoiceId;
        
        SELECT @PaymentId AS PaymentId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Payment_UpdateStatus @PaymentId INT, @Status NVARCHAR(30), @UpdatedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Payments SET Status = @Status, UpdatedAt = GETDATE(), UpdatedBy = @UpdatedBy WHERE PaymentId = @PaymentId AND IsDeleted = 0;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Payment_SoftDelete @PaymentId INT, @DeletedBy INT = NULL
AS BEGIN SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    UPDATE Payments SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = @DeletedBy,
        UpdatedAt = GETDATE(), UpdatedBy = @DeletedBy
    WHERE PaymentId = @PaymentId AND IsDeleted = 0;
END;
GO

-- ============================================================
-- ── REPORT STORED PROCEDURES ─────────────────────────────────
-- ============================================================

-- Báo cáo hội viên đang hoạt động (có gói tập còn hạn)
CREATE OR ALTER PROCEDURE dbo.sp_Report_ActiveMembers
    @PageNumber INT = 1,
    @PageSize INT = 50,
    @TotalCount INT OUTPUT
AS BEGIN SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE m.IsDeleted = 0 AND m.Status = ''Active'' AND ms.IsDeleted = 0 AND ms.IsActive = 1 AND ms.EndDate >= CAST(GETDATE() AS DATE)';
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM Members m
                INNER JOIN Memberships ms ON ms.MemberId = m.MemberId ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT m.MemberId, m.FullName, m.Email, m.Phone,
                       ms.MembershipType, ms.EndDate,
                       dbo.fn_GetDaysRemaining(ms.EndDate) AS DaysRemaining,
                       (SELECT COUNT(*) FROM Checkins c WHERE c.MemberId = m.MemberId AND c.IsDeleted = 0) AS TotalCheckins
                FROM Members m
                INNER JOIN Memberships ms ON ms.MemberId = m.MemberId ' + @Where + '
                ORDER BY m.FullName
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
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
    WHERE MONTH(i.InvoiceDate) = @Month AND YEAR(i.InvoiceDate) = @Year AND i.IsDeleted = 0;
END;
GO

-- Danh sách chi tiết thanh toán theo tháng
CREATE OR ALTER PROCEDURE dbo.sp_Report_RevenueDetail
    @Month INT, @Year INT,
    @PageNumber INT = 1,
    @PageSize INT = 50,
    @TotalCount INT OUTPUT
AS BEGIN SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT @TotalCount = COUNT(*)
    FROM Invoices i
    JOIN Members m ON m.MemberId = i.MemberId
    LEFT JOIN Payments p ON p.InvoiceId = i.InvoiceId AND p.Status = 'Completed' AND p.IsDeleted = 0
    WHERE MONTH(i.InvoiceDate) = @Month AND YEAR(i.InvoiceDate) = @Year AND i.IsDeleted = 0;
    
    SELECT i.InvoiceId, m.FullName AS MemberName,
           i.TotalAmount, i.InvoiceDate, i.Status,
           p.Amount AS PaidAmount, p.PaymentMethod, p.PaymentDate
    FROM Invoices i
    JOIN Members m ON m.MemberId = i.MemberId
    LEFT JOIN Payments p ON p.InvoiceId = i.InvoiceId AND p.Status = 'Completed' AND p.IsDeleted = 0
    WHERE MONTH(i.InvoiceDate) = @Month AND YEAR(i.InvoiceDate) = @Year AND i.IsDeleted = 0
    ORDER BY i.InvoiceDate DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- Báo cáo tần suất check-in theo hội viên
CREATE OR ALTER PROCEDURE dbo.sp_Report_MemberCheckinFrequency
    @FromDate DATE, @ToDate DATE,
    @PageNumber INT = 1,
    @PageSize INT = 50,
    @TotalCount INT OUTPUT
AS BEGIN SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT @TotalCount = COUNT(*)
    FROM Members m
    WHERE m.IsDeleted = 0 AND m.Status = 'Active'
      AND EXISTS (
        SELECT 1 FROM Checkins c 
        WHERE c.MemberId = m.MemberId AND c.IsDeleted = 0
          AND CAST(c.CheckinTime AS DATE) BETWEEN @FromDate AND @ToDate
      );
    
    SELECT m.MemberId, m.FullName, m.Email, m.Phone,
           COUNT(c.CheckinId) AS CheckinCount,
           MIN(c.CheckinTime) AS FirstCheckin,
           MAX(c.CheckinTime) AS LastCheckin
    FROM Members m
    LEFT JOIN Checkins c ON c.MemberId = m.MemberId AND c.IsDeleted = 0
        AND CAST(c.CheckinTime AS DATE) BETWEEN @FromDate AND @ToDate
    WHERE m.IsDeleted = 0 AND m.Status = 'Active'
    GROUP BY m.MemberId, m.FullName, m.Email, m.Phone
    HAVING COUNT(c.CheckinId) > 0
    ORDER BY CheckinCount DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- Báo cáo利用率 phòng (Facility Utilization)
CREATE OR ALTER PROCEDURE dbo.sp_Report_FacilityUtilization
    @FromDate DATE, @ToDate DATE
AS BEGIN SET NOCOUNT ON;
    SELECT f.FacilityId, f.Name,
           COUNT(DISTINCT s.ScheduleId) AS TotalSchedules,
           COUNT(DISTINCT CASE WHEN se.Status = 'Completed' THEN se.SessionId END) AS CompletedSessions,
           COUNT(DISTINCT c.CheckinId) AS TotalCheckins,
           CAST(COUNT(DISTINCT CASE WHEN se.Status = 'Completed' THEN se.SessionId END) * 100.0 / 
                NULLIF(COUNT(DISTINCT s.ScheduleId), 0) AS DECIMAL(5,2)) AS UtilizationRate
    FROM Facilities f
    LEFT JOIN Schedules s ON s.FacilityId = f.FacilityId AND s.IsDeleted = 0
        AND CAST(s.StartTime AS DATE) BETWEEN @FromDate AND @ToDate
    LEFT JOIN Sessions se ON se.ScheduleId = s.ScheduleId AND se.IsDeleted = 0
    LEFT JOIN Checkins c ON c.SessionId = se.SessionId AND c.IsDeleted = 0
    WHERE f.IsDeleted = 0 AND f.IsActive = 1
    GROUP BY f.FacilityId, f.Name
    ORDER BY UtilizationRate DESC;
END;
GO

-- Báo cáo PT workload
CREATE OR ALTER PROCEDURE dbo.sp_Report_TrainerWorkload
    @FromDate DATE, @ToDate DATE
AS BEGIN SET NOCOUNT ON;
    SELECT t.TrainerId, t.FullName, t.Specialization,
           COUNT(DISTINCT s.ScheduleId) AS TotalSchedules,
           COUNT(DISTINCT CASE WHEN se.Status = 'Completed' THEN se.SessionId END) AS CompletedSessions,
           COUNT(DISTINCT c.CheckinId) AS TotalCheckins,
           COUNT(DISTINCT s.MemberId) AS UniqueMembers
    FROM Trainers t
    LEFT JOIN Schedules s ON s.TrainerId = t.TrainerId AND s.IsDeleted = 0
        AND CAST(s.StartTime AS DATE) BETWEEN @FromDate AND @ToDate
    LEFT JOIN Sessions se ON se.ScheduleId = s.ScheduleId AND se.IsDeleted = 0
    LEFT JOIN Checkins c ON c.SessionId = se.SessionId AND c.IsDeleted = 0
    WHERE t.IsDeleted = 0
    GROUP BY t.TrainerId, t.FullName, t.Specialization
    ORDER BY CompletedSessions DESC;
END;
GO

-- ============================================================
-- ── AUDIT LOG STORED PROCEDURES ──────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_AuditLog_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 50,
    @TableName NVARCHAR(100) = NULL,
    @RecordId INT = NULL,
    @Action NVARCHAR(20) = NULL,
    @ChangedBy INT = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate DATETIME2 = NULL,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Where NVARCHAR(MAX) = 'WHERE 1=1';
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    IF @TableName IS NOT NULL AND @TableName <> ''
        SET @Where += ' AND TableName = ''' + @TableName + '''';
    IF @RecordId IS NOT NULL
        SET @Where += ' AND RecordId = ' + CAST(@RecordId AS NVARCHAR(10));
    IF @Action IS NOT NULL AND @Action <> ''
        SET @Where += ' AND Action = ''' + @Action + '''';
    IF @ChangedBy IS NOT NULL
        SET @Where += ' AND ChangedBy = ' + CAST(@ChangedBy AS NVARCHAR(10));
    IF @FromDate IS NOT NULL
        SET @Where += ' AND ChangedAt >= ''' + CAST(@FromDate AS NVARCHAR(30)) + '''';
    IF @ToDate IS NOT NULL
        SET @Where += ' AND ChangedAt <= ''' + CAST(@ToDate AS NVARCHAR(30)) + '''';
    
    SET @Sql = 'SELECT @Total = COUNT(*) FROM AuditLogs ' + @Where;
    EXEC sp_executesql @Sql, N'@Total INT OUTPUT', @TotalCount OUTPUT;
    
    SET @Sql = 'SELECT AuditLogId, TableName, RecordId, Action, OldValues, NewValues, ChangedBy, ChangedAt, IpAddress, UserAgent
                FROM AuditLogs ' + @Where + ' ORDER BY ChangedAt DESC
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';
    EXEC sp_executesql @Sql, N'@Offset INT, @PageSize INT', @Offset, @PageSize;
END;
GO

-- ============================================================
-- ── USER PERMISSIONS (for JWT claims) ───────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_User_GetPermissions
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.PermissionCode
    FROM RolePermissions rp
    INNER JOIN Permissions p ON p.PermissionId = rp.PermissionId
    INNER JOIN Users u ON u.RoleId = rp.RoleId
    WHERE u.UserId = @UserId AND u.IsDeleted = 0;
END;
GO

-- ============================================================
-- ── USER AUTHENTICATION ─────────────────────────────────────
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_User_GetByUsername
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;
    SELECT 
        u.UserId, u.Username, u.PasswordHash, u.PasswordSalt,
        u.RoleId, r.RoleName,
        u.MemberId, u.TrainerId,
        u.IsActive, u.FailedLoginCount, u.LockedUntil, u.LastLoginAt,
        u.RefreshToken, u.RefreshTokenExpiry
    FROM Users u
    INNER JOIN Roles r ON r.RoleId = u.RoleId
    WHERE u.Username = @Username AND u.IsDeleted = 0;
END;
GO

PRINT 'Programmability created successfully with pagination, search, filter, sort, and soft delete support.';
GO
