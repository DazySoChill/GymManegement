using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class MembershipRepository : IMembershipRepository
    {
        private readonly DapperContext _db;
        public MembershipRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Membership>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Memberships WHERE IsDeleted = 0 ORDER BY StartDate DESC";
            return await conn.QueryAsync<Membership>(sql);
        }

        public async Task<PagedResult<Membership>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            
            sortBy ??= "MembershipId";
            sortDir ??= "DESC";
            
            var whereClause = "WHERE IsDeleted = 0";
            
            var sql = $@"
                SELECT * FROM Memberships 
                {whereClause}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

                SELECT COUNT(*) FROM Memberships {whereClause};";

            var parameters = new
            {
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            };

            using var multi = await conn.QueryMultipleAsync(sql, parameters);
            var data = (await multi.ReadAsync<Membership>()).ToList();
            var total = await multi.ReadSingleAsync<int>();

            return new PagedResult<Membership>
            {
                Data = data,
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<Membership?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Memberships WHERE MembershipId = @MembershipId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Membership>(sql, new { MembershipId = id });
        }

        public async Task<IEnumerable<Membership>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Memberships WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY StartDate DESC";
            return await conn.QueryAsync<Membership>(sql, new { MemberId = memberId });
        }

        public async Task<Membership?> GetActiveMembershipAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT TOP 1 * FROM Memberships 
                WHERE MemberId = @MemberId 
                  AND EndDate >= CAST(GETDATE() AS DATE)
                  AND IsDeleted = 0
                ORDER BY EndDate DESC";
            return await conn.QueryFirstOrDefaultAsync<Membership>(sql, new { MemberId = memberId });
        }

        public async Task<IEnumerable<Membership>> GetExpiringSoonAsync(int daysAhead = 7)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Memberships 
                WHERE EndDate BETWEEN CAST(GETDATE() AS DATE) 
                  AND DATEADD(DAY, @DaysAhead, CAST(GETDATE() AS DATE))
                  AND IsDeleted = 0
                ORDER BY EndDate ASC";
            return await conn.QueryAsync<Membership>(sql, new { DaysAhead = daysAhead });
        }

        public async Task<IEnumerable<Membership>> GetActiveAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Memberships 
                WHERE EndDate >= CAST(GETDATE() AS DATE)
                  AND IsDeleted = 0
                ORDER BY EndDate ASC";
            return await conn.QueryAsync<Membership>(sql);
        }

        public async Task<Membership> CreateAsync(Membership entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Memberships (MemberId, PackageName, Price, StartDate, EndDate, CreatedAt, UpdatedAt, IsDeleted)
                OUTPUT INSERTED.MembershipId
                VALUES (@MemberId, @PackageName, @Price, @StartDate, @EndDate, @CreatedAt, @UpdatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.MemberId,
                entity.PackageName,
                entity.Price,
                entity.StartDate,
                entity.EndDate,
                entity.CreatedAt,
                entity.UpdatedAt,
                entity.IsDeleted
            });
            
            entity.MembershipId = id;
            return entity;
        }

        public async Task<Membership> UpdateAsync(Membership entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Memberships 
                SET PackageName = @PackageName,
                    Price = @Price,
                    StartDate = @StartDate,
                    EndDate = @EndDate,
                    UpdatedAt = @UpdatedAt
                WHERE MembershipId = @MembershipId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.MembershipId,
                entity.PackageName,
                entity.Price,
                entity.StartDate,
                entity.EndDate,
                entity.UpdatedAt
            });
            
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Memberships 
                SET IsDeleted = 1,
                    DeletedAt = @DeletedAt
                WHERE MembershipId = @MembershipId";
            
            await conn.ExecuteAsync(sql, new { MembershipId = id, DeletedAt = DateTime.UtcNow });
        }

        public async Task<bool> CancelAsync(int membershipId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Memberships 
                SET EndDate = CAST(GETDATE() AS DATE),
                    UpdatedAt = GETDATE()
                WHERE MembershipId = @MembershipId 
                  AND IsDeleted = 0
                  AND EndDate > CAST(GETDATE() AS DATE)";
            var rowsAffected = await conn.ExecuteAsync(sql, new { MembershipId = membershipId });
            return rowsAffected > 0;
        }

        public async Task<List<Membership>> GetByIdsAsync(List<int> membershipIds)
        {
            if (membershipIds == null || !membershipIds.Any())
                return new List<Membership>();
            
            var query = @"
                SELECT * FROM Memberships 
                WHERE MembershipId IN @MembershipIds AND IsDeleted = 0";
            
            using var connection = _db.CreateConnection();
            var memberships = await connection.QueryAsync<Membership>(query, new { MembershipIds = membershipIds });
            return memberships.ToList();
        }
    }
}
