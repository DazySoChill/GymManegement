namespace GymManegement.DAL.Entities
{
    public class Session
    {
        public int SessionId { get; set; }

        public int ScheduleId { get; set; }

        public DateTime SessionDate { get; set; }

        public string Status { get; set; } = string.Empty;

        // Navigation
        public Schedule Schedule { get; set; } = null!;

        public ICollection<Checkin> Checkins { get; set; }
            = new List<Checkin>();
    }
}
