using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Facility;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class FacilityService : IFacilityService
    {
        private readonly IFacilityRepository _repo;
        public FacilityService(IFacilityRepository repo) => _repo = repo;

        public async Task<PagedResult<FacilityResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<FacilityResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<FacilityResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<FacilityResponse>> GetActiveAsync()
        {
            var entities = await _repo.GetActiveAsync();
            return entities.Select(ToResponse);
        }

        public async Task<FacilityResponse> CreateAsync(CreateFacilityRequest request)
        {
            var entity = new Facility
            {
                Name = request.Name,
                Description = request.Description,
                Status = request.Status
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<FacilityResponse?> UpdateAsync(int id, UpdateFacilityRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.Status = request.Status;
            await _repo.UpdateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            await _repo.DeleteAsync(id);
            return true;
        }

        private static FacilityResponse ToResponse(Facility f) => new FacilityResponse
        {
            FacilityId = f.FacilityId,
            Name = f.Name,
            Description = f.Description,
            Status = f.Status,
            CreatedAt = f.CreatedAt,
            UpdatedAt = f.UpdatedAt
        };
    }
}
