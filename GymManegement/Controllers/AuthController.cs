using GymManegement.API.DTOs.Auth;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _service;
        public AuthController(IAuthService service) => _service = service;

        /// <summary>Đăng nhập – trả về JWT token</summary>
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.LoginAsync(request);
            if (result == null)
                return Unauthorized(new { message = "Tên đăng nhập hoặc mật khẩu không đúng." });
            return Ok(result);
        }

        /// <summary>Đăng ký tài khoản mới - Auto tạo Member với QRCode</summary>
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                var result = await _service.RegisterAsync(request);
                return Ok(new { 
                    message = "Đăng ký thành công! Tài khoản đã được kích hoạt và Member được tạo tự động.", 
                    user = result 
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>Tạo tài khoản Admin hoặc Trainer (chỉ Admin)</summary>
        [HttpPost("create-staff")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateStaff([FromBody] CreateStaffRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            try
            {
                var result = await _service.CreateStaffAsync(request);
                return Ok(new { 
                    message = "Tạo tài khoản thành công!", 
                    user = result 
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>Đổi mật khẩu (yêu cầu đăng nhập)</summary>
        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var userIdStr = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
            if (!int.TryParse(userIdStr, out var userId)) return Unauthorized();
            var ok = await _service.ChangePasswordAsync(userId, request);
            return ok ? Ok(new { message = "Đổi mật khẩu thành công." })
                : BadRequest(new { message = "Mật khẩu cũ không đúng." });
        }

        /// <summary>Xem danh sách Users (Admin only)</summary>
        [HttpGet("users")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAllUsers()
            => Ok(await _service.GetAllUsersAsync());

        /// <summary>Khóa/mở tài khoản (Admin only)</summary>
        [HttpPut("users/{id:int}/active")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> SetActive(int id, [FromQuery] bool isActive)
        {
            var ok = await _service.SetActiveAsync(id, isActive);
            return ok ? Ok(new { message = isActive ? "Đã kích hoạt tài khoản." : "Đã khóa tài khoản." })
                : NotFound();
        }

        /// <summary>Thay đổi vai trò user (Admin only)</summary>
        [HttpPut("users/{id:int}/role")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateUserRole(int id, [FromBody] UpdateUserRoleRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Prevent admin from changing their own role
            var currentUserIdStr = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
            if (int.TryParse(currentUserIdStr, out var currentUserId) && currentUserId == id)
                return BadRequest(new { message = "Không thể thay đổi vai trò của chính mình." });

            var ok = await _service.UpdateUserRoleAsync(id, request.Role);
            return ok ? Ok(new { message = "Đã thay đổi vai trò thành công." })
                : NotFound(new { message = "Không tìm thấy user." });
        }

        /// <summary>Lấy thông tin user đang đăng nhập</summary>
        [HttpGet("me")]
        [Authorize]
        public IActionResult Me()
        {
            return Ok(new
            {
                userId = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub),
                username = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.UniqueName),
                fullName = User.FindFirstValue("fullName"),
                email = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email),
                role = User.FindFirstValue(ClaimTypes.Role) ?? User.FindFirstValue("role"),
                memberId = User.FindFirstValue("memberId")
            });
        }

        /// <summary>Alias for /me - frontend compatibility</summary>
        [HttpGet("profile")]
        [Authorize]
        public IActionResult GetProfile() => Me();
    }
}
