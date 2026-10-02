using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByUsernameAsync(string username);
        Task<User?> GetByIdAsync(int id);
        Task<IEnumerable<User>> GetAllAsync();
        Task<User> CreateAsync(User entity, string plainPassword);
        Task UpdatePasswordAsync(int userId, string newPlainPassword);
        Task SetActiveAsync(int userId, bool isActive);
    }
}
