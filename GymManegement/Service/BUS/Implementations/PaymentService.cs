using GymManegement.API.DTOs.Payment;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class PaymentService : IPaymentService
    {
        private readonly IPaymentRepository _repo;
        public PaymentService(IPaymentRepository repo) => _repo = repo;

        public async Task<IEnumerable<PaymentResponse>> GetByInvoiceAsync(int invoiceId)
            => (await _repo.GetByInvoiceIdAsync(invoiceId)).Select(ToResponse);

        public async Task<PaymentResponse> CreateAsync(CreatePaymentRequest request)
        {
            var entity = new Payment
            {
                InvoiceId     = request.InvoiceId,
                Amount        = request.Amount,
                PaymentDate   = request.PaymentDate == default ? DateTime.UtcNow : request.PaymentDate,
                PaymentMethod = request.PaymentMethod,
                Status        = "Completed"
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<bool> UpdateStatusAsync(int id, UpdatePaymentRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            entity.Status = request.Status;
            await _repo.UpdateAsync(entity);
            return true;
        }

        private static PaymentResponse ToResponse(Payment p) => new()
        {
            PaymentId     = p.PaymentId,
            InvoiceId     = p.InvoiceId,
            Amount        = p.Amount,
            PaymentDate   = p.PaymentDate,
            PaymentMethod = p.PaymentMethod,
            Status        = p.Status
        };
    }
}
