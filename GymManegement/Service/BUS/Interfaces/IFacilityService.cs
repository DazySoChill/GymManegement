using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Facility;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IFacilityService
    {
        Task<PagedResult<FacilityResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<FacilityResponse?> GetByIdAsync(int id);
        Task<IEnumerable<FacilityResponse>> GetActiveAsync();
        Task<FacilityResponse> CreateAsync(CreateFacilityRequest request);
        Task<FacilityResponse?> UpdateAsync(int id, UpdateFacilityRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
