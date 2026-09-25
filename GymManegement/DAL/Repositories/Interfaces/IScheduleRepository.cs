using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IScheduleRepository : IRepository<Schedule>
    {
        Task<IEnumerable<Schedule>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Schedule>> GetByTrainerIdAsync(int trainerId);
        Task<IEnumerable<Schedule>> GetByFacilityIdAsync(int facilityId);
        /// <summary>Kiểm tra xung đột lịch: trainer/phòng đã bận trong khoảng thời gian chưa</summary>
        Task<bool> HasConflictAsync(int trainerId, int facilityId, DateTime start, DateTime end, int? excludeScheduleId = null);
    }
}
