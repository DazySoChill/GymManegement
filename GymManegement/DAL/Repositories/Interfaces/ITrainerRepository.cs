using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ITrainerRepository : IRepository<Trainer>
    {
        Task<Trainer?> GetByEmailAsync(string email);
        Task<IEnumerable<Trainer>> GetWithSchedulesAsync();
        Task<PagedResult<Trainer>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
    }
}
