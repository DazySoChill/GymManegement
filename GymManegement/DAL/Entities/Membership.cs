namespace GymManegement.DAL.Entities
{
    public class Membership
    {
        public int MembershipId { get; set; }

        public int MemberId { get; set; }

        public string PackageName { get; set; } = string.Empty;

        public decimal Price { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation - SQL2 relationships
        public Member Member { get; set; } = null!;

        public ICollection<Invoice> Invoices { get; set; }
            = new List<Invoice>();
    }
}
