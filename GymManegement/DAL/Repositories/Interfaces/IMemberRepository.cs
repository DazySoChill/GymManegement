using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IMemberRepository : IRepository<Member>
    {
        Task<Member?> GetByEmailAsync(string email);
        Task<Member?> GetByQRCodeAsync(string qrCode);
        Task<IEnumerable<Member>> GetByStatusAsync(string status); // Deprecated in SQL2 but kept for compatibility
        Task<bool> EmailExistsAsync(string email, int? excludeMemberId = null);
        Task<PagedResult<Member>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<List<Member>> GetByIdsAsync(List<int> memberIds);
    }
}
