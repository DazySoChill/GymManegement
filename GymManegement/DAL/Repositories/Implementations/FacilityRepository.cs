using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class FacilityRepository : IFacilityRepository
    {
        private readonly DapperContext _db;
        public FacilityRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Facility>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Facility>("SELECT * FROM Facilities WHERE IsDeleted = 0 ORDER BY FacilityId");
        }

        public async Task<PagedResult<Facility>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            sortBy ??= "FacilityId";
            sortDir = sortDir?.ToUpper() == "DESC" ? "DESC" : "ASC";

            var whereClauses = new List<string> { "IsDeleted = 0" };
            if (!string.IsNullOrWhiteSpace(searchTerm))
                whereClauses.Add("(Name LIKE @Search OR Description LIKE @Search)");

            var where = string.Join(" AND ", whereClauses);
            var countSql = $"SELECT COUNT(*) FROM Facilities WHERE {where}";
            var dataSql = $@"
                SELECT * FROM Facilities WHERE {where}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var total = await conn.ExecuteScalarAsync<int>(countSql, new { Search = $"%{searchTerm}%" });
            var data = await conn.QueryAsync<Facility>(dataSql, new
            {
                Search = $"%{searchTerm}%",
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            });

            return new PagedResult<Facility>
            {
                Data = data.ToList(),
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Facility?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Facility>(
                "SELECT * FROM Facilities WHERE FacilityId = @Id AND IsDeleted = 0",
                new { Id = id });
        }

        public async Task<IEnumerable<Facility>> GetActiveAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Facility>(
                "SELECT * FROM Facilities WHERE Status = 'Active' AND IsDeleted = 0 ORDER BY Name");
        }

        public async Task<Facility> CreateAsync(Facility entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Facilities (Name, Description, Status, CreatedAt, UpdatedAt, IsDeleted)
                VALUES (@Name, @Description, @Status, GETDATE(), GETDATE(), 0);
                SELECT CAST(SCOPE_IDENTITY() AS INT);";
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.Name,
                entity.Description,
                entity.Status
            });
            entity.FacilityId = id;
            return entity;
        }

        public async Task<Facility> UpdateAsync(Facility entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Facilities
                SET Name = @Name, Description = @Description, Status = @Status, UpdatedAt = GETDATE()
                WHERE FacilityId = @FacilityId AND IsDeleted = 0";
            await conn.ExecuteAsync(sql, new
            {
                entity.FacilityId,
                entity.Name,
                entity.Description,
                entity.Status
            });
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync(
                "UPDATE Facilities SET IsDeleted = 1, UpdatedAt = GETDATE() WHERE FacilityId = @Id",
                new { Id = id });
        }
    }
}
