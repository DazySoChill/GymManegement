namespace GymManegement.API.DTOs.MemberSchedule
{
    public class MemberScheduleResponse
    {
        public int PreferenceId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public int DayOfWeek { get; set; }
        public string DayOfWeekName { get; set; } = string.Empty;
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
