namespace GymManegement.DAL.Entities
{
    public class Payment
    {
        public int PaymentId { get; set; }

        public int InvoiceId { get; set; }

        public decimal Amount { get; set; }

        /// <summary>PaymentMethod: Cash | Card | BankTransfer | Momo | ZaloPay</summary>
        public string PaymentMethod { get; set; } = string.Empty;

        public DateTime PaymentDate { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Invoice Invoice { get; set; } = null!;
    }
}
