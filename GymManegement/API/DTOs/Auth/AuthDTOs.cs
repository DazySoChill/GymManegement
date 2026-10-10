using System.ComponentModel.DataAnnotations;

namespace GymManegement.API.DTOs.Auth
{
    public class LoginRequest
    {
        [Required] public string Username { get; set; } = string.Empty;
        [Required] public string Password { get; set; } = string.Empty;
    }

    public class LoginResponse
    {
        public string   Token     { get; set; } = string.Empty;
        public string   Username  { get; set; } = string.Empty;
        public string   FullName  { get; set; } = string.Empty;
        public string   Email     { get; set; } = string.Empty;
        public string   Role      { get; set; } = string.Empty;
        public int?     MemberId  { get; set; }  // Null if Admin/Trainer
        public DateTime ExpiresAt { get; set; }
    }

    /// <summary>
    /// Đăng ký tài khoản mới.
    /// Mặc định Role = "Member" và auto tạo Member record.
    /// </summary>
    public class RegisterRequest
    {
        [Required] public string Username { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
        public string Password { get; set; } = string.Empty;

        [Required]
        [MaxLength(100, ErrorMessage = "Tên người dùng không quá 100 ký tự.")]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty; // dùng cho gửi OTP/xác thực sau này
    }

    public class ChangePasswordRequest
    {
        [Required] public string OldPassword { get; set; } = string.Empty;
        [Required] public string NewPassword { get; set; } = string.Empty;
    }

    public class UserResponse
    {
        public int       UserId    { get; set; }
        public string    Username  { get; set; } = string.Empty;
        public string    FullName  { get; set; } = string.Empty;
        public string    Email     { get; set; } = string.Empty;
        public string    Role      { get; set; } = string.Empty;
        public bool      IsActive  { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public DateTime  CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
