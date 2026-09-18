namespace GymManegement.API.DTOs.Membership
{
    public class CreateMembershipRequest
    {
        public int MemberId { get; set; }
        /// <summary>Monthly | Quarterly | Annual</summary>
        public string MembershipType { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
