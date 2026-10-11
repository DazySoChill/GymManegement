using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IScheduleRepository : IRepository<Schedule>
    {
        Task<IEnumerable<Schedule>> GetByTrainerIdAsync(int trainerId);
        Task<IEnumerable<Schedule>> GetByFacilityIdAsync(int facilityId);
        /// <summary>Lấy lịch theo ngày cụ thể</summary>
        Task<IEnumerable<Schedule>> GetByDateAsync(DateTime date);
        /// <summary>Kiểm tra xung đột lịch: trainer/phòng đã bận trong khoảng thời gian chưa</summary>
        Task<bool> HasConflictAsync(int trainerId, int facilityId, DateTime start, DateTime end, int? excludeScheduleId = null);
        Task<PagedResult<Schedule>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<List<Schedule>> GetByIdsAsync(List<int> scheduleIds);
    }
}
