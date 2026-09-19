using GymManegement.API.DTOs.Membership;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class MembershipService : IMembershipService
    {
        private readonly IMembershipRepository _repo;
        public MembershipService(IMembershipRepository repo) => _repo = repo;

        public async Task<IEnumerable<MembershipResponse>> GetByMemberAsync(int memberId)
        {
            var list = await _repo.GetByMemberIdAsync(memberId);
            return list.Select(ToResponse);
        }

        public async Task<MembershipResponse?> GetActiveAsync(int memberId)
        {
            var m = await _repo.GetActiveMembershipAsync(memberId);
            return m is null ? null : ToResponse(m);
        }

        public async Task<MembershipResponse> CreateAsync(CreateMembershipRequest request)
        {
            var entity = new Membership
            {
                MemberId       = request.MemberId,
                MembershipType = request.MembershipType,
                Price          = request.Price,
                StartDate      = request.StartDate,
                EndDate        = request.EndDate,
                IsActive       = true
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<bool> UpdateAsync(int id, UpdateMembershipRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            entity.MembershipType = request.MembershipType;
            entity.Price          = request.Price;
            entity.StartDate      = request.StartDate;
            entity.EndDate        = request.EndDate;
            entity.IsActive       = request.IsActive;
            await _repo.UpdateAsync(entity);
            return true;
        }

        public async Task<IEnumerable<object>> GetExpiringSoonAsync(int daysAhead = 7)
            => (await _repo.GetExpiringSoonAsync(daysAhead)).Cast<object>();

        private static MembershipResponse ToResponse(Membership m) => new()
        {
            MembershipId   = m.MembershipId,
            MemberId       = m.MemberId,
            MembershipType = m.MembershipType,
            Price          = m.Price,
            StartDate      = m.StartDate,
            EndDate        = m.EndDate,
            IsActive       = m.IsActive
        };
    }
}
