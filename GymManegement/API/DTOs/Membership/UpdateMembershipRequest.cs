namespace GymManegement.API.DTOs.Membership
{
    public class UpdateMembershipRequest
    {
        public string MembershipType { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; }
    }
}
