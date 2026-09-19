using GymManegement.API.DTOs.Member;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IMemberService
    {
        Task<IEnumerable<MemberResponse>> GetAllAsync();
        Task<MemberResponse?> GetByIdAsync(int id);
        Task<MemberResponse> CreateAsync(CreateMemberRequest request);
        Task<MemberResponse?> UpdateAsync(int id, UpdateMemberRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
