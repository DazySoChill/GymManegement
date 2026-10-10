namespace GymManegement.API.DTOs.MemberSchedule
{
    public class UpdateMemberScheduleRequest
    {
        public int DayOfWeek { get; set; }
        public string StartTime { get; set; } = string.Empty; // "HH:MM:SS"
        public string EndTime { get; set; } = string.Empty; // "HH:MM:SS"
        public bool IsActive { get; set; }
    }
}
