namespace GymManegement.DAL.Entities
{
    public class Membership
    {
        public int MembershipId { get; set; }

        public int MemberId { get; set; }

        public string MembershipType { get; set; } = string.Empty;

        public decimal Price { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        /// <summary>Gói còn hiệu lực (dùng để query nhanh, không cần tính ngày)</summary>
        public bool IsActive { get; set; } = true;

        // Navigation
        public Member Member { get; set; } = null!;
    }
}
