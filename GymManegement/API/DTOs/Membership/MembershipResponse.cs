namespace GymManegement.API.DTOs.Membership
{
    public class MembershipResponse
    {
        public int MembershipId { get; set; }
        public int MemberId { get; set; }
        public string MembershipType { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; }
        /// <summary>Số ngày còn lại (tính từ EndDate - hôm nay)</summary>
        public int DaysRemaining => IsActive ? Math.Max(0, (EndDate - DateTime.UtcNow).Days) : 0;
    }
}
