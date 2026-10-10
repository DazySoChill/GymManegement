using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IMembershipRepository : IRepository<Membership>
    {
        Task<IEnumerable<Membership>> GetByMemberIdAsync(int memberId);
        /// <summary>Trả về gói membership đang active của member</summary>
        Task<Membership?> GetActiveMembershipAsync(int memberId);
        /// <summary>Hội viên sắp hết hạn trong N ngày</summary>
        Task<IEnumerable<Membership>> GetExpiringSoonAsync(int daysAhead = 7);
        /// <summary>Lấy tất cả membership đang active (EndDate >= today)</summary>
        Task<IEnumerable<Membership>> GetActiveAsync();
        Task<PagedResult<Membership>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        /// <summary>Cancel membership - set EndDate to today</summary>
        Task<bool> CancelAsync(int membershipId);
    }
}
