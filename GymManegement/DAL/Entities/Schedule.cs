namespace GymManegement.DAL.Entities
{
    public class Schedule
    {
        public int ScheduleId { get; set; }

        public int TrainerId { get; set; }

        public int FacilityId { get; set; }

        public string ClassName { get; set; } = string.Empty;

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public int MaxCapacity { get; set; } = 20;

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Trainer Trainer { get; set; } = null!;

        public Facility Facility { get; set; } = null!;

        public ICollection<Session> Sessions { get; set; }
            = new List<Session>();
    }
}
