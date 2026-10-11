using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class TrainerRepository : ITrainerRepository
    {
        private readonly DapperContext _db;
        public TrainerRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Trainer>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Trainers 
                WHERE IsDeleted = 0 
                ORDER BY CreatedAt DESC";
            return await conn.QueryAsync<Trainer>(sql);
        }

        public async Task<PagedResult<Trainer>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            
            // Whitelist validation to prevent SQL injection
            var allowedSortColumns = new[] { "TrainerId", "FullName", "Email", "Phone", "Specialization", "CreatedAt", "UpdatedAt" };
            sortBy = !string.IsNullOrEmpty(sortBy) && allowedSortColumns.Contains(sortBy) ? sortBy : "TrainerId";
            sortDir = sortDir?.ToUpperInvariant() == "DESC" ? "DESC" : "ASC";
            
            var whereClause = "WHERE IsDeleted = 0";
            if (!string.IsNullOrEmpty(searchTerm))
                whereClause += " AND (FullName LIKE @SearchTerm OR Email LIKE @SearchTerm OR Phone LIKE @SearchTerm)";

            var sql = $@"
                SELECT * FROM Trainers 
                {whereClause}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

                SELECT COUNT(*) FROM Trainers {whereClause};";

            var parameters = new
            {
                SearchTerm = searchTerm != null ? $"%{searchTerm}%" : null,
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            };

            using var multi = await conn.QueryMultipleAsync(sql, parameters);
            var data = (await multi.ReadAsync<Trainer>()).ToList();
            var total = await multi.ReadSingleAsync<int>();

            return new PagedResult<Trainer>
            {
                Data = data,
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Trainer?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Trainers 
                WHERE TrainerId = @TrainerId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Trainer>(sql, new { TrainerId = id });
        }
        public async Task<Trainer?> GetByEmailAsync(string email)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Trainers WHERE Email = @Email AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Trainer>(sql, new { Email = email });
        }
        public async Task<IEnumerable<Trainer>> GetWithSchedulesAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Trainers WHERE IsDeleted = 0";
            return await conn.QueryAsync<Trainer>(sql);
        }
        public async Task<Trainer> CreateAsync(Trainer entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Trainers (FullName, Email, Phone, Specialization, CreatedAt, UpdatedAt, IsDeleted)
                OUTPUT INSERTED.TrainerId
                VALUES (@FullName, @Email, @Phone, @Specialization, @CreatedAt, @UpdatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.FullName,
                entity.Email,
                entity.Phone,
                entity.Specialization,
                entity.CreatedAt,
                entity.UpdatedAt,
                entity.IsDeleted
            });
            
            entity.TrainerId = id;
            return entity;
        }
        public async Task<Trainer> UpdateAsync(Trainer entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Trainers 
                SET FullName = @FullName,
                    Email = @Email,
                    Phone = @Phone,
                    Specialization = @Specialization,
                    UpdatedAt = @UpdatedAt
                WHERE TrainerId = @TrainerId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.TrainerId,
                entity.FullName,
                entity.Email,
                entity.Phone,
                entity.Specialization,
                entity.UpdatedAt
            });
            
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Trainers 
                SET IsDeleted = 1,
                    DeletedAt = @DeletedAt
                WHERE TrainerId = @TrainerId";
            
            await conn.ExecuteAsync(sql, new { TrainerId = id, DeletedAt = DateTime.UtcNow });
        }

        public async Task<List<Trainer>> GetByIdsAsync(List<int> trainerIds)
        {
            if (trainerIds == null || !trainerIds.Any())
                return new List<Trainer>();
            
            var query = @"
                SELECT * FROM Trainers 
                WHERE TrainerId IN @TrainerIds AND IsDeleted = 0";
            
            using var connection = _db.CreateConnection();
            var trainers = await connection.QueryAsync<Trainer>(query, new { TrainerIds = trainerIds });
            return trainers.ToList();
        }
    }
}
