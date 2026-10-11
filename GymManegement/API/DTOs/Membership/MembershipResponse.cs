namespace GymManegement.API.DTOs.Membership
{
    public class MembershipResponse
    {
        public int MembershipId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int DaysRemaining => Math.Max(0, (EndDate - DateTime.UtcNow).Days);
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
