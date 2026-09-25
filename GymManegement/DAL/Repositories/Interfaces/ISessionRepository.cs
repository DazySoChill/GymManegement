using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ISessionRepository : IRepository<Session>
    {
        Task<IEnumerable<Session>> GetByScheduleIdAsync(int scheduleId);
        Task<IEnumerable<Session>> GetByStatusAsync(string status);
    }
}
