namespace GymManegement.DAL.Entities
{
    public class Schedule
    {
        public int ScheduleId { get; set; }

        public int MemberId { get; set; }

        public int TrainerId { get; set; }

        public int FacilityId { get; set; }

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        // Navigation
        public Member Member { get; set; } = null!;

        public Trainer Trainer { get; set; } = null!;

        public Facility Facility { get; set; } = null!;

        public ICollection<Session> Sessions { get; set; }
            = new List<Session>();
    }
}
