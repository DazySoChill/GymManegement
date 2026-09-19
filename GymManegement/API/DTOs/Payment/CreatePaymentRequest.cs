namespace GymManegement.API.DTOs.Payment
{
    public class CreatePaymentRequest
    {
        public int InvoiceId { get; set; }
        public decimal Amount { get; set; }
        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
        /// <summary>Cash | BankTransfer | Card | MoMo | ZaloPay</summary>
        public string PaymentMethod { get; set; } = string.Empty;
    }
}
