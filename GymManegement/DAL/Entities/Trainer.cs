namespace GymManegement.DAL.Entities
{
    public class Trainer
    {
        public int TrainerId { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Specialization { get; set; } = string.Empty;

        // Navigation
        public ICollection<Schedule> Schedules { get; set; }
            = new List<Schedule>();

    }
}
