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

        public async Task<IEnumerable<MemberResponse>> GetAllAsync()
        {
            var members = await _repo.GetAllAsync();
            return members.Select(ToResponse);
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

            var entity = new Member
            {
                FullName     = request.FullName,
                Phone        = request.Phone,
                Email        = request.Email,
                DateOfBirth  = request.DateOfBirth,
                JoinDate     = request.JoinDate == default ? DateTime.UtcNow : request.JoinDate,
                Status       = "Active",
                QRCodeValue  = Guid.NewGuid().ToString("N")[..20] // 20 ký tự, duy nhất
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
            entity.Phone       = request.Phone;
            entity.Email       = request.Email;
            entity.DateOfBirth = request.DateOfBirth;
            entity.Status      = string.IsNullOrEmpty(request.Status) ? entity.Status : request.Status;
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
            Phone       = m.Phone,
            Email       = m.Email,
            DateOfBirth = m.DateOfBirth,
            JoinDate    = m.JoinDate,
            Status      = m.Status,
            QRCodeValue = m.QRCodeValue
        };
    }
}
