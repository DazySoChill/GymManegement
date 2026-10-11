using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class ScheduleRepository : IScheduleRepository
    {
        private readonly DapperContext _db;
        public ScheduleRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Schedule>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Schedules WHERE IsDeleted = 0 ORDER BY StartTime DESC";
            return await conn.QueryAsync<Schedule>(sql);
        }

        public async Task<PagedResult<Schedule>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            
            sortBy ??= "ScheduleId";
            sortDir ??= "DESC";
            
            var whereClause = "WHERE IsDeleted = 0";
            
            var sql = $@"
                SELECT * FROM Schedules 
                {whereClause}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

                SELECT COUNT(*) FROM Schedules {whereClause};";

            var parameters = new
            {
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            };

            using var multi = await conn.QueryMultipleAsync(sql, parameters);
            var data = (await multi.ReadAsync<Schedule>()).ToList();
            var total = await multi.ReadSingleAsync<int>();

            return new PagedResult<Schedule>
            {
                Data = data,
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<Schedule?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Schedules WHERE ScheduleId = @ScheduleId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Schedule>(sql, new { ScheduleId = id });
        }

        public async Task<IEnumerable<Schedule>> GetByTrainerIdAsync(int trainerId)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Schedules WHERE TrainerId = @TrainerId AND IsDeleted = 0 ORDER BY StartTime DESC";
            return await conn.QueryAsync<Schedule>(sql, new { TrainerId = trainerId });
        }

        public async Task<IEnumerable<Schedule>> GetByFacilityIdAsync(int facilityId)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM Schedules WHERE FacilityId = @FacilityId AND IsDeleted = 0 ORDER BY StartTime DESC";
            return await conn.QueryAsync<Schedule>(sql, new { FacilityId = facilityId });
        }

        public async Task<IEnumerable<Schedule>> GetByDateAsync(DateTime date)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Schedules 
                WHERE CAST(StartTime AS DATE) = CAST(@Date AS DATE)
                  AND IsDeleted = 0
                ORDER BY StartTime ASC";
            return await conn.QueryAsync<Schedule>(sql, new { Date = date });
        }

        public async Task<bool> HasConflictAsync(int trainerId, int facilityId, DateTime start, DateTime end, int? excludeScheduleId = null)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT COUNT(1) FROM Schedules 
                WHERE IsDeleted = 0
                  AND (TrainerId = @TrainerId OR FacilityId = @FacilityId)
                  AND (@ExcludeId = 0 OR ScheduleId != @ExcludeId)
                  AND (
                    (StartTime <= @Start AND EndTime > @Start) OR
                    (StartTime < @End AND EndTime >= @End) OR
                    (StartTime >= @Start AND EndTime <= @End)
                  )";
            
            var count = await conn.ExecuteScalarAsync<int>(sql, new
            {
                TrainerId = trainerId,
                FacilityId = facilityId,
                Start = start,
                End = end,
                ExcludeId = excludeScheduleId ?? 0
            });
            
            return count > 0;
        }

        public async Task<Schedule> CreateAsync(Schedule entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Schedules (TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted)
                OUTPUT INSERTED.ScheduleId
                VALUES (@TrainerId, @FacilityId, @ClassName, @StartTime, @EndTime, @MaxCapacity, @CreatedAt, @UpdatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.TrainerId,
                entity.FacilityId,
                entity.ClassName,
                entity.StartTime,
                entity.EndTime,
                entity.MaxCapacity,
                entity.CreatedAt,
                entity.UpdatedAt,
                entity.IsDeleted
            });
            
            entity.ScheduleId = id;
            return entity;
        }

        public async Task<Schedule> UpdateAsync(Schedule entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Schedules 
                SET TrainerId = @TrainerId,
                    FacilityId = @FacilityId,
                    ClassName = @ClassName,
                    StartTime = @StartTime,
                    EndTime = @EndTime,
                    MaxCapacity = @MaxCapacity,
                    UpdatedAt = @UpdatedAt
                WHERE ScheduleId = @ScheduleId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.ScheduleId,
                entity.TrainerId,
                entity.FacilityId,
                entity.ClassName,
                entity.StartTime,
                entity.EndTime,
                entity.MaxCapacity,
                entity.UpdatedAt
            });
            
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Schedules 
                SET IsDeleted = 1,
                    DeletedAt = @DeletedAt
                WHERE ScheduleId = @ScheduleId";
            
            await conn.ExecuteAsync(sql, new { ScheduleId = id, DeletedAt = DateTime.UtcNow });
        }

        public async Task<List<Schedule>> GetByIdsAsync(List<int> scheduleIds)
        {
            if (scheduleIds == null || !scheduleIds.Any())
                return new List<Schedule>();
            
            var query = @"
                SELECT * FROM Schedules 
                WHERE ScheduleId IN @ScheduleIds AND IsDeleted = 0";
            
            using var connection = _db.CreateConnection();
            var schedules = await connection.QueryAsync<Schedule>(query, new { ScheduleIds = scheduleIds });
            return schedules.ToList();
        }
    }
}
