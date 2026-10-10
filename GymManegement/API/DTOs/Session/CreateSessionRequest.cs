namespace GymManegement.API.DTOs.Session
{
    public class CreateSessionRequest
    {
        public int MemberId { get; set; }
        public int ScheduleId { get; set; }
        
        /// <summary>Registration date/time. Defaults to current UTC time if not provided</summary>
        public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
        
        /// <summary>Status: Registered | Attended | Cancelled</summary>
        public string Status { get; set; } = "Registered";
    }
}
