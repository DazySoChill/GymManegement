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
            var responses = new List<SessionResponse>();
            
            foreach (var session in result.Data)
            {
                responses.Add(await ToResponseAsync(session));
            }
            
            return new PagedResult<SessionResponse>
            {
                Data = responses,
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<SessionResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : await ToResponseAsync(entity);
        }

        public async Task<IEnumerable<SessionResponse>> GetByScheduleIdAsync(int scheduleId)
        {
            var entities = await _repo.GetByScheduleIdAsync(scheduleId);
            var responses = new List<SessionResponse>();
            foreach (var entity in entities)
            {
                responses.Add(await ToResponseAsync(entity));
            }
            return responses;
        }

        public async Task<IEnumerable<SessionResponse>> GetByMemberIdAsync(int memberId)
        {
            var entities = await _repo.GetByMemberIdAsync(memberId);
            var responses = new List<SessionResponse>();
            foreach (var entity in entities)
            {
                responses.Add(await ToResponseAsync(entity));
            }
            return responses;
        }

        public async Task<IEnumerable<SessionResponse>> GetByStatusAsync(string status)
        {
            var entities = await _repo.GetByStatusAsync(status);
            var responses = new List<SessionResponse>();
            foreach (var entity in entities)
            {
                responses.Add(await ToResponseAsync(entity));
            }
            return responses;
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

        public async Task<SessionResponse?> UpdateAsync(int id, UpdateSessionRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

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
    }
}
