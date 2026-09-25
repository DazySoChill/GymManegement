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
    }
}
