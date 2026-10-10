namespace GymManegement.API.DTOs.MemberSchedule
{
    public class CreateMemberScheduleRequest
    {
        public int MemberId { get; set; }
        public int DayOfWeek { get; set; } // 0-6
        public string StartTime { get; set; } = string.Empty; // "HH:MM:SS"
        public string EndTime { get; set; } = string.Empty; // "HH:MM:SS"
    }
}
