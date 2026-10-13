# 3. DATA FLOW CHI TIẾT - Request/Response Journey

## Mục lục

1. [Login Flow](#1-login-flow)
2. [Check-in Flow](#2-check-in-flow)
3. [Create Schedule Flow](#3-create-schedule-flow)
4. [Register for Session Flow](#4-register-for-session-flow)
5. [Generate Report Flow](#5-generate-report-flow)

---

## 1. Login Flow

### Step-by-step từ click button đến hiển thị dashboard

#### STEP 1: User nhập username/password và click "Đăng nhập"

**Frontend (index.html)**
```html
<form id="loginForm">
    <input type="text" id="username" value="admin">
    <input type="password" id="password" value="password">
    <button type="submit">Đăng nhập</button>
</form>
```

---

#### STEP 2: JavaScript xử lý form submit

**Frontend (wwwroot/js/app.js)**
```javascript
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    try {
        // Call API
        const response = await apiFetch('POST', '/api/Auth/login', {
            username: username,
            password: password
        });
        
        // Save token & user info
        localStorage.setItem('authToken', response.token);
        localStorage.setItem('currentUser', JSON.stringify(response));
        
        // Redirect to dashboard
        showDashboard();
    } catch (error) {
        alert('Đăng nhập thất bại: ' + error.message);
    }
});
```

**apiFetch() helper:**
```javascript
async function apiFetch(method, url, body = null) {
    const token = localStorage.getItem('authToken');
    
    const options = {
        method: method,
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    // Add token nếu có
    if (token) {
        options.headers['Authorization'] = `Bearer ${token}`;
    }
    
    // Add body nếu có
    if (body) {
        options.body = JSON.stringify(body);
    }
    
    const response = await fetch(API_BASE_URL + url, options);
    
    // Handle errors
    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Request failed');
    }
    
    return await response.json();
}
```

---

#### STEP 3: HTTP Request gửi đến server

**HTTP Request:**
```http
POST https://localhost:5001/api/Auth/login HTTP/1.1
Host: localhost:5001
Content-Type: application/json
Content-Length: 47

{
  "username": "admin",
  "password": "password"
}
```

---

#### STEP 4: ASP.NET Core Pipeline xử lý request

**Program.cs - Middleware Pipeline:**
```
Request → HTTPS Redirect
        → Global Exception Middleware
        → CORS
        → Static Files (bỏ qua vì /api/*)
        → Authentication (bỏ qua vì AllowAnonymous)
        → Authorization (bỏ qua vì AllowAnonymous)
        → Routing → AuthController.Login()
```

---

#### STEP 5: Controller nhận request

**Controllers/AuthController.cs**
```csharp
[HttpPost("login")]
[AllowAnonymous]  // Không cần token
public async Task<IActionResult> Login([FromBody] LoginRequest request)
{
    // 1. Validate ModelState
    if (!ModelState.IsValid) 
        return BadRequest(ModelState);
    
    // 2. Call service
    var result = await _service.LoginAsync(request);
    
    // 3. Check result
    if (result == null)
        return Unauthorized(new { 
            message = "Tên đăng nhập hoặc mật khẩu không đúng." 
        });
    
    // 4. Return success
    return Ok(result);
}
```

**LoginRequest DTO:**
```csharp
public class LoginRequest
{
    [Required]
    public string Username { get; set; }
    
    [Required]
    public string Password { get; set; }
}
```

---

#### STEP 6: Service xử lý business logic

**Service/BUS/Implementations/AuthService.cs**
```csharp
public async Task<LoginResponse?> LoginAsync(LoginRequest request)
{
    // 1. Tìm user by username
    var user = await _userRepo.GetByUsernameAsync(request.Username);
    
    // 2. Check user exists
    if (user == null) return null;
    
    // 3. Verify password với BCrypt
    bool passwordValid = BCrypt.Net.BCrypt.Verify(
        request.Password, 
        user.PasswordHash
    );
    
    if (!passwordValid) return null;
    
    // 4. Check user active
    if (!user.IsActive)
        throw new InvalidOperationException("Tài khoản chưa được kích hoạt.");
    
    // 5. Update last login
    await _userRepo.UpdateLastLoginAsync(user.UserId);
    
    // 6. Find MemberId nếu role = Member/Trainer
    int? memberId = null;
    if (user.Role == "Member" || user.Role == "Trainer")
    {
        var member = await _memberRepo.GetByEmailAsync(user.Email);
        memberId = member?.MemberId;
    }
    
    // 7. Generate JWT token
    var token = GenerateJwt(user, memberId);
    
    // 8. Calculate expiration
    var expiresAt = DateTime.UtcNow.AddHours(
        _config.GetValue<int>("Jwt:ExpiryHours", 24)
    );
    
    // 9. Return response
    return new LoginResponse
    {
        Token = token,
        Username = user.Username,
        FullName = user.FullName,
        Email = user.Email,
        Role = user.Role,
        MemberId = memberId,
        ExpiresAt = expiresAt
    };
}
```

**GenerateJwt() helper:**
```csharp
private string GenerateJwt(User user, int? memberId)
{
    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
        new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Role, user.Role),
        new Claim("fullName", user.FullName)
    };
    
    // Add memberId nếu có
    if (memberId.HasValue)
    {
        claims.Add(new Claim("memberId", memberId.Value.ToString()));
    }
    
    // Add trainerId nếu là Trainer
    if (user.Role == "Trainer")
    {
        var trainer = await _trainerRepo.GetByEmailAsync(user.Email);
        if (trainer != null)
        {
            claims.Add(new Claim("trainerId", trainer.TrainerId.ToString()));
        }
    }
    
    var key = new SymmetricSecurityKey(
        Encoding.UTF8.GetBytes(_config["Jwt:Key"])
    );
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    
    var token = new JwtSecurityToken(
        issuer: _config["Jwt:Issuer"],
        audience: _config["Jwt:Audience"],
        claims: claims,
        expires: DateTime.UtcNow.AddHours(24),
        signingCredentials: creds
    );
    
    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

---

#### STEP 7: Repository truy vấn database

**DAL/Repositories/Implementations/UserRepository.cs**
```csharp
public async Task<User?> GetByUsernameAsync(string username)
{
    var sql = @"
        SELECT UserId, Username, PasswordHash, FullName, Email, 
               Role, IsActive, LastLoginAt, CreatedAt, UpdatedAt
        FROM Users 
        WHERE Username = @username 
          AND IsDeleted = 0
    ";
    
    using var connection = _db.CreateConnection();
    return await connection.QueryFirstOrDefaultAsync<User>(
        sql, 
        new { username }
    );
}
```

**Dapper execution:**
```
1. Open SQL connection
2. Create SqlCommand với parameterized query
3. Execute query: SELECT * FROM Users WHERE Username = 'admin' AND IsDeleted = 0
4. Map result to User object
5. Return User hoặc null
```

---

#### STEP 8: SQL Server xử lý query

**SQL Execution Plan:**
```sql
SELECT UserId, Username, PasswordHash, FullName, Email, Role, IsActive, 
       LastLoginAt, CreatedAt, UpdatedAt
FROM Users 
WHERE Username = 'admin' AND IsDeleted = 0

-- Execution:
-- 1. Index Seek on IX_Users_Username (fast O(log n))
-- 2. Filter IsDeleted = 0
-- 3. Return 1 row
-- Time: ~1ms
```

**Result:**
```
UserId: 1
Username: admin
PasswordHash: $2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq
FullName: Quản Trị Viên
Email: admin@gymmanagement.vn
Role: Admin
IsActive: 1
```

---

#### STEP 9: Response trả về qua layers

**Repository → Service → Controller**

**LoginResponse:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwidW5pcXVlX25hbWUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AZ3ltbWFuYWdlbWVudC52biIsInJvbGUiOiJBZG1pbiIsImZ1bGxOYW1lIjoiUXXhuqNuIFRy4buLIFZpw6puIiwiZXhwIjoxNzA1NjYxMjM0fQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "username": "admin",
  "fullName": "Quản Trị Viên",
  "email": "admin@gymmanagement.vn",
  "role": "Admin",
  "memberId": null,
  "expiresAt": "2025-01-19T10:00:00Z"
}
```

---

#### STEP 10: Frontend nhận response

**wwwroot/js/app.js**
```javascript
// apiFetch() returns parsed JSON
const response = await apiFetch('POST', '/api/Auth/login', { ... });

// Save to localStorage
localStorage.setItem('authToken', response.token);
localStorage.setItem('currentUser', JSON.stringify({
    username: response.username,
    fullName: response.fullName,
    role: response.role,
    memberId: response.memberId
}));

// Update UI
showDashboard();
```

---

#### STEP 11: Hiển thị Dashboard

**wwwroot/js/app.js**
```javascript
function showDashboard() {
    // Hide login form
    document.getElementById('loginSection').style.display = 'none';
    
    // Show main app
    document.getElementById('mainApp').style.display = 'block';
    
    // Load dashboard page
    loadPage('dashboard');
    
    // Update navbar with user info
    const user = JSON.parse(localStorage.getItem('currentUser'));
    document.getElementById('userFullName').textContent = user.fullName;
    document.getElementById('userRole').textContent = user.role;
    
    // Show role-specific menu
    updateNavigation(user.role);
}
```

---

### Tổng thời gian xử lý

```
Frontend processing:      ~5ms
Network latency:          ~20ms (localhost)
ASP.NET Core routing:     ~1ms
Controller + Service:     ~2ms
Repository (Dapper):      ~1ms
SQL Server query:         ~1ms
BCrypt verify:            ~100ms (intentionally slow)
JWT generation:           ~2ms
Response serialization:   ~1ms
Network return:           ~20ms
Frontend render:          ~5ms
─────────────────────────────
TOTAL:                    ~158ms
```

**Bottleneck**: BCrypt verification (100ms) - đây là security feature, KHÔNG NÊN tối ưu.

---

## 2. Check-in Flow

### Member clicks "Check In" button

#### STEP 1: Frontend gửi request

**wwwroot/js/checkins.js**
```javascript
async function createCheckin() {
    try {
        // POST với empty body - memberId lấy từ JWT token
        const response = await apiFetch('POST', '/api/Checkins', {});
        
        alert('Check-in thành công!');
        loadMyCheckins(); // Reload list
    } catch (error) {
        alert('Lỗi: ' + error.message);
    }
}
```

---

#### STEP 2: HTTP Request

```http
POST https://localhost:5001/api/Checkins HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{}
```

---

#### STEP 3: JwtMiddleware validate token

**Middleware/JwtMiddleware.cs** (KHÔNG có trong project, ASP.NET Core tự động xử lý)

```csharp
// ASP.NET Core Authentication Middleware tự động:
// 1. Extract token từ Authorization header
var token = context.Request.Headers["Authorization"]
    .ToString().Replace("Bearer ", "");

// 2. Validate token
var tokenHandler = new JwtSecurityTokenHandler();
var principal = tokenHandler.ValidateToken(token, validationParameters, out _);

// 3. Check expiration
if (principal.Claims.First(c => c.Type == "exp").Value < DateTime.UtcNow)
    return Unauthorized();

// 4. Attach claims to HttpContext
context.User = principal;

// 5. Extract memberId từ claims
var memberId = principal.FindFirst("memberId")?.Value;
context.Items["MemberId"] = int.Parse(memberId);
```

---

#### STEP 4: Controller extract memberId từ token

**Controllers/CheckinsController.cs**
```csharp
[HttpPost]
[Authorize]  // Yêu cầu token hợp lệ
public async Task<IActionResult> Create()
{
    // Extract memberId từ JWT claims
    var memberIdStr = User.FindFirstValue("memberId");
    
    if (string.IsNullOrEmpty(memberIdStr))
        return BadRequest(new { message = "Không tìm thấy thông tin member." });
    
    var memberId = int.Parse(memberIdStr);
    
    // Call service
    var checkin = await _service.CreateCheckinAsync(memberId);
    
    return CreatedAtAction(nameof(GetById), 
        new { id = checkin.CheckinId }, 
        checkin
    );
}
```

---

#### STEP 5: Service validation

**Service/BUS/Implementations/CheckinService.cs**
```csharp
public async Task<CheckinResponse> CreateCheckinAsync(int memberId)
{
    // 1. Validate member exists
    var member = await _memberRepo.GetByIdAsync(memberId);
    if (member == null)
        throw new InvalidOperationException("Member không tồn tại.");
    
    // 2. Create checkin entity
    var checkin = new Checkin
    {
        MemberId = memberId,
        CheckinTime = DateTime.Now,
        CheckoutTime = null,
        CreatedAt = DateTime.Now,
        UpdatedAt = DateTime.Now,
        IsDeleted = false
    };
    
    // 3. Save to database
    var checkinId = await _checkinRepo.CreateAsync(checkin);
    checkin.CheckinId = checkinId;
    
    // 4. Return response DTO
    return new CheckinResponse
    {
        CheckinId = checkin.CheckinId,
        MemberId = checkin.MemberId,
        MemberName = member.FullName,
        CheckinTime = checkin.CheckinTime,
        CheckoutTime = checkin.CheckoutTime
    };
}
```

---

#### STEP 6: Repository insert record

**DAL/Repositories/Implementations/CheckinRepository.cs**
```csharp
public async Task<int> CreateAsync(Checkin checkin)
{
    var sql = @"
        INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted)
        OUTPUT INSERTED.CheckinId
        VALUES (@MemberId, @CheckinTime, @CheckoutTime, @CreatedAt, @UpdatedAt, @IsDeleted)
    ";
    
    using var connection = _db.CreateConnection();
    return await connection.ExecuteScalarAsync<int>(sql, checkin);
}
```

**SQL executed:**
```sql
INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted)
OUTPUT INSERTED.CheckinId
VALUES (1, '2025-01-18 14:30:00', NULL, '2025-01-18 14:30:00', '2025-01-18 14:30:00', 0)

-- Returns: CheckinId = 30
```

---

#### STEP 7: Response trả về

**HTTP Response:**
```http
HTTP/1.1 201 Created
Location: /api/Checkins/30
Content-Type: application/json

{
  "checkinId": 30,
  "memberId": 1,
  "memberName": "Nguyễn Thị Mai",
  "checkinTime": "2025-01-18T14:30:00",
  "checkoutTime": null
}
```

---

#### STEP 8: Frontend cập nhật UI

```javascript
// createCheckin() success callback
alert('Check-in thành công!');

// Reload check-ins list
loadMyCheckins();

// Update button state
document.getElementById('checkinBtn').disabled = true;
document.getElementById('checkinBtn').textContent = 'Đã check-in';
```

---

### Tổng thời gian: ~30ms

```
JWT validation:    ~2ms
Business logic:    ~1ms
SQL INSERT:        ~2ms
Response:          ~5ms
UI update:         ~5ms
─────────────────────
TOTAL:             ~15ms (cực nhanh!)
```

---

## 3. Create Schedule Flow

### Trainer tạo lịch tập mới

#### STEP 1: Trainer điền form

**wwwroot/schedules.html**
```html
<form id="createScheduleForm">
    <select id="trainerId">
        <option value="1">Nguyễn Văn An</option>
    </select>
    <select id="facilityId">
        <option value="1">Phòng Gym Tầng 1</option>
    </select>
    <input type="text" id="className" value="Cardio Buổi Sáng">
    <input type="datetime-local" id="startTime" value="2025-01-20T06:00">
    <input type="datetime-local" id="endTime" value="2025-01-20T07:30">
    <input type="number" id="maxCapacity" value="20">
    <button type="submit">Tạo lịch</button>
</form>
```

---

#### STEP 2: JavaScript submit

**wwwroot/js/schedules.js**
```javascript
document.getElementById('createScheduleForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
        trainerId: parseInt(document.getElementById('trainerId').value),
        facilityId: parseInt(document.getElementById('facilityId').value),
        className: document.getElementById('className').value,
        startTime: document.getElementById('startTime').value,
        endTime: document.getElementById('endTime').value,
        maxCapacity: parseInt(document.getElementById('maxCapacity').value)
    };
    
    try {
        await apiFetch('POST', '/api/Schedules', formData);
        alert('Tạo lịch thành công!');
        loadSchedules();
    } catch (error) {
        alert('Lỗi: ' + error.message);
    }
});
```

---

#### STEP 3: Controller với Authorization check

**Controllers/SchedulesController.cs**
```csharp
[HttpPost]
[Authorize(Roles = "Trainer,Admin")]
public async Task<IActionResult> Create([FromBody] CreateScheduleRequest request)
{
    // 1. Validate input
    if (!ModelState.IsValid) 
        return BadRequest(ModelState);
    
    // 2. Ownership check (nếu Trainer)
    var role = User.FindFirstValue(ClaimTypes.Role);
    if (role == "Trainer")
    {
        var currentTrainerIdStr = User.FindFirstValue("trainerId");
        var currentTrainerId = int.Parse(currentTrainerIdStr);
        
        if (request.TrainerId != currentTrainerId)
        {
            return Forbid(); // 403 Forbidden
        }
    }
    
    // 3. Call service
    try
    {
        var schedule = await _service.CreateScheduleAsync(request);
        return CreatedAtAction(nameof(GetById), 
            new { id = schedule.ScheduleId }, 
            schedule
        );
    }
    catch (InvalidOperationException ex)
    {
        return BadRequest(new { message = ex.Message });
    }
}
```

---

#### STEP 4: Service conflict detection

**Service/BUS/Implementations/ScheduleService.cs**
```csharp
public async Task<ScheduleResponse> CreateScheduleAsync(CreateScheduleRequest request)
{
    // 1. Validate trainer exists
    var trainer = await _trainerRepo.GetByIdAsync(request.TrainerId);
    if (trainer == null)
        throw new InvalidOperationException("Trainer không tồn tại.");
    
    // 2. Validate facility exists
    var facility = await _facilityRepo.GetByIdAsync(request.FacilityId);
    if (facility == null)
        throw new InvalidOperationException("Facility không tồn tại.");
    
    // 3. Check time conflict
    var hasConflict = await _scheduleRepo.HasConflictAsync(
        request.TrainerId,
        request.FacilityId,
        request.StartTime,
        request.EndTime,
        excludeScheduleId: null
    );
    
    if (hasConflict)
    {
        throw new InvalidOperationException(
            "Trainer hoặc Facility đã có lịch trùng giờ."
        );
    }
    
    // 4. Create schedule
    var schedule = new Schedule
    {
        TrainerId = request.TrainerId,
        FacilityId = request.FacilityId,
        ClassName = request.ClassName,
        StartTime = request.StartTime,
        EndTime = request.EndTime,
        MaxCapacity = request.MaxCapacity,
        CreatedAt = DateTime.Now,
        UpdatedAt = DateTime.Now,
        IsDeleted = false
    };
    
    var scheduleId = await _scheduleRepo.CreateAsync(schedule);
    schedule.ScheduleId = scheduleId;
    
    // 5. Return response
    return new ScheduleResponse
    {
        ScheduleId = schedule.ScheduleId,
        TrainerId = trainer.TrainerId,
        TrainerName = trainer.FullName,
        FacilityId = facility.FacilityId,
        FacilityName = facility.Name,
        ClassName = schedule.ClassName,
        StartTime = schedule.StartTime,
        EndTime = schedule.EndTime,
        MaxCapacity = schedule.MaxCapacity
    };
}
```

---

#### STEP 5: Repository conflict check

**DAL/Repositories/Implementations/ScheduleRepository.cs**
```csharp
public async Task<bool> HasConflictAsync(
    int trainerId, 
    int facilityId,
    DateTime startTime, 
    DateTime endTime,
    int? excludeScheduleId = null)
{
    var sql = @"
        SELECT COUNT(*) 
        FROM Schedules
        WHERE (TrainerId = @trainerId OR FacilityId = @facilityId)
          AND IsDeleted = 0
          AND (
              (@start >= StartTime AND @start < EndTime) OR
              (@end > StartTime AND @end <= EndTime) OR
              (@start <= StartTime AND @end >= EndTime)
          )
          AND (@excludeId IS NULL OR ScheduleId != @excludeId)
    ";
    
    using var connection = _db.CreateConnection();
    var count = await connection.ExecuteScalarAsync<int>(sql, new {
        trainerId,
        facilityId,
        start = startTime,
        end = endTime,
        excludeId = excludeScheduleId
    });
    
    return count > 0;
}
```

**SQL executed:**
```sql
SELECT COUNT(*) 
FROM Schedules
WHERE (TrainerId = 1 OR FacilityId = 1)
  AND IsDeleted = 0
  AND (
      ('2025-01-20 06:00' >= StartTime AND '2025-01-20 06:00' < EndTime) OR
      ('2025-01-20 07:30' > StartTime AND '2025-01-20 07:30' <= EndTime) OR
      ('2025-01-20 06:00' <= StartTime AND '2025-01-20 07:30' >= EndTime)
  )

-- Returns: 0 (no conflict) hoặc 1+ (có conflict)
```

---

#### STEP 6: Insert nếu không conflict

```sql
INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted)
OUTPUT INSERTED.ScheduleId
VALUES (1, 1, N'Cardio Buổi Sáng', '2025-01-20 06:00', '2025-01-20 07:30', 20, GETDATE(), GETDATE(), 0)

-- Returns: ScheduleId = 21
```

---

#### STEP 7: Response

```json
{
  "scheduleId": 21,
  "trainerId": 1,
  "trainerName": "Nguyễn Văn An",
  "facilityId": 1,
  "facilityName": "Phòng Gym Tầng 1",
  "className": "Cardio Buổi Sáng",
  "startTime": "2025-01-20T06:00:00",
  "endTime": "2025-01-20T07:30:00",
  "maxCapacity": 20
}
```

---

## 4. Register for Session Flow

**(Tương tự, member đăng ký vào lịch)**

## 5. Generate Report Flow

**(Admin export Excel, tương tự)**

---

## Tổng kết Data Flow Patterns

### Pattern 1: Read Operation (GET)
```
Frontend → API Call → Controller → Service → Repository → SQL SELECT → Return
Time: ~10-20ms
```

### Pattern 2: Create Operation (POST)
```
Frontend → API Call → JwtMiddleware → Controller → Service (validation) → Repository → SQL INSERT → Return
Time: ~20-50ms
```

### Pattern 3: Create with Business Logic (POST + validation)
```
Frontend → API Call → JwtMiddleware → Controller (authorization) → Service (validation + conflict check) → Multiple SQL queries → Repository → SQL INSERT → Return
Time: ~50-100ms
```

### Pattern 4: Authentication (POST /login)
```
Frontend → API Call → Controller → Service → Repository (get user) → BCrypt verify (100ms) → Generate JWT → Return
Time: ~150ms (BCrypt intentionally slow)
```

---

**Lưu ý quan trọng:**
- JWT validation ở mỗi request (~2ms overhead - acceptable)
- BCrypt slow by design (security > performance)
- Dapper queries cực nhanh (~1-5ms)
- Business logic không nên quá phức tạp (keep under 10ms)
- Total response time < 200ms là tốt

---

**Tài liệu tiếp theo:**
- [04-DATABASE-SCHEMA.md](./04-DATABASE-SCHEMA.md) - Chi tiết schema và relationships
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Tham khảo nhanh
