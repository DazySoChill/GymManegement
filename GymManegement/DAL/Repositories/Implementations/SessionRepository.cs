using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class SessionRepository : ISessionRepository
    {
        private readonly DapperContext _db;
        public SessionRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Session>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>("sp_Session_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Session?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Session>("sp_Session_GetById", new { SessionId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Session>> GetByScheduleIdAsync(int scheduleId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>("sp_Session_GetBySchedule", new { ScheduleId = scheduleId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Session>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>("SELECT * FROM Sessions WHERE Status = @Status", new { Status = status });
        }
        public async Task<Session> CreateAsync(Session entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Session_Create",
                new { entity.ScheduleId, entity.SessionDate, entity.Status },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.SessionId = id;
            return entity;
        }
        public async Task<Session> UpdateAsync(Session entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Session_UpdateStatus", new { entity.SessionId, entity.Status }, commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Session_Delete", new { SessionId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
