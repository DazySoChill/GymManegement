namespace GymManegement.API.DTOs.Facility
{
    public class CreateFacilityRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        /// <summary>Active | Maintenance | Inactive</summary>
        public string Status { get; set; } = "Active";
    }
}
