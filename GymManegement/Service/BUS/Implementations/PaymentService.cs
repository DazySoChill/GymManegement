using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Payment;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class PaymentService : IPaymentService
    {
        private readonly IPaymentRepository _repo;
        private readonly IInvoiceRepository _invoiceRepo;

        public PaymentService(IPaymentRepository repo, IInvoiceRepository invoiceRepo)
        {
            _repo = repo;
            _invoiceRepo = invoiceRepo;
        }

        public async Task<PagedResult<PaymentResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<PaymentResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<PaymentResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<PaymentResponse>> GetByInvoiceIdAsync(int invoiceId)
        {
            var entities = await _repo.GetByInvoiceIdAsync(invoiceId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<PaymentResponse>> GetByMemberIdAsync(int memberId)
        {
            var entities = await _repo.GetByMemberIdAsync(memberId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<PaymentResponse>> GetByStatusAsync(string status)
        {
            var entities = await _repo.GetByStatusAsync(status);
            return entities.Select(ToResponse);
        }

        /// <summary>
        /// CreateAsync: Tạo Payment và AUTO UPDATE Invoice.Status
        /// </summary>
        public async Task<PaymentResponse> CreateAsync(CreatePaymentRequest request)
        {
            // 1. Get Invoice
            var invoice = await _invoiceRepo.GetByIdAsync(request.InvoiceId);
            if (invoice is null)
                throw new InvalidOperationException("Invoice không tồn tại.");

            // 2. Create Payment
            var payment = new Payment
            {
                InvoiceId = request.InvoiceId,
                Amount = request.Amount,
                PaymentDate = request.PaymentDate,
                PaymentMethod = request.PaymentMethod
            };
            await _repo.CreateAsync(payment);

            // 3. AUTO UPDATE Invoice.Status
            // Calculate total paid
            var allPayments = await _repo.GetByInvoiceIdAsync(invoice.InvoiceId);
            var totalPaid = allPayments.Sum(p => p.Amount);

            if (totalPaid >= invoice.TotalAmount)
            {
                // Full payment → Mark as Paid
                invoice.Status = "Paid";
            }
            else if (totalPaid > 0)
            {
                // Partial payment → Keep as Pending
                invoice.Status = "Pending";
            }

            await _invoiceRepo.UpdateAsync(invoice);

            return ToResponse(payment);
        }

        public async Task<PaymentResponse?> UpdateAsync(int id, UpdatePaymentRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            await _repo.UpdateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            await _repo.DeleteAsync(id);
            return true;
        }

        private static PaymentResponse ToResponse(Payment p) => new PaymentResponse
        {
            PaymentId = p.PaymentId,
            InvoiceId = p.InvoiceId,
            Amount = p.Amount,
            PaymentDate = p.PaymentDate,
            PaymentMethod = p.PaymentMethod,
            CreatedAt = p.CreatedAt,
            UpdatedAt = p.UpdatedAt
        };
    }
}
