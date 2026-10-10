using GymManegement.API.DTOs.MemberSchedule;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IMemberSchedulePreferenceService
    {
        Task<MemberScheduleResponse?> GetByIdAsync(int preferenceId);
        Task<IEnumerable<MemberScheduleResponse>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<MemberScheduleResponse>> GetByDayOfWeekAsync(int dayOfWeek);
        Task<MemberScheduleResponse> CreateAsync(CreateMemberScheduleRequest request);
        Task<MemberScheduleResponse?> UpdateAsync(int preferenceId, UpdateMemberScheduleRequest request);
        Task<bool> DeleteAsync(int preferenceId);
    }
}
