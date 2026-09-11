namespace GymManegement.DAL.Entities
{
    public class Invoice
    {
        public int InvoiceId { get; set; }

        public int MemberId { get; set; }

        public decimal TotalAmount { get; set; }

        public DateTime InvoiceDate { get; set; }

        /// <summary>Hạn thanh toán</summary>
        public DateTime DueDate { get; set; }

        /// <summary>Trạng thái: Pending | Paid | Overdue | Cancelled</summary>
        public string Status { get; set; } = "Pending";

        // Navigation
        public Member Member { get; set; } = null!;

        public ICollection<Payment> Payments { get; set; }
            = new List<Payment>();
    }
}
