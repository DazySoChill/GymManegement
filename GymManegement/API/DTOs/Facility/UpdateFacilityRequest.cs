namespace GymManegement.API.DTOs.Facility
{
    public class UpdateFacilityRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}
