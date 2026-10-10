namespace GymManegement.DAL.Entities
{
    public class Member
    {
        public int MemberId { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string? Phone { get; set; }

        public DateTime? DateOfBirth { get; set; }

        /// <summary>QR Code để check-in (format: M000001)</summary>
        public string QRCode { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation - SQL2 relationships
        public ICollection<Membership> Memberships { get; set; }
            = new List<Membership>();

        public ICollection<Session> Sessions { get; set; }
            = new List<Session>();

        public ICollection<Checkin> Checkins { get; set; }
            = new List<Checkin>();
        // Note: Invoices → Memberships, not direct to Members
    }
}
