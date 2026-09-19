namespace GymManegement.API.DTOs.Invoice
{
    public class UpdateInvoiceRequest
    {
        /// <summary>Pending | Paid | Overdue | Cancelled</summary>
        public string Status { get; set; } = string.Empty;
    }
}
