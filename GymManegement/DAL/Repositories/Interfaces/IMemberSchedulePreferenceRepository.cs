using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IMemberSchedulePreferenceRepository : IRepository<MemberSchedulePreference>
    {
        Task<IEnumerable<MemberSchedulePreference>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<MemberSchedulePreference>> GetByDayOfWeekAsync(int dayOfWeek);
    }
}
