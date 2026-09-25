using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ITrainerRepository : IRepository<Trainer>
    {
        Task<Trainer?> GetByEmailAsync(string email);
        Task<IEnumerable<Trainer>> GetWithSchedulesAsync();
    }
}
