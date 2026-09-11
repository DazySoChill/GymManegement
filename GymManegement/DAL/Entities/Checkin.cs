namespace GymManegement.DAL.Entities
{
    public class Checkin
    {
        public int CheckinId { get; set; }

        public int MemberId { get; set; }

        public int SessionId { get; set; }

        public DateTime CheckinTime { get; set; }

        public string CheckinMethod { get; set; } = string.Empty;

        // Navigation
        public Member Member { get; set; } = null!;

        public Session Session { get; set; } = null!;
    }
}
