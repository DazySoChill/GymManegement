using GymManegement.API.DTOs.Membership;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IMembershipService
    {
        Task<IEnumerable<MembershipResponse>> GetByMemberAsync(int memberId);
        Task<MembershipResponse?> GetActiveAsync(int memberId);
        Task<MembershipResponse> CreateAsync(CreateMembershipRequest request);
        Task<bool> UpdateAsync(int id, UpdateMembershipRequest request);
        Task<IEnumerable<object>> GetExpiringSoonAsync(int daysAhead = 7);
    }
}
