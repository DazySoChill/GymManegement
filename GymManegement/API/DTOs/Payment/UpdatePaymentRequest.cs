namespace GymManegement.API.DTOs.Payment
{
    /// <summary>
    /// UpdatePaymentRequest: SQL2 Payment không có Status nữa.
    /// Giữ class để tương thích API nhưng không có fields để update.
    /// </summary>
    public class UpdatePaymentRequest
    {
        // No updatable fields in SQL2 Payment schema
    }
}
