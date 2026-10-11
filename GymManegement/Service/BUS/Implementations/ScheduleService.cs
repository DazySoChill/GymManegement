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
        private readonly ITrainerRepository _trainerRepo;
        private readonly IFacilityRepository _facilityRepo;
        
        public ScheduleService(
            IScheduleRepository repo,
            ITrainerRepository trainerRepo,
            IFacilityRepository facilityRepo)
        {
            _repo = repo;
            _trainerRepo = trainerRepo;
            _facilityRepo = facilityRepo;
        }

        public async Task<PagedResult<ScheduleResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            var schedules = result.Data;
            
            if (!schedules.Any())
                return new PagedResult<ScheduleResponse>
                {
                    Data = new List<ScheduleResponse>(),
                    Total = result.Total,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };
            
            // BATCH FETCH: Collect all IDs
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var facilityIds = schedules.Where(s => s.FacilityId > 0).Select(s => s.FacilityId).Distinct().ToList();
            
            // Fetch in parallel (2 queries total)
            var trainersTask = _trainerRepo.GetByIdsAsync(trainerIds);
            var facilitiesTask = _facilityRepo.GetByIdsAsync(facilityIds);
            await Task.WhenAll(trainersTask, facilitiesTask);
            
            var trainers = trainersTask.Result;
            var facilities = facilitiesTask.Result;
            
            // Build lookup dictionaries
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            var facilityDict = facilities.ToDictionary(f => f.FacilityId);
            
            // Map using dictionaries
            var responses = schedules.Select(s => ToResponse(s, trainerDict, facilityDict)).ToList();
            
            return new PagedResult<ScheduleResponse>
            {
                Data = responses,
                Total = result.Total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<ScheduleResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : await ToResponseAsync(entity);
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByTrainerIdAsync(int trainerId)
        {
            var schedules = (await _repo.GetByTrainerIdAsync(trainerId)).ToList();
            if (!schedules.Any())
                return new List<ScheduleResponse>();
            
            // BATCH FETCH
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var facilityIds = schedules.Where(s => s.FacilityId > 0).Select(s => s.FacilityId).Distinct().ToList();
            
            var trainersTask = _trainerRepo.GetByIdsAsync(trainerIds);
            var facilitiesTask = _facilityRepo.GetByIdsAsync(facilityIds);
            await Task.WhenAll(trainersTask, facilitiesTask);
            
            var trainers = trainersTask.Result;
            var facilities = facilitiesTask.Result;
            
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            var facilityDict = facilities.ToDictionary(f => f.FacilityId);
            
            return schedules.Select(s => ToResponse(s, trainerDict, facilityDict)).ToList();
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByFacilityIdAsync(int facilityId)
        {
            var schedules = (await _repo.GetByFacilityIdAsync(facilityId)).ToList();
            if (!schedules.Any())
                return new List<ScheduleResponse>();
            
            // BATCH FETCH
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var facilityIds = schedules.Where(s => s.FacilityId > 0).Select(s => s.FacilityId).Distinct().ToList();
            
            var trainersTask = _trainerRepo.GetByIdsAsync(trainerIds);
            var facilitiesTask = _facilityRepo.GetByIdsAsync(facilityIds);
            await Task.WhenAll(trainersTask, facilitiesTask);
            
            var trainers = trainersTask.Result;
            var facilities = facilitiesTask.Result;
            
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            var facilityDict = facilities.ToDictionary(f => f.FacilityId);
            
            return schedules.Select(s => ToResponse(s, trainerDict, facilityDict)).ToList();
        }

        public async Task<IEnumerable<ScheduleResponse>> GetByDateAsync(DateTime date)
        {
            var schedules = (await _repo.GetByDateAsync(date)).ToList();
            if (!schedules.Any())
                return new List<ScheduleResponse>();
            
            // BATCH FETCH
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var facilityIds = schedules.Where(s => s.FacilityId > 0).Select(s => s.FacilityId).Distinct().ToList();
            
            var trainersTask = _trainerRepo.GetByIdsAsync(trainerIds);
            var facilitiesTask = _facilityRepo.GetByIdsAsync(facilityIds);
            await Task.WhenAll(trainersTask, facilitiesTask);
            
            var trainers = trainersTask.Result;
            var facilities = facilitiesTask.Result;
            
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            var facilityDict = facilities.ToDictionary(f => f.FacilityId);
            
            return schedules.Select(s => ToResponse(s, trainerDict, facilityDict)).ToList();
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
            return await ToResponseAsync(entity);
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
            return await ToResponseAsync(entity);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            await _repo.DeleteAsync(id);
            return true;
        }

        private async Task<ScheduleResponse> ToResponseAsync(Schedule s)
        {
            var trainer = await _trainerRepo.GetByIdAsync(s.TrainerId);
            var facility = await _facilityRepo.GetByIdAsync(s.FacilityId);
            
            return new ScheduleResponse
            {
                ScheduleId = s.ScheduleId,
                ClassName = s.ClassName,
                TrainerId = s.TrainerId,
                TrainerName = trainer?.FullName ?? "-",
                FacilityId = s.FacilityId,
                FacilityName = facility?.Name ?? "-",
                StartTime = s.StartTime,
                EndTime = s.EndTime,
                MaxCapacity = s.MaxCapacity,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            };
        }

        private static ScheduleResponse ToResponse(
            Schedule s,
            Dictionary<int, Trainer> trainerDict,
            Dictionary<int, Facility> facilityDict)
        {
            trainerDict.TryGetValue(s.TrainerId, out var trainer);
            facilityDict.TryGetValue(s.FacilityId, out var facility);
            
            return new ScheduleResponse
            {
                ScheduleId = s.ScheduleId,
                ClassName = s.ClassName,
                TrainerId = s.TrainerId,
                TrainerName = trainer?.FullName ?? "-",
                FacilityId = s.FacilityId,
                FacilityName = facility?.Name ?? "-",
                StartTime = s.StartTime,
                EndTime = s.EndTime,
                MaxCapacity = s.MaxCapacity,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            };
        }
    }
}
