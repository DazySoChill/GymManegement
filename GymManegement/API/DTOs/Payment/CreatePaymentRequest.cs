namespace GymManegement.API.DTOs.Payment
{
    public class CreatePaymentRequest
    {
        public int? InvoiceId { get; set; }  // Optional - for invoice payments
        public int MemberId { get; set; }     // Required - who is paying
        public decimal Amount { get; set; }
        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
        /// <summary>Cash | QRCode | BankTransfer | Card | MoMo | ZaloPay</summary>
        public string PaymentMethod { get; set; } = string.Empty;
        public string? TransactionId { get; set; }  // Optional transaction reference
        public string Status { get; set; } = "Completed";  // Completed | Pending | Failed
    }
}
