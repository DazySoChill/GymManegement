namespace GymManegement.DAL.Entities
{
    public class Trainer
    {
        public int TrainerId { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string? Phone { get; set; }

        public string? Specialization { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public ICollection<Schedule> Schedules { get; set; }
            = new List<Schedule>();

    }
}
