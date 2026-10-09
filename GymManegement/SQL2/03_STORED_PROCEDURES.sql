-- ============================================================
-- FILE: 03_STORED_PROCEDURES.sql
-- MÔ TẢ: Basic stored procedures cho CRUD operations
-- Optional: Có thể dùng Dapper/EF trực tiếp thay vì SP
-- ============================================================

USE GymDb;
GO

-- ============================================================
-- HELPER FUNCTION: Soft Delete
-- ============================================================
CREATE OR ALTER PROCEDURE sp_SoftDelete
    @TableName NVARCHAR(100),
    @RecordId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @IdColumn NVARCHAR(50) = @TableName + 'Id';
    
    SET @Sql = N'UPDATE ' + QUOTENAME(@TableName) + 
               N' SET IsDeleted = 1, DeletedAt = GETDATE()' +
               N' WHERE ' + QUOTENAME(@IdColumn) + N' = @RecordId AND IsDeleted = 0';
    
    EXEC sp_executesql @Sql, N'@RecordId INT', @RecordId;
END;
GO

-- ============================================================
-- MEMBER PROCEDURES
-- ============================================================

-- Get all members with pagination
CREATE OR ALTER PROCEDURE sp_Member_GetAll
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SearchTerm NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = NULL,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Get total count
    SELECT @TotalCount = COUNT(*)
    FROM Members
    WHERE IsDeleted = 0
        AND (@SearchTerm IS NULL OR 
             FullName LIKE '%' + @SearchTerm + '%' OR 
             Email LIKE '%' + @SearchTerm + '%' OR 
             Phone LIKE '%' + @SearchTerm + '%')
        AND (@Status IS NULL OR Status = @Status);
    
    -- Get paginated results
    SELECT 
        MemberId, FullName, Phone, Email, DateOfBirth, 
        JoinDate, Status, QRCodeValue, CreatedAt
    FROM Members
    WHERE IsDeleted = 0
        AND (@SearchTerm IS NULL OR 
             FullName LIKE '%' + @SearchTerm + '%' OR 
             Email LIKE '%' + @SearchTerm + '%' OR 
             Phone LIKE '%' + @SearchTerm + '%')
        AND (@Status IS NULL OR Status = @Status)
    ORDER BY MemberId DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- Get member by ID
CREATE OR ALTER PROCEDURE sp_Member_GetById
    @MemberId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        MemberId, FullName, Phone, Email, DateOfBirth, 
        JoinDate, Status, QRCodeValue, CreatedAt, UpdatedAt
    FROM Members
    WHERE MemberId = @MemberId AND IsDeleted = 0;
END;
GO

-- Get member by QRCode
CREATE OR ALTER PROCEDURE sp_Member_GetByQRCode
    @QRCodeValue NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        MemberId, FullName, Phone, Email, DateOfBirth, 
        JoinDate, Status, QRCodeValue, CreatedAt
    FROM Members
    WHERE QRCodeValue = @QRCodeValue AND IsDeleted = 0;
END;
GO

-- ============================================================
-- MEMBERSHIP PROCEDURES
-- ============================================================

-- Get active membership of member
CREATE OR ALTER PROCEDURE sp_Membership_GetActive
    @MemberId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP 1
        MembershipId, MemberId, MembershipType, Price, 
        StartDate, EndDate, Status, CreatedAt
    FROM Memberships
    WHERE MemberId = @MemberId 
        AND IsDeleted = 0
        AND Status = 'Active'
        AND EndDate >= CAST(GETDATE() AS DATE)
    ORDER BY EndDate DESC;
END;
GO

-- Get expiring memberships
CREATE OR ALTER PROCEDURE sp_Membership_GetExpiringSoon
    @DaysAhead INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        m.MembershipId, m.MemberId, mem.FullName, mem.Email, mem.Phone,
        m.MembershipType, m.EndDate,
        DATEDIFF(DAY, GETDATE(), m.EndDate) AS DaysRemaining
    FROM Memberships m
    INNER JOIN Members mem ON mem.MemberId = m.MemberId AND mem.IsDeleted = 0
    WHERE m.IsDeleted = 0
        AND m.Status = 'Active'
        AND m.EndDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE))
    ORDER BY m.EndDate ASC;
END;
GO

-- ============================================================
-- INVOICE PROCEDURES
-- ============================================================

-- Get overdue invoices
CREATE OR ALTER PROCEDURE sp_Invoice_GetOverdue
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Auto update status to Overdue
    UPDATE Invoices
    SET Status = 'Overdue', UpdatedAt = GETDATE()
    WHERE Status = 'Pending' 
        AND DueDate < CAST(GETDATE() AS DATE)
        AND IsDeleted = 0;
    
    -- Return overdue invoices
    SELECT 
        i.InvoiceId, i.MemberId, m.FullName, m.Email,
        i.Amount, i.IssueDate, i.DueDate, i.Status, i.Description
    FROM Invoices i
    INNER JOIN Members m ON m.MemberId = i.MemberId AND m.IsDeleted = 0
    WHERE i.Status = 'Overdue' AND i.IsDeleted = 0
    ORDER BY i.DueDate ASC;
END;
GO

-- ============================================================
-- PAYMENT PROCEDURES
-- ============================================================

