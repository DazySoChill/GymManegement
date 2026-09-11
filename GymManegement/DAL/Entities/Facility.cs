namespace GymManegement.DAL.Entities
{
    public class Facility
    {
        public int FacilityId { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        // Navigation
        public ICollection<Schedule> Schedules { get; set; }
            = new List<Schedule>();
    }
}
