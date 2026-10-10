using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByUsernameAsync(string username);
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByIdAsync(int id);
        Task<IEnumerable<User>> GetAllAsync();
        Task<User> CreateAsync(User entity, string plainPassword);
        Task UpdateAsync(User entity);
        Task UpdatePasswordAsync(int userId, string newPlainPassword);
        Task SetActiveAsync(int userId, bool isActive);
        Task<bool> UsernameExistsAsync(string username);
        Task<bool> EmailExistsAsync(string email);
        Task UpdateLastLoginAsync(int userId);
    }
}
