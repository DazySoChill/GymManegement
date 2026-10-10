using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Member;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class MemberService : IMemberService
    {
        private readonly IMemberRepository _repo;
        public MemberService(IMemberRepository repo) => _repo = repo;

        public async Task<PagedResult<MemberResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<MemberResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<MemberResponse?> GetByIdAsync(int id)
        {
            var m = await _repo.GetByIdAsync(id);
            return m is null ? null : ToResponse(m);
        }

        public async Task<MemberResponse> CreateAsync(CreateMemberRequest request)
        {
            if (await _repo.EmailExistsAsync(request.Email))
                throw new InvalidOperationException($"Email '{request.Email}' đã tồn tại.");

            // Generate unique QRCode using GUID
            var qrCode = $"M{Guid.NewGuid():N}"[..10].ToUpper(); // M + 9 hex chars

            var entity = new Member
            {
                FullName     = request.FullName,
                Email        = request.Email,
                Phone        = request.Phone,
                DateOfBirth  = request.DateOfBirth,
                QRCode       = qrCode
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<MemberResponse?> UpdateAsync(int id, UpdateMemberRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            if (!string.Equals(entity.Email, request.Email, StringComparison.OrdinalIgnoreCase)
                && await _repo.EmailExistsAsync(request.Email, id))
                throw new InvalidOperationException($"Email '{request.Email}' đã tồn tại.");

            entity.FullName    = request.FullName;
            entity.Email       = request.Email;
            entity.Phone       = request.Phone;
            entity.DateOfBirth = request.DateOfBirth;
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

        private static MemberResponse ToResponse(Member m) => new()
        {
            MemberId    = m.MemberId,
            FullName    = m.FullName,
            Email       = m.Email,
            Phone       = m.Phone,
            DateOfBirth = m.DateOfBirth,
            QRCode      = m.QRCode,
            CreatedAt   = m.CreatedAt,
            UpdatedAt   = m.UpdatedAt
        };
    }
}
