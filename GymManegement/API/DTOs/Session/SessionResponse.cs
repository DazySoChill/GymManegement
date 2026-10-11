namespace GymManegement.API.DTOs.Session
{
    public class SessionResponse
    {
        public int SessionId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public int ScheduleId { get; set; }
        public string ClassName { get; set; } = string.Empty;
        public string TrainerName { get; set; } = string.Empty;
        public DateTime? ClassStartTime { get; set; }
        public DateTime? ClassEndTime { get; set; }
        public DateTime RegistrationDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
