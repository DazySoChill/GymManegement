using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Schedule;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class ScheduleService : IScheduleService
    {
        private readonly IScheduleRepository _repo;
        public ScheduleService(IScheduleRepository repo) => _repo = repo;

        public async Task<PagedResult<ScheduleResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<ScheduleResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<ScheduleResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByTrainerIdAsync(int trainerId)
        {
            var entities = await _repo.GetByTrainerIdAsync(trainerId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByFacilityIdAsync(int facilityId)
        {
            var entities = await _repo.GetByFacilityIdAsync(facilityId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByDateAsync(DateTime date)
        {
            var entities = await _repo.GetByDateAsync(date);
            return entities.Select(ToResponse);
        }

        public async Task<ScheduleResponse> CreateAsync(CreateScheduleRequest request)
        {
            var entity = new Schedule
            {
                ClassName = request.ClassName,
                TrainerId = request.TrainerId,
                FacilityId = request.FacilityId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                MaxCapacity = request.MaxCapacity
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<ScheduleResponse?> UpdateAsync(int id, UpdateScheduleRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            entity.ClassName = request.ClassName;
            entity.TrainerId = request.TrainerId;
            entity.FacilityId = request.FacilityId;
            entity.StartTime = request.StartTime;
            entity.EndTime = request.EndTime;
            entity.MaxCapacity = request.MaxCapacity;
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

        private static ScheduleResponse ToResponse(Schedule s) => new ScheduleResponse
        {
            ScheduleId = s.ScheduleId,
            ClassName = s.ClassName,
            TrainerId = s.TrainerId,
            FacilityId = s.FacilityId,
            StartTime = s.StartTime,
            EndTime = s.EndTime,
            MaxCapacity = s.MaxCapacity
        };
    }
}
