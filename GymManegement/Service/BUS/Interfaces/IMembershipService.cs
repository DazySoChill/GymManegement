using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Membership;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IMembershipService
    {
        Task<PagedResult<MembershipResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<MembershipResponse?> GetByIdAsync(int id);
        Task<IEnumerable<MembershipResponse>> GetByMemberIdAsync(int memberId);
        Task<MembershipResponse?> GetActiveMembershipAsync(int memberId);
        Task<IEnumerable<MembershipResponse>> GetExpiringSoonAsync(int daysAhead = 7);
        Task<IEnumerable<MembershipResponse>> GetActiveAsync();
        Task<MembershipResponse> CreateAsync(CreateMembershipRequest request);
        Task<MembershipResponse?> UpdateAsync(int id, UpdateMembershipRequest request);
        Task<bool> DeleteAsync(int id);
        /// <summary>Cancel membership - sets EndDate to today</summary>
        Task<bool> CancelAsync(int membershipId, int requestingMemberId);
    }
}
