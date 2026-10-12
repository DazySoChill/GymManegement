using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Checkin;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface ICheckinService
    {
        Task<PagedResult<CheckinResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<CheckinResponse?> GetByIdAsync(int id);
        Task<IEnumerable<CheckinResponse>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<CheckinResponse>> GetByDateRangeAsync(DateTime from, DateTime to);
        Task<IEnumerable<CheckinResponse>> GetByDateAsync(DateTime date);
        Task<CheckinResponse> CreateManualAsync(CreateCheckinRequest request, string? userRole = null, string? userEmail = null);
        Task<CheckinResponse> CheckinByQRAsync(QRCheckinRequest request);
        Task<CheckinResponse?> CheckoutAsync(int checkinId);
    }
}
