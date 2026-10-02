using GymManegement.API.DTOs.Auth;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse?> LoginAsync(LoginRequest request);
        Task<UserResponse>   RegisterAsync(RegisterRequest request);
        Task<bool>           ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task<IEnumerable<UserResponse>> GetAllUsersAsync();
        Task<bool>           SetActiveAsync(int userId, bool isActive);
    }
}
