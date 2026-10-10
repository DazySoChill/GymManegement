namespace GymManegement.DAL.Entities
{
    public class Invoice
    {
        public int InvoiceId { get; set; }

        public int MemberId { get; set; }  // Add this - who is being invoiced

        public int? MembershipId { get; set; }  // Made nullable

        public DateTime InvoiceDate { get; set; }

        public DateTime? DueDate { get; set; }  // Made nullable

        public decimal TotalAmount { get; set; }

        /// <summary>Status: Pending | Paid | PartiallyPaid | Overdue | Cancelled</summary>
        public string Status { get; set; } = "Pending";

        public string? Description { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Member Member { get; set; } = null!;
        public Membership? Membership { get; set; }

        public ICollection<Payment> Payments { get; set; }
            = new List<Payment>();
    }
}
