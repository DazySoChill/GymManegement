using System.ComponentModel.DataAnnotations;

namespace GymManegement.API.DTOs.Auth
{
    /// <summary>
    /// Admin tạo tài khoản Admin hoặc Trainer.
    /// Chỉ Admin có quyền gọi endpoint này.
    /// </summary>
    public class CreateStaffRequest
    {
        [Required]
        [MaxLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự.")]
        public string Password { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [RegularExpression("^(Admin|Trainer)$", ErrorMessage = "Role phải là 'Admin' hoặc 'Trainer'.")]
        public string Role { get; set; } = string.Empty; // "Admin" or "Trainer" only
    }
}
