using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ISessionRepository : IRepository<Session>
    {
        Task<IEnumerable<Session>> GetByScheduleIdAsync(int scheduleId);
        Task<IEnumerable<Session>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Session>> GetByStatusAsync(string status);
        Task<PagedResult<Session>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
    }
}
