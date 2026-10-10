using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Membership;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class MembershipService : IMembershipService
    {
        private readonly IMembershipRepository _repo;
        private readonly IInvoiceRepository _invoiceRepo;

        public MembershipService(IMembershipRepository repo, IInvoiceRepository invoiceRepo)
        {
            _repo = repo;
            _invoiceRepo = invoiceRepo;
        }

        public async Task<PagedResult<MembershipResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<MembershipResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<MembershipResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<MembershipResponse>> GetByMemberIdAsync(int memberId)
        {
            var entities = await _repo.GetByMemberIdAsync(memberId);
            return entities.Select(ToResponse);
        }

        public async Task<MembershipResponse?> GetActiveMembershipAsync(int memberId)
        {
            var entity = await _repo.GetActiveMembershipAsync(memberId);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<MembershipResponse>> GetExpiringSoonAsync(int daysAhead = 7)
        {
            var entities = await _repo.GetExpiringSoonAsync(daysAhead);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<MembershipResponse>> GetActiveAsync()
        {
            var entities = await _repo.GetActiveAsync();
            return entities.Select(ToResponse);
        }

        /// <summary>
        /// CreateAsync: Tạo Membership và AUTO CREATE Invoice
        /// </summary>
        public async Task<MembershipResponse> CreateAsync(CreateMembershipRequest request)
        {
            // 1. Create Membership
            var membership = new Membership
            {
                MemberId = request.MemberId,
                PackageName = request.PackageName,
                Price = request.Price,
                StartDate = request.StartDate,
                EndDate = request.EndDate
            };
            await _repo.CreateAsync(membership);

            // 2. AUTO CREATE Invoice
            var invoice = new Invoice
            {
                MemberId = membership.MemberId,  // FIX: Add MemberId
                MembershipId = membership.MembershipId,
                InvoiceDate = DateTime.Today,
                DueDate = membership.EndDate,
                TotalAmount = membership.Price,
                Status = "Pending",
                Description = $"Hóa đơn cho gói tập {membership.PackageName}"
            };
            await _invoiceRepo.CreateAsync(invoice);

            return ToResponse(membership);
        }

        public async Task<MembershipResponse?> UpdateAsync(int id, UpdateMembershipRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            entity.PackageName = request.PackageName;
            entity.Price = request.Price;
            entity.StartDate = request.StartDate;
            entity.EndDate = request.EndDate;
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

        public async Task<bool> CancelAsync(int membershipId, int requestingMemberId)
        {
            var entity = await _repo.GetByIdAsync(membershipId);
            if (entity is null) return false;
            if (entity.MemberId != requestingMemberId) return false; // Security check: member can only cancel own
            var cancelled = await _repo.CancelAsync(membershipId);
            return cancelled;
        }

        private static MembershipResponse ToResponse(Membership m) => new MembershipResponse
        {
            MembershipId = m.MembershipId,
            MemberId = m.MemberId,
            PackageName = m.PackageName,
            Price = m.Price,
            StartDate = m.StartDate,
            EndDate = m.EndDate,
            CreatedAt = m.CreatedAt,
            UpdatedAt = m.UpdatedAt
        };
    }
}
