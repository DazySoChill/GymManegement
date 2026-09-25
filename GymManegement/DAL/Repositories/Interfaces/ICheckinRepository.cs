using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ICheckinRepository : IRepository<Checkin>
    {
        Task<IEnumerable<Checkin>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Checkin>> GetBySessionIdAsync(int sessionId);
        /// <summary>Lấy lịch sử checkin trong khoảng ngày</summary>
        Task<IEnumerable<Checkin>> GetByDateRangeAsync(DateTime from, DateTime to);
    }
}
