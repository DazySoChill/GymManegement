namespace GymManegement.API.DTOs.Session
{
    public class SessionResponse
    {
        public int SessionId { get; set; }
        public int ScheduleId { get; set; }
        public DateTime SessionDate { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
