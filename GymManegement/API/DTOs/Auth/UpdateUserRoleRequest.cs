using System.ComponentModel.DataAnnotations;

namespace GymManegement.API.DTOs.Auth
{
    public class UpdateUserRoleRequest
    {
        [Required(ErrorMessage = "Role is required")]
        [RegularExpression("^(Admin|Trainer|Member)$", ErrorMessage = "Role must be Admin, Trainer, or Member")]
        public string Role { get; set; } = string.Empty;
    }
}
