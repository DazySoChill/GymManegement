namespace GymManegement.API.DTOs.Facility
{
    public class UpdateFacilityRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        /// <summary>Active | Maintenance | Inactive</summary>
        public string Status { get; set; } = string.Empty;
    }
}
