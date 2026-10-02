using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using GymManegement.API.DTOs.Auth;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.IdentityModel.Tokens;

namespace GymManegement.Service.BUS.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepo;
        private readonly IConfiguration  _config;

        public AuthService(IUserRepository userRepo, IConfiguration config)
        {
            _userRepo = userRepo;
            _config   = config;
        }

        public async Task<LoginResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _userRepo.GetByUsernameAsync(request.Username);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return null;

            var token   = GenerateJwt(user);
            var expires = DateTime.UtcNow.AddHours(
                _config.GetValue<int>("Jwt:ExpiryHours", 8));

            return new LoginResponse
            {
                Token     = token,
                Username  = user.Username,
                Role      = user.Role,
                MemberId  = user.MemberId,
                TrainerId = user.TrainerId,
                ExpiresAt = expires
            };
        }

        public async Task<UserResponse> RegisterAsync(RegisterRequest request)
        {
            var entity = new User
            {
                Username  = request.Username,
                Role      = request.Role,
                MemberId  = request.MemberId,
                TrainerId = request.TrainerId,
                IsActive  = true
            };
            await _userRepo.CreateAsync(entity, request.Password);
            return ToResponse(entity);
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

        // ── JWT Generation ─────────────────────────────────────────
        private string GenerateJwt(User user)
        {
            var key     = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds   = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expires = DateTime.UtcNow.AddHours(_config.GetValue<int>("Jwt:ExpiryHours", 8));

            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub,  user.UserId.ToString()),
                new(JwtRegisteredClaimNames.UniqueName, user.Username),
                new(ClaimTypes.Role,              user.Role),
                new("role",                       user.Role),
                new(JwtRegisteredClaimNames.Jti,  Guid.NewGuid().ToString()),
            };

            if (user.MemberId.HasValue)
                claims.Add(new Claim("memberId",  user.MemberId.Value.ToString()));
            if (user.TrainerId.HasValue)
                claims.Add(new Claim("trainerId", user.TrainerId.Value.ToString()));

            var token = new JwtSecurityToken(
                issuer:   _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims:   claims,
                expires:  expires,
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static UserResponse ToResponse(User u) => new()
        {
            UserId    = u.UserId,
            Username  = u.Username,
            Role      = u.Role,
            MemberId  = u.MemberId,
            TrainerId = u.TrainerId,
            IsActive  = u.IsActive,
            CreatedAt = u.CreatedAt
        };
    }
}
