namespace GymManegement.API.DTOs.Invoice
{
    public class InvoiceResponse
    {
        public int InvoiceId { get; set; }
        public int MembershipId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public string PackageName { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime InvoiceDate { get; set; }
        public DateTime DueDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsOverdue => Status == "Pending" && DueDate < DateTime.UtcNow;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
