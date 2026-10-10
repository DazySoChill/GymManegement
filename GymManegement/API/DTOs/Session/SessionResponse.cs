namespace GymManegement.API.DTOs.Session
{
    public class SessionResponse
    {
        public int SessionId { get; set; }
        public int MemberId { get; set; }
        public int ScheduleId { get; set; }
        public DateTime RegistrationDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
