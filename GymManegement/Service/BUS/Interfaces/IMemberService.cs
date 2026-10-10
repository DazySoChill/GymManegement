using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Member;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IMemberService
    {
        Task<PagedResult<MemberResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<MemberResponse?> GetByIdAsync(int id);
        Task<MemberResponse> CreateAsync(CreateMemberRequest request);
        Task<MemberResponse?> UpdateAsync(int id, UpdateMemberRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
