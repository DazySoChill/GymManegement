using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class CheckinRepository : ICheckinRepository
    {
        private readonly DapperContext _db;
        public CheckinRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Checkin>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Checkin>("sp_Checkin_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<PagedResult<Checkin>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            var parameters = new
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                SearchTerm = searchTerm,
                SortBy = sortBy ?? "CheckinId",
                SortDir = sortDir ?? "ASC"
            };
            var result = await conn.QueryMultipleAsync(
                "sp_Checkin_GetPaged",
                parameters,
                commandType: System.Data.CommandType.StoredProcedure);

            var data = (await result.ReadAsync<Checkin>()).ToList();
            var total = await result.ReadSingleAsync<int>();

            return new PagedResult<Checkin>
            {
                Data = data,
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Checkin?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Checkin>("sp_Checkin_GetById", new { CheckinId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Checkin>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Checkin>("sp_Checkin_GetByMember", new { MemberId = memberId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Checkin>> GetBySessionIdAsync(int sessionId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Checkin>("SELECT * FROM Checkins WHERE SessionId = @SessionId", new { SessionId = sessionId });
        }
        public async Task<IEnumerable<Checkin>> GetByDateRangeAsync(DateTime from, DateTime to)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Checkin>("sp_Checkin_GetByDateRange", new { From = from, To = to }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Checkin> CreateAsync(Checkin entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Checkin_Create",
                new { entity.MemberId, entity.SessionId, entity.CheckinTime, entity.CheckinMethod },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.CheckinId = id;
            return entity;
        }
        public async Task<Checkin> UpdateAsync(Checkin entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("UPDATE Checkins SET CheckinMethod=@CheckinMethod WHERE CheckinId=@CheckinId",
                new { entity.CheckinId, entity.CheckinMethod });
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("DELETE FROM Checkins WHERE CheckinId = @CheckinId", new { CheckinId = id });
        }
    }
}
