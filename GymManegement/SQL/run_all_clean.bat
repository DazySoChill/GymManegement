@echo off
REM ============================================================
REM GymDb - Clean Rebuild Script
REM Chạy: Double-click file này hoặc chạy từ cmd/PowerShell as Admin
REM Yêu cầu: SQL Server LocalDB hoặc Express đang chạy
REM ============================================================

set SERVER=(localdb)\MSSQLLocalDB
REM Thay đổi SERVER nếu dùng instance khác, ví dụ:
REM set SERVER=localhost
REM set SERVER=.\SQLEXPRESS

set MASTER_DB=master
set TARGET_DB=GymDb
set SQL_DIR=%~dp0

echo ============================================================
echo GymDb Clean Rebuild
echo Server: %SERVER%
echo Target DB: %TARGET_DB%
echo SQL Dir: %SQL_DIR%
echo ============================================================

REM 1. Drop database if exists (force close connections)
echo [1/5] Dropping existing database...
sqlcmd -S %SERVER% -d %MASTER_DB% -Q "IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'%TARGET_DB%') BEGIN ALTER DATABASE [%TARGET_DB%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [%TARGET_DB%]; END" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi khi drop database. Kiểm tra SQL Server có chạy không.
    pause
    exit /b 1
)
echo ✅ Database dropped.

REM 2. Create fresh database
echo [2/5] Creating fresh database...
sqlcmd -S %SERVER% -d %MASTER_DB% -Q "CREATE DATABASE [%TARGET_DB%];" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi khi create database.
    pause
    exit /b 1
)
echo ✅ Database created.

REM 3. Run schema (01_Schema.sql)
echo [3/6] Running 01_Schema.sql...
sqlcmd -S %SERVER% -d %TARGET_DB% -i "%SQL_DIR%01_Schema.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi chạy 01_Schema.sql
    pause
    exit /b 1
)
echo ✅ Schema done.

REM 4. Run seed data (03_SeedData.sql) - PHẢI chạy TRƯỚC Users vì nó DELETE FROM Users
echo [4/6] Running 03_SeedData.sql...
sqlcmd -S %SERVER% -d %TARGET_DB% -i "%SQL_DIR%03_SeedData.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi chạy 03_SeedData.sql
    pause
    exit /b 1
)
echo ✅ Seed data done.

REM 5. Seed users (04_Users.sql) - chạy SAU SeedData
echo [5/6] Running 04_Users.sql...
sqlcmd -S %SERVER% -d %TARGET_DB% -i "%SQL_DIR%04_Users.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi chạy 04_Users.sql
    pause
    exit /b 1
)
echo ✅ Users seeded.

REM 6. Run programmability (02_Programmability.sql)
echo [6/6] Running 02_Programmability.sql...
sqlcmd -S %SERVER% -d %TARGET_DB% -i "%SQL_DIR%02_Programmability.sql" -b
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Lỗi chạy 02_Programmability.sql
    pause
    exit /b 1
)
echo ✅ Programmability done.

echo ============================================================
echo 🎉 HOÀN TẤT - GymDb rebuilt successfully!
echo ============================================================
echo Kiểm tra nhanh:
sqlcmd -S %SERVER% -d %TARGET_DB% -Q "SELECT 'Members:' AS TableName, COUNT(*) AS Count FROM Members UNION ALL SELECT 'Trainers', COUNT(*) FROM Trainers UNION ALL SELECT 'Memberships', COUNT(*) FROM Memberships UNION ALL SELECT 'Schedules', COUNT(*) FROM Schedules UNION ALL SELECT 'Checkins', COUNT(*) FROM Checkins UNION ALL SELECT 'Invoices', COUNT(*) FROM Invoices UNION ALL SELECT 'Users', COUNT(*) FROM Users;"

pause
