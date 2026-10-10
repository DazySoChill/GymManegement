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
        public SessionService(ISessionRepository repo) => _repo = repo;

        public async Task<PagedResult<SessionResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            return new PagedResult<SessionResponse>
            {
                Data = result.Data.Select(ToResponse).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<SessionResponse?> GetByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : ToResponse(entity);
        }

        public async Task<IEnumerable<SessionResponse>> GetByScheduleIdAsync(int scheduleId)
        {
            var entities = await _repo.GetByScheduleIdAsync(scheduleId);
            return entities.Select(ToResponse);
        }

        public async Task<IEnumerable<SessionResponse>> GetByStatusAsync(string status)
        {
            var entities = await _repo.GetByStatusAsync(status);
            return entities.Select(ToResponse);
        }

        public async Task<SessionResponse> CreateAsync(CreateSessionRequest request)
        {
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
            return ToResponse(entity);
        }

        public async Task<SessionResponse?> UpdateAsync(int id, UpdateSessionRequest request)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return null;

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

        private static SessionResponse ToResponse(Session s) => new SessionResponse
        {
            SessionId = s.SessionId,
            MemberId = s.MemberId,
            ScheduleId = s.ScheduleId,
            RegistrationDate = s.RegistrationDate,
            Status = s.Status,
            CreatedAt = s.CreatedAt,
            UpdatedAt = s.UpdatedAt
        };
    }
}
