namespace GymManegement.DAL.Entities
{
    public class Invoice
    {
        public int InvoiceId { get; set; }

        public int MembershipId { get; set; }

        public DateTime InvoiceDate { get; set; }

        public DateTime DueDate { get; set; }

        public decimal TotalAmount { get; set; }

        /// <summary>Status: Pending | Paid | PartiallyPaid | Overdue | Cancelled</summary>
        public string Status { get; set; } = "Pending";

        public string? Description { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Membership Membership { get; set; } = null!;

        public ICollection<Payment> Payments { get; set; }
            = new List<Payment>();
    }
}
