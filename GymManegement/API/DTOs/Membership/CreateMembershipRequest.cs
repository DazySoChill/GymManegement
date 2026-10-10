namespace GymManegement.API.DTOs.Membership
{
    public class CreateMembershipRequest
    {
        public int MemberId { get; set; }
        public string PackageName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
