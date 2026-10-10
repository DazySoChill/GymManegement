namespace GymManegement.API.DTOs.Invoice
{
    public class CreateInvoiceRequest
    {
        public int MembershipId { get; set; }
        public decimal TotalAmount { get; set; }
        public DateTime InvoiceDate { get; set; } = DateTime.UtcNow;
        /// <summary>Hạn thanh toán (mặc định 7 ngày từ ngày tạo)</summary>
        public DateTime DueDate { get; set; } = DateTime.UtcNow.AddDays(7);
        public string? Description { get; set; }
    }
}
