namespace GymManegement.API.DTOs.Payment
{
    public class UpdatePaymentRequest
    {
        /// <summary>Pending | Completed | Failed | Refunded</summary>
        public string Status { get; set; } = string.Empty;
    }
}
