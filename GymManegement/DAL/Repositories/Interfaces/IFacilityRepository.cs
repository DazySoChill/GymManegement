using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IFacilityRepository : IRepository<Facility>
    {
        Task<IEnumerable<Facility>> GetActiveAsync();
        Task<PagedResult<Facility>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<List<Facility>> GetByIdsAsync(List<int> facilityIds);
    }
}
