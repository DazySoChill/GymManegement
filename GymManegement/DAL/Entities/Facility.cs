namespace GymManegement.DAL.Entities
{
    public class Facility
    {
        public int FacilityId { get; set; }

        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        /// <summary>Status: Available | Maintenance | OutOfService</summary>
        public string Status { get; set; } = "Available";

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public ICollection<Schedule> Schedules { get; set; }
            = new List<Schedule>();
    }
}
