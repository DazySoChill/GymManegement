using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Trainer;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface ITrainerService
    {
        Task<PagedResult<TrainerResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<TrainerResponse?> GetByIdAsync(int id);
        Task<TrainerResponse> CreateAsync(CreateTrainerRequest request);
        Task<TrainerResponse?> UpdateAsync(int id, UpdateTrainerRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
