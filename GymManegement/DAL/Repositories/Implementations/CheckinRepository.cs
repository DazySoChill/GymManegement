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
            var sql = "SELECT * FROM Checkins WHERE IsDeleted = 0 ORDER BY CheckinTime ASC";
            return await conn.QueryAsync<Checkin>(sql);
        }

        public async Task<PagedResult<Checkin>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            
            sortBy ??= "CheckinId";
            sortDir ??= "DESC";
            
            var whereClause = "WHERE IsDeleted = 0";
            
            var sql = $@"
                SELECT * FROM Checkins 
                {whereClause}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

                SELECT COUNT(*) FROM Checkins {whereClause};";

            var parameters = new
            {
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            };

            using var multi = await conn.QueryMultipleAsync(sql, parameters);
            var data = (await multi.ReadAsync<Checkin>()).ToList();
            var total = await multi.ReadSingleAsync<int>();

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
            var sql = "SELECT * FROM Checkins WHERE CheckinId = @CheckinId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Checkin>(sql, new { CheckinId = id });
        }

        public async Task<IEnumerable<Checkin>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Checkins WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY CheckinTime ASC";
            return await conn.QueryAsync<Checkin>(sql, new { MemberId = memberId });
        }

        public async Task<IEnumerable<Checkin>> GetByDateRangeAsync(DateTime from, DateTime to)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Checkins 
                WHERE CheckinTime >= @From AND CheckinTime <= @To AND IsDeleted = 0 
                ORDER BY CheckinTime ASC";
            return await conn.QueryAsync<Checkin>(sql, new { From = from, To = to });
        }

        public async Task<IEnumerable<Checkin>> GetByDateAsync(DateTime date)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Checkins 
                WHERE CAST(CheckinTime AS DATE) = CAST(@Date AS DATE)
                  AND IsDeleted = 0
                ORDER BY CheckinTime ASC";
            return await conn.QueryAsync<Checkin>(sql, new { Date = date });
        }

        public async Task<Checkin?> GetByQRCodeAsync(string qrCode)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT TOP 1 c.* 
                FROM Checkins c
                INNER JOIN Members m ON c.MemberId = m.MemberId
                WHERE m.QRCode = @QRCode AND c.IsDeleted = 0
                ORDER BY c.CheckinTime DESC";
            return await conn.QueryFirstOrDefaultAsync<Checkin>(sql, new { QRCode = qrCode });
        }

        public async Task<Checkin> CreateAsync(Checkin entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Checkins (MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted)
                OUTPUT INSERTED.CheckinId
                VALUES (@MemberId, @CheckinTime, @CheckoutTime, @CreatedAt, @UpdatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.MemberId,
                entity.CheckinTime,
                entity.CheckoutTime,
                entity.CreatedAt,
                entity.UpdatedAt,
                entity.IsDeleted
            });
            
            entity.CheckinId = id;
            return entity;
        }

        public async Task<Checkin> UpdateAsync(Checkin entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Checkins 
                SET CheckoutTime = @CheckoutTime,
                    UpdatedAt = @UpdatedAt
                WHERE CheckinId = @CheckinId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.CheckinId,
                entity.CheckoutTime,
                entity.UpdatedAt
            });
            
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Checkins 
                SET IsDeleted = 1,
                    DeletedAt = @DeletedAt
                WHERE CheckinId = @CheckinId";
            
            await conn.ExecuteAsync(sql, new { CheckinId = id, DeletedAt = DateTime.UtcNow });
        }
    }
}
