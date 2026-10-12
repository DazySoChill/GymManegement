using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Dapper;
using GymManegement.API.DTOs.Auth;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.IdentityModel.Tokens;

namespace GymManegement.Service.BUS.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepo;
        private readonly IMemberRepository _memberRepo;
        private readonly ITrainerRepository _trainerRepo;
        private readonly DapperContext _db;
        private readonly IConfiguration _config;

        public AuthService(IUserRepository userRepo, IMemberRepository memberRepo, ITrainerRepository trainerRepo, DapperContext db, IConfiguration config)
        {
            _userRepo = userRepo;
            _memberRepo = memberRepo;
            _trainerRepo = trainerRepo;
            _db = db;
            _config = config;
        }

        /// <summary>
        /// Login: Tìm User by Username, lấy MemberId từ Members table via Email
        /// </summary>
        public async Task<LoginResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _userRepo.GetByUsernameAsync(request.Username);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return null;

            if (!user.IsActive)
                throw new InvalidOperationException("Tài khoản chưa được kích hoạt.");

            // Update last login
            await _userRepo.UpdateLastLoginAsync(user.UserId);

            // Find MemberId if role is Member
            int? memberId = null;
            if (user.Role == "Member")
            {
                var member = await _memberRepo.GetByEmailAsync(user.Email);
                memberId = member?.MemberId;
            }

            var token = GenerateJwt(user, memberId);
            var expiresAt = DateTime.UtcNow.AddHours(_config.GetValue<int>("Jwt:ExpiryHours", 8));

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

        /// <summary>
        /// Register: Tạo User với Role="Member", auto tạo Member với QRCode
        /// </summary>
        public async Task<UserResponse> RegisterAsync(RegisterRequest request)
        {
            // Validate
            if (await _userRepo.UsernameExistsAsync(request.Username))
                throw new InvalidOperationException("Tên đăng nhập đã tồn tại.");

            if (await _userRepo.EmailExistsAsync(request.Email))
                throw new InvalidOperationException("Email đã được sử dụng.");

            // 1. Create User với Role = "Member"
            var user = new User
            {
                Username = request.Username.Trim(),
                FullName = request.FullName.Trim(),
                Email = request.Email.Trim().ToLowerInvariant(),
                Role = "Member", // Auto Member
                IsActive = true  // Active immediately (no OTP verification)
            };
            await _userRepo.CreateAsync(user, request.Password);

            // 2. Auto create Member with sequential QRCode
            // Get next available MemberId from sequence to generate QRCode before insert
            using var conn = _db.CreateConnection();
            
            // Get next MemberId (IDENT_CURRENT returns last inserted, add 1 for next)
            var nextMemberId = await conn.ExecuteScalarAsync<int>(
                "SELECT ISNULL(IDENT_CURRENT('Members'), 0) + 1");
            
            var qrCode = $"M{nextMemberId:D6}";
            
            var member = new Member
            {
                FullName = user.FullName,
                Email = user.Email,
                Phone = null, // Nullable
                DateOfBirth = null, // Nullable
                QRCode = qrCode // Pre-generated sequential QRCode
            };
            await _memberRepo.CreateAsync(member);

            return ToResponse(user);
        }

        /// <summary>
        /// CreateStaff: Admin tạo tài khoản Admin hoặc Trainer (không tạo Member)
        /// </summary>
        public async Task<UserResponse> CreateStaffAsync(CreateStaffRequest request)
        {
            // Validate
            if (await _userRepo.UsernameExistsAsync(request.Username))
                throw new InvalidOperationException("Tên đăng nhập đã tồn tại.");

            if (await _userRepo.EmailExistsAsync(request.Email))
                throw new InvalidOperationException("Email đã được sử dụng.");

            if (request.Role != "Admin" && request.Role != "Trainer")
                throw new InvalidOperationException("Role phải là 'Admin' hoặc 'Trainer'.");

            // Create User
            var user = new User
            {
                Username = request.Username.Trim(),
                FullName = request.FullName.Trim(),
                Email = request.Email.Trim().ToLowerInvariant(),
                Role = request.Role,
                IsActive = true
            };
            await _userRepo.CreateAsync(user, request.Password);

            // Auto-create Trainer record if role is Trainer
            if (user.Role == "Trainer")
            {
                try
                {
                    var existingTrainer = await _trainerRepo.GetByEmailAsync(user.Email);
                    if (existingTrainer == null)
                    {
                        var trainer = new Trainer
                        {
                            FullName = user.FullName,
                            Email = user.Email,
                            Phone = string.Empty,
                            Specialization = "General"
                        };
                        await _trainerRepo.CreateAsync(trainer);
                    }
                }
                catch (Exception ex)
                {
                    // Log warning but don't fail User creation
                    Console.WriteLine($"[WARNING] Failed to auto-create Trainer record for {user.Email}: {ex.Message}");
                }
            }

            return ToResponse(user);
        }

        public async Task<bool> ChangePasswordAsync(int userId, ChangePasswordRequest request)
        {
            var user = await _userRepo.GetByIdAsync(userId);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.OldPassword, user.PasswordHash))
                return false;

            await _userRepo.UpdatePasswordAsync(userId, request.NewPassword);
            return true;
        }

        public async Task<IEnumerable<UserResponse>> GetAllUsersAsync()
        {
            var users = await _userRepo.GetAllAsync();
            return users.Select(ToResponse);
        }

        public async Task<bool> SetActiveAsync(int userId, bool isActive)
        {
            var user = await _userRepo.GetByIdAsync(userId);
            if (user is null) return false;

            await _userRepo.SetActiveAsync(userId, isActive);
            return true;
        }

        public async Task<bool> UpdateUserRoleAsync(int userId, string newRole)
        {
            // Validate role
            var validRoles = new[] { "Admin", "Trainer", "Member" };
            if (!validRoles.Contains(newRole))
                return false;

            // Get user
            var user = await _userRepo.GetByIdAsync(userId);
            if (user is null)
                return false;

            // Update role
            user.Role = newRole;
            await _userRepo.UpdateAsync(user);

            // Auto-create Trainer/Member record if missing for the new role
            try
            {
                if (newRole == "Trainer")
                {
                    var existingTrainer = await _trainerRepo.GetByEmailAsync(user.Email);
                    if (existingTrainer == null)
                    {
                        var trainer = new Trainer
                        {
                            FullName = user.FullName,
                            Email = user.Email,
                            Phone = string.Empty,
                            Specialization = "General"
                        };
                        await _trainerRepo.CreateAsync(trainer);
                    }
                }
                else if (newRole == "Member")
                {
                    var existingMember = await _memberRepo.GetByEmailAsync(user.Email);
                    if (existingMember == null)
                    {
                        using var conn = _db.CreateConnection();
                        var nextMemberId = await conn.ExecuteScalarAsync<int>(
                            "SELECT ISNULL(IDENT_CURRENT('Members'), 0) + 1");
                        var qrCode = $"M{nextMemberId:D6}";
                        var member = new Member
                        {
                            FullName = user.FullName,
                            Email = user.Email,
                            Phone = null,
                            DateOfBirth = null,
                            QRCode = qrCode
                        };
                        await _memberRepo.CreateAsync(member);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[WARNING] Failed to auto-create Trainer/Member record for {user.Email}: {ex.Message}");
            }

            return true;
        }

        private string GenerateJwt(User user, int? memberId)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expires = DateTime.UtcNow.AddHours(_config.GetValue<int>("Jwt:ExpiryHours", 8));

            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
                new(JwtRegisteredClaimNames.UniqueName, user.Username),
                new(JwtRegisteredClaimNames.Email, user.Email),
                new("fullName", user.FullName),
                new(ClaimTypes.Role, user.Role),
                new("role", user.Role),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            if (memberId.HasValue)
                claims.Add(new Claim("memberId", memberId.Value.ToString()));

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static UserResponse ToResponse(User u) => new()
        {
            UserId = u.UserId,
            Username = u.Username,
            FullName = u.FullName,
            Email = u.Email,
            Role = u.Role,
            IsActive = u.IsActive,
            LastLoginAt = u.LastLoginAt,
            CreatedAt = u.CreatedAt,
            UpdatedAt = u.UpdatedAt
        };
    }
}
