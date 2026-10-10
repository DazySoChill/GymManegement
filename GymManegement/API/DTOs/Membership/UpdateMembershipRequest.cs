namespace GymManegement.API.DTOs.Membership
{
    public class UpdateMembershipRequest
    {
        public string PackageName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
