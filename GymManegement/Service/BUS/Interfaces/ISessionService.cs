using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Session;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface ISessionService
    {
        Task<PagedResult<SessionResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<SessionResponse?> GetByIdAsync(int id);
        Task<IEnumerable<SessionResponse>> GetByScheduleIdAsync(int scheduleId);
        Task<IEnumerable<SessionResponse>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<SessionResponse>> GetByStatusAsync(string status);
        Task<SessionResponse> CreateAsync(CreateSessionRequest request);
        Task<SessionResponse?> UpdateAsync(int id, UpdateSessionRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
