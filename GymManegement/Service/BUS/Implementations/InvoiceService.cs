using GymManegement.API.DTOs.Invoice;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class InvoiceService : IInvoiceService
    {
        private readonly IInvoiceRepository _repo;
        public InvoiceService(IInvoiceRepository repo) => _repo = repo;

        public async Task<IEnumerable<InvoiceResponse>> GetAllAsync()
            => (await _repo.GetAllAsync()).Select(ToResponse);

        public async Task<InvoiceResponse?> GetByIdAsync(int id)
        {
            var inv = await _repo.GetByIdAsync(id);
            return inv is null ? null : ToResponse(inv);
        }

        public async Task<IEnumerable<InvoiceResponse>> GetByMemberAsync(int memberId)
            => (await _repo.GetByMemberIdAsync(memberId)).Select(ToResponse);

        public async Task<IEnumerable<InvoiceResponse>> GetOverdueAsync()
            => (await _repo.GetOverdueAsync()).Select(ToResponse);

        public async Task<InvoiceResponse> CreateAsync(CreateInvoiceRequest request)
        {
            var entity = new Invoice
            {
                MemberId    = request.MemberId,
                TotalAmount = request.TotalAmount,
                InvoiceDate = request.InvoiceDate == default ? DateTime.UtcNow : request.InvoiceDate,
                DueDate     = request.DueDate == default ? DateTime.UtcNow.AddDays(7) : request.DueDate,
                Status      = "Pending"
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<bool> UpdateStatusAsync(int id, UpdateInvoiceRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            entity.Status = request.Status;
            await _repo.UpdateAsync(entity);
            return true;
        }

        private static InvoiceResponse ToResponse(Invoice i) => new()
        {
            InvoiceId   = i.InvoiceId,
            MemberId    = i.MemberId,
            MemberName  = string.Empty,
            TotalAmount = i.TotalAmount,
            InvoiceDate = i.InvoiceDate,
            DueDate     = i.DueDate,
            Status      = i.Status
        };
    }
}
