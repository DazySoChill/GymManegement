using GymManegement.API.DTOs.Payment;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IPaymentService
    {
        Task<IEnumerable<PaymentResponse>> GetByInvoiceAsync(int invoiceId);
        Task<PaymentResponse> CreateAsync(CreatePaymentRequest request);
        Task<bool> UpdateStatusAsync(int id, UpdatePaymentRequest request);
    }
}
