using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Session;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class SessionService : ISessionService
    {
        private readonly ISessionRepository _repo;
        private readonly IMemberRepository _memberRepo;
        private readonly IScheduleRepository _scheduleRepo;
        private readonly ITrainerRepository _trainerRepo;
        
        public SessionService(
            ISessionRepository repo, 
            IMemberRepository memberRepo,
            IScheduleRepository scheduleRepo,
            ITrainerRepository trainerRepo)
        {
            _repo = repo;
            _memberRepo = memberRepo;
            _scheduleRepo = scheduleRepo;
            _trainerRepo = trainerRepo;
        }

        public async Task<PagedResult<SessionResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            var sessions = result.Data;
            
            if (!sessions.Any())
                return new PagedResult<SessionResponse>
                {
                    Data = new List<SessionResponse>(),
                    Total = result.Total,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };
            
            // BATCH FETCH: Collect all IDs first
            var memberIds = sessions.Select(s => s.MemberId).Distinct().ToList();
            var scheduleIds = sessions.Select(s => s.ScheduleId).Distinct().ToList();
            
            // Fetch all entities in parallel (3 queries total, not N queries)
            var membersTask = _memberRepo.GetByIdsAsync(memberIds);
            var schedulesTask = _scheduleRepo.GetByIdsAsync(scheduleIds);
            await Task.WhenAll(membersTask, schedulesTask);
            
            var members = membersTask.Result;
            var schedules = schedulesTask.Result;
            
            // Fetch trainers from schedules (batch)
            var trainerIds = schedules.Where(s => s.TrainerId > 0)
                                      .Select(s => s.TrainerId)
                                      .Distinct()
                                      .ToList();
            var trainers = await _trainerRepo.GetByIdsAsync(trainerIds);
            
            // Build lookup dictionaries for O(1) access
            var memberDict = members.ToDictionary(m => m.MemberId);
            var scheduleDict = schedules.ToDictionary(s => s.ScheduleId);
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            
            // Map using dictionaries (no DB calls in loop)
            var responses = sessions.Select(s => ToResponse(s, memberDict, scheduleDict, trainerDict)).ToList();
            
            return new PagedResult<SessionResponse>
            {
                Data = responses,
                Total = result.Total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<SessionResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : await ToResponseAsync(entity);
        }

        public async Task<IEnumerable<SessionResponse>> GetByScheduleIdAsync(int scheduleId)
        {
            var sessions = (await _repo.GetByScheduleIdAsync(scheduleId)).ToList();
            if (!sessions.Any())
                return new List<SessionResponse>();
            
            // BATCH FETCH
            var memberIds = sessions.Select(s => s.MemberId).Distinct().ToList();
            var scheduleIds = sessions.Select(s => s.ScheduleId).Distinct().ToList();
            
            var membersTask = _memberRepo.GetByIdsAsync(memberIds);
            var schedulesTask = _scheduleRepo.GetByIdsAsync(scheduleIds);
            await Task.WhenAll(membersTask, schedulesTask);
            
            var members = membersTask.Result;
            var schedules = schedulesTask.Result;
            
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var trainers = await _trainerRepo.GetByIdsAsync(trainerIds);
            
            var memberDict = members.ToDictionary(m => m.MemberId);
            var scheduleDict = schedules.ToDictionary(s => s.ScheduleId);
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            
            return sessions.Select(s => ToResponse(s, memberDict, scheduleDict, trainerDict)).ToList();
        }

        public async Task<IEnumerable<SessionResponse>> GetByMemberIdAsync(int memberId)
        {
            var sessions = (await _repo.GetByMemberIdAsync(memberId)).ToList();
            if (!sessions.Any())
                return new List<SessionResponse>();
            
            // BATCH FETCH
            var memberIds = sessions.Select(s => s.MemberId).Distinct().ToList();
            var scheduleIds = sessions.Select(s => s.ScheduleId).Distinct().ToList();
            
            var membersTask = _memberRepo.GetByIdsAsync(memberIds);
            var schedulesTask = _scheduleRepo.GetByIdsAsync(scheduleIds);
            await Task.WhenAll(membersTask, schedulesTask);
            
            var members = membersTask.Result;
            var schedules = schedulesTask.Result;
            
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var trainers = await _trainerRepo.GetByIdsAsync(trainerIds);
            
            var memberDict = members.ToDictionary(m => m.MemberId);
            var scheduleDict = schedules.ToDictionary(s => s.ScheduleId);
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            
            return sessions.Select(s => ToResponse(s, memberDict, scheduleDict, trainerDict)).ToList();
        }

        public async Task<IEnumerable<SessionResponse>> GetByStatusAsync(string status)
        {
            var sessions = (await _repo.GetByStatusAsync(status)).ToList();
            if (!sessions.Any())
                return new List<SessionResponse>();
            
            // BATCH FETCH
            var memberIds = sessions.Select(s => s.MemberId).Distinct().ToList();
            var scheduleIds = sessions.Select(s => s.ScheduleId).Distinct().ToList();
            
            var membersTask = _memberRepo.GetByIdsAsync(memberIds);
            var schedulesTask = _scheduleRepo.GetByIdsAsync(scheduleIds);
            await Task.WhenAll(membersTask, schedulesTask);
            
            var members = membersTask.Result;
            var schedules = schedulesTask.Result;
            
            var trainerIds = schedules.Where(s => s.TrainerId > 0).Select(s => s.TrainerId).Distinct().ToList();
            var trainers = await _trainerRepo.GetByIdsAsync(trainerIds);
            
            var memberDict = members.ToDictionary(m => m.MemberId);
            var scheduleDict = schedules.ToDictionary(s => s.ScheduleId);
            var trainerDict = trainers.ToDictionary(t => t.TrainerId);
            
            return sessions.Select(s => ToResponse(s, memberDict, scheduleDict, trainerDict)).ToList();
        }

        public async Task<SessionResponse> CreateAsync(CreateSessionRequest request)
        {
            // Validate MemberId is provided (not default 0)
            if (request.MemberId <= 0)
                throw new InvalidOperationException("MemberId phải được cung cấp và lớn hơn 0.");

            // Validate member exists
            var member = await _memberRepo.GetByIdAsync(request.MemberId);
            if (member is null)
                throw new InvalidOperationException($"Hội viên với ID {request.MemberId} không tồn tại.");

            // Ensure RegistrationDate has a valid value (prevent SQL datetime out-of-range)
            var registrationDate = request.RegistrationDate == default || request.RegistrationDate == DateTime.MinValue
                ? DateTime.UtcNow
                : request.RegistrationDate;

            var entity = new Session
            {
                MemberId = request.MemberId,
                ScheduleId = request.ScheduleId,
                RegistrationDate = registrationDate,
                Status = request.Status
            };
            await _repo.CreateAsync(entity);
            return await ToResponseAsync(entity);
        }

        public async Task<SessionResponse?> UpdateAsync(int id, UpdateSessionRequest request, string? userRole = null, string? userEmail = null)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

            // Ownership validation: Trainers can only update sessions for their own schedules
            if (userRole == "Trainer" && !string.IsNullOrEmpty(userEmail))
            {
                // Fetch the schedule to get the trainerId
                var schedule = await _scheduleRepo.GetByIdAsync(entity.ScheduleId);
                if (schedule is null)
                    throw new InvalidOperationException("Lịch học không tồn tại.");

                // Fetch all trainers to match email
                var trainersResult = await _trainerRepo.GetAllAsync(1, 1000, null, null, null);
                var trainers = trainersResult.Data;
                
                var trainer = trainers.FirstOrDefault(t => 
                    !string.IsNullOrEmpty(t.Email) && 
                    t.Email.Trim().Equals(userEmail.Trim(), StringComparison.OrdinalIgnoreCase));

                if (trainer is null || schedule.TrainerId != trainer.TrainerId)
                {
                    throw new UnauthorizedAccessException("Bạn chỉ có thể duyệt đăng ký cho lớp học của mình.");
                }
            }

            entity.Status = request.Status;
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

        private async Task<SessionResponse> ToResponseAsync(Session s)
        {
            // Fetch related data
            var member = await _memberRepo.GetByIdAsync(s.MemberId);
            var schedule = await _scheduleRepo.GetByIdAsync(s.ScheduleId);
            
            string trainerName = "-";
            if (schedule != null && schedule.TrainerId > 0)
            {
                var trainer = await _trainerRepo.GetByIdAsync(schedule.TrainerId);
                trainerName = trainer?.FullName ?? "-";
            }
            
            return new SessionResponse
            {
                SessionId = s.SessionId,
                MemberId = s.MemberId,
                MemberName = member?.FullName ?? "-",
                ScheduleId = s.ScheduleId,
                ClassName = schedule?.ClassName ?? "-",
                TrainerName = trainerName,
                ClassStartTime = schedule?.StartTime,
                ClassEndTime = schedule?.EndTime,
                RegistrationDate = s.RegistrationDate,
                Status = s.Status,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            };
        }

        private static SessionResponse ToResponse(
            Session s,
            Dictionary<int, Member> memberDict,
            Dictionary<int, Schedule> scheduleDict,
            Dictionary<int, Trainer> trainerDict)
        {
            memberDict.TryGetValue(s.MemberId, out var member);
            scheduleDict.TryGetValue(s.ScheduleId, out var schedule);
            
            string trainerName = "-";
            if (schedule != null && schedule.TrainerId > 0)
            {
                trainerDict.TryGetValue(schedule.TrainerId, out var trainer);
                trainerName = trainer?.FullName ?? "-";
            }
            
            return new SessionResponse
            {
                SessionId = s.SessionId,
                MemberId = s.MemberId,
                MemberName = member?.FullName ?? "-",
                ScheduleId = s.ScheduleId,
                ClassName = schedule?.ClassName ?? "-",
                TrainerName = trainerName,
                ClassStartTime = schedule?.StartTime,
                ClassEndTime = schedule?.EndTime,
                RegistrationDate = s.RegistrationDate,
                Status = s.Status,
                CreatedAt = s.CreatedAt,
                UpdatedAt = s.UpdatedAt
            };
        }
    }
}
