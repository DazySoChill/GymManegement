using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Schedule;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IScheduleService
    {
        Task<PagedResult<ScheduleResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<ScheduleResponse?> GetByIdAsync(int id);
        Task<IEnumerable<ScheduleResponse>> GetByTrainerIdAsync(int trainerId);
        Task<IEnumerable<ScheduleResponse>> GetByFacilityIdAsync(int facilityId);
        Task<IEnumerable<ScheduleResponse>> GetByDateAsync(DateTime date);
        Task<ScheduleResponse> CreateAsync(CreateScheduleRequest request);
        Task<ScheduleResponse?> UpdateAsync(int id, UpdateScheduleRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
