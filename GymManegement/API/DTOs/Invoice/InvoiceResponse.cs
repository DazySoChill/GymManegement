namespace GymManegement.API.DTOs.Invoice
{
    public class InvoiceResponse
    {
        public int InvoiceId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime InvoiceDate { get; set; }
        public DateTime DueDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public bool IsOverdue => Status == "Pending" && DueDate < DateTime.UtcNow;
    }
}
