using Dapper;
using GymManegement.API.DTOs.Common;
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
            return await conn.QueryAsync<Session>("SELECT * FROM Sessions WHERE IsDeleted = 0 ORDER BY SessionId");
        }

        public async Task<PagedResult<Session>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            sortBy ??= "SessionId";
            sortDir = sortDir?.ToUpper() == "DESC" ? "DESC" : "ASC";

            var whereClauses = new List<string> { "IsDeleted = 0" };
            if (!string.IsNullOrWhiteSpace(searchTerm))
                whereClauses.Add("(Status LIKE @Search)");

            var where = string.Join(" AND ", whereClauses);
            var countSql = $"SELECT COUNT(*) FROM Sessions WHERE {where}";
            var dataSql = $@"
                SELECT * FROM Sessions WHERE {where}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var total = await conn.ExecuteScalarAsync<int>(countSql, new { Search = $"%{searchTerm}%" });
            var data = await conn.QueryAsync<Session>(dataSql, new
            {
                Search = $"%{searchTerm}%",
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            });

            return new PagedResult<Session>
            {
                Data = data.ToList(),
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Session?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Session>(
                "SELECT * FROM Sessions WHERE SessionId = @Id AND IsDeleted = 0",
                new { Id = id });
        }

        public async Task<IEnumerable<Session>> GetByScheduleIdAsync(int scheduleId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>(
                "SELECT * FROM Sessions WHERE ScheduleId = @ScheduleId AND IsDeleted = 0 ORDER BY RegistrationDate DESC",
                new { ScheduleId = scheduleId });
        }

        public async Task<IEnumerable<Session>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>(
                "SELECT * FROM Sessions WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY RegistrationDate DESC",
                new { MemberId = memberId });
        }

        public async Task<IEnumerable<Session>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Session>(
                "SELECT * FROM Sessions WHERE Status = @Status AND IsDeleted = 0 ORDER BY RegistrationDate DESC",
                new { Status = status });
        }

        public async Task<Session> CreateAsync(Session entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Sessions (MemberId, ScheduleId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted)
                VALUES (@MemberId, @ScheduleId, @RegistrationDate, @Status, GETDATE(), GETDATE(), 0);
                SELECT CAST(SCOPE_IDENTITY() AS INT);";
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.MemberId,
                entity.ScheduleId,
                entity.RegistrationDate,
                entity.Status
            });
            entity.SessionId = id;
            return entity;
        }

        public async Task<Session> UpdateAsync(Session entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Sessions
                SET Status = @Status, UpdatedAt = GETDATE()
                WHERE SessionId = @SessionId AND IsDeleted = 0";
            await conn.ExecuteAsync(sql, new { entity.SessionId, entity.Status });
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync(
                "UPDATE Sessions SET IsDeleted = 1, UpdatedAt = GETDATE() WHERE SessionId = @Id",
                new { Id = id });
        }
    }
}
