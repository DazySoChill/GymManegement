namespace GymManegement.DAL.Entities
{
    public class Payment
    {
        public int PaymentId { get; set; }

        public int? InvoiceId { get; set; }  // Optional - null for direct payments

        public int MemberId { get; set; }  // Required - who is paying

        public decimal Amount { get; set; }

        /// <summary>PaymentMethod: Cash | QRCode | Card | BankTransfer | Momo | ZaloPay</summary>
        public string PaymentMethod { get; set; } = string.Empty;

        public DateTime PaymentDate { get; set; }
        
        public string? TransactionId { get; set; }  // Optional transaction reference
        
        public string Status { get; set; } = "Completed";  // Completed | Pending | Failed

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Invoice? Invoice { get; set; }
        public Member Member { get; set; } = null!;
    }
}
