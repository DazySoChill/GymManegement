namespace GymManegement.DAL.Entities
{
    public class MemberSchedulePreference
    {
        public int PreferenceId { get; set; }
        public int MemberId { get; set; }
        public int DayOfWeek { get; set; } // 0=Sunday, 1=Monday...6=Saturday
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Navigation
        public Member Member { get; set; } = null!;
    }
}
