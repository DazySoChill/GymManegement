using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Trainer;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class TrainerService : ITrainerService
    {
        private readonly ITrainerRepository _repo;
        public TrainerService(ITrainerRepository repo) => _repo = repo;

        public async Task<PagedResult<TrainerResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<TrainerResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<TrainerResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<TrainerResponse> CreateAsync(CreateTrainerRequest request)
        {
            // Check if email already exists
            var existingTrainer = await _repo.GetByEmailAsync(request.Email);
            if (existingTrainer != null)
                throw new InvalidOperationException($"Email '{request.Email}' đã tồn tại.");

            var entity = new Trainer
            {
                FullName = request.FullName,
                Phone = request.Phone,
                Email = request.Email,
                Specialization = request.Specialization
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<TrainerResponse?> UpdateAsync(int id, UpdateTrainerRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            // Check if new email conflicts with another trainer
            if (!string.Equals(entity.Email, request.Email, StringComparison.OrdinalIgnoreCase))
            {
                var existingTrainer = await _repo.GetByEmailAsync(request.Email);
                if (existingTrainer != null && existingTrainer.TrainerId != id)
                    throw new InvalidOperationException($"Email '{request.Email}' đã tồn tại.");
            }
            
            entity.FullName = request.FullName;
            entity.Phone = request.Phone;
            entity.Email = request.Email;
            entity.Specialization = request.Specialization;
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

        private static TrainerResponse ToResponse(Trainer t) => new TrainerResponse
        {
            TrainerId = t.TrainerId,
            FullName = t.FullName,
            Phone = t.Phone,
            Email = t.Email,
            Specialization = t.Specialization,
            CreatedAt = t.CreatedAt,
            UpdatedAt = t.UpdatedAt
        };
    }
}
