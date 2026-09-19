namespace GymManegement.API.DTOs.Session
{
    public class CreateSessionRequest
    {
        public int ScheduleId { get; set; }
        public DateTime SessionDate { get; set; }
        /// <summary>Scheduled | Completed | Cancelled</summary>
        public string Status { get; set; } = "Scheduled";
    }
}
