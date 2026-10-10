using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface ICheckinRepository : IRepository<Checkin>
    {
        Task<IEnumerable<Checkin>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Checkin>> GetByDateRangeAsync(DateTime from, DateTime to);
        Task<IEnumerable<Checkin>> GetByDateAsync(DateTime date);
        Task<PagedResult<Checkin>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<Checkin?> GetByQRCodeAsync(string qrCode);
    }
}