-- Create payment and auto-update invoice status
CREATE OR ALTER PROCEDURE sp_Payment_CreateAndUpdateInvoice
    @InvoiceId INT,
    @Amount DECIMAL(18,2),
    @PaymentDate DATE,
    @PaymentMethod NVARCHAR(20),
    @Notes NVARCHAR(500) = NULL,
    @PaymentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Insert payment
        INSERT INTO Payments (InvoiceId, Amount, PaymentDate, PaymentMethod, Notes)
        VALUES (@InvoiceId, @Amount, @PaymentDate, @PaymentMethod, @Notes);
        
        SET @PaymentId = SCOPE_IDENTITY();
        
        -- Calculate total paid
        DECLARE @TotalPaid DECIMAL(18,2);
        DECLARE @InvoiceAmount DECIMAL(18,2);
        
        SELECT @InvoiceAmount = Amount
        FROM Invoices
        WHERE InvoiceId = @InvoiceId;
        
        SELECT @TotalPaid = SUM(Amount)
        FROM Payments
        WHERE InvoiceId = @InvoiceId AND IsDeleted = 0;
        
        -- Update invoice status if fully paid
        IF @TotalPaid >= @InvoiceAmount
        BEGIN
            UPDATE Invoices
            SET Status = 'Paid', UpdatedAt = GETDATE()
            WHERE InvoiceId = @InvoiceId;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================
-- CHECKIN PROCEDURES
-- ============================================================

-- Check-in by QR Code
CREATE OR ALTER PROCEDURE sp_Checkin_ByQRCode
    @QRCodeValue NVARCHAR(100),
    @SessionId INT = NULL,
    @CheckinId INT OUTPUT,
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MemberId INT;
    DECLARE @MemberName NVARCHAR(100);
    DECLARE @HasActiveMembership BIT = 0;
    
    -- Find member by QRCode
    SELECT @MemberId = MemberId, @MemberName = FullName
    FROM Members
    WHERE QRCodeValue = @QRCodeValue AND IsDeleted = 0;
    
    IF @MemberId IS NULL
    BEGIN
        SET @Message = N'QR Code không hợp lệ';
        RETURN;
    END
    
    -- Check active membership
    IF EXISTS (
        SELECT 1 FROM Memberships
        WHERE MemberId = @MemberId 
            AND IsDeleted = 0
            AND Status = 'Active'
            AND EndDate >= CAST(GETDATE() AS DATE)
    )
        SET @HasActiveMembership = 1;
    
    IF @HasActiveMembership = 0
    BEGIN
        SET @Message = N'Membership đã hết hạn. Vui lòng gia hạn!';
        RETURN;
    END
    
    -- Check duplicate checkin today
    IF EXISTS (
        SELECT 1 FROM Checkins
        WHERE MemberId = @MemberId 
            AND IsDeleted = 0
            AND CAST(CheckinTime AS DATE) = CAST(GETDATE() AS DATE)
    )
    BEGIN
        SET @Message = N'Bạn đã check-in hôm nay rồi!';
        RETURN;
    END
    
    -- Create checkin
    INSERT INTO Checkins (MemberId, SessionId, CheckinMethod)
    VALUES (@MemberId, @SessionId, 'QR');
    
    SET @CheckinId = SCOPE_IDENTITY();
    SET @Message = N'Check-in thành công! Chào mừng ' + @MemberName + N' đến với phòng gym.';
END;
GO

-- ============================================================
-- REPORT PROCEDURES
-- ============================================================

-- Get active members report
CREATE OR ALTER PROCEDURE sp_Report_ActiveMembers
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(DISTINCT m.MemberId) AS TotalActiveMembers,
        (SELECT COUNT(*) FROM Members 
         WHERE IsDeleted = 0 
           AND MONTH(JoinDate) = MONTH(GETDATE())
           AND YEAR(JoinDate) = YEAR(GETDATE())) AS NewMembersThisMonth,
        (SELECT COUNT(*) FROM Memberships ms
         WHERE ms.IsDeleted = 0
           AND ms.Status = 'Active'
           AND ms.EndDate BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE))) AS ExpiringThisMonth
    FROM Members m
    INNER JOIN Memberships ms ON ms.MemberId = m.MemberId
    WHERE m.IsDeleted = 0
        AND ms.IsDeleted = 0
        AND ms.Status = 'Active'
        AND ms.EndDate >= CAST(GETDATE() AS DATE);
END;
GO

-- Get revenue report
CREATE OR ALTER PROCEDURE sp_Report_Revenue
    @Month INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    
    SELECT 
        @Month AS Month,
        @Year AS Year,
        COUNT(DISTINCT i.InvoiceId) AS TotalInvoices,
        COALESCE(SUM(p.Amount), 0) AS TotalRevenue,
        COALESCE(SUM(CASE WHEN i.Status = 'Paid' THEN i.Amount ELSE 0 END), 0) AS TotalPaid,
        COALESCE(SUM(CASE WHEN i.Status = 'Pending' THEN i.Amount ELSE 0 END), 0) AS TotalPending
    FROM Invoices i
    LEFT JOIN Payments p ON p.InvoiceId = i.InvoiceId AND p.IsDeleted = 0
    WHERE i.IsDeleted = 0
        AND i.IssueDate BETWEEN @StartDate AND @EndDate;
END;
GO

-- ============================================================
-- SUMMARY
-- ============================================================
PRINT '✅ Stored procedures created successfully!';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_SoftDelete (helper)';
PRINT '  - sp_Member_GetAll';
PRINT '  - sp_Member_GetById';
PRINT '  - sp_Member_GetByQRCode';
PRINT '  - sp_Membership_GetActive';
PRINT '  - sp_Membership_GetExpiringSoon';
PRINT '  - sp_Invoice_GetOverdue';
PRINT '  - sp_Payment_CreateAndUpdateInvoice';
PRINT '  - sp_Checkin_ByQRCode';
PRINT '  - sp_Report_ActiveMembers';
PRINT '  - sp_Report_Revenue';
PRINT '';
PRINT '✅ Database setup complete!';
PRINT '';
PRINT 'Next: Update your C# code (see CHANGES_FOR_CODE.md)';
GO
