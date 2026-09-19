namespace GymManegement.API.DTOs.Facility
{
    public class FacilityResponse
    {
        public int FacilityId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}
