using GymManegement.API.DTOs.Common;
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

        public async Task<PagedResult<InvoiceResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<InvoiceResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<InvoiceResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<InvoiceResponse>> GetByMemberIdAsync(int memberId)
        {
            var entities = await _repo.GetByMemberIdAsync(memberId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<InvoiceResponse>> GetByStatusAsync(string status)
        {
            var entities = await _repo.GetByStatusAsync(status);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<InvoiceResponse>> GetOverdueAsync()
        {
            var entities = await _repo.GetOverdueAsync();
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<InvoiceResponse>> GetUnpaidAsync()
        {
            var entities = await _repo.GetUnpaidAsync();
            return entities.Select(ToResponse);
        }

        public async Task<decimal> GetTotalRevenueAsync(int month, int year)
        {
            return await _repo.GetTotalRevenueAsync(month, year);
        }

        public async Task<InvoiceResponse> CreateAsync(CreateInvoiceRequest request)
        {
            var entity = new Invoice
            {
                MemberId = request.MemberId,  // Add this
                MembershipId = request.MembershipId,
                TotalAmount = request.TotalAmount,
                InvoiceDate = request.InvoiceDate,
                DueDate = request.DueDate,
                Status = "Pending",
                Description = request.Description
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<InvoiceResponse?> UpdateAsync(int id, UpdateInvoiceRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            entity.Status = request.Status;
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

        private static InvoiceResponse ToResponse(Invoice i) => new InvoiceResponse
        {
            InvoiceId = i.InvoiceId,
            MembershipId = i.MembershipId ?? 0,  // Handle nullable
            TotalAmount = i.TotalAmount,
            InvoiceDate = i.InvoiceDate,
            DueDate = i.DueDate ?? DateTime.MinValue,  // Handle nullable
            Status = i.Status,
            Description = i.Description,
            CreatedAt = i.CreatedAt,
            UpdatedAt = i.UpdatedAt ?? DateTime.MinValue  // Handle nullable
        };
    }
}
