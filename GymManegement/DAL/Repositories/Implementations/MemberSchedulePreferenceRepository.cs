using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class MemberSchedulePreferenceRepository : IMemberSchedulePreferenceRepository
    {
        private readonly DapperContext _db;
        public MemberSchedulePreferenceRepository(DapperContext db) => _db = db;

        public async Task<MemberSchedulePreference?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM MemberSchedulePreferences WHERE PreferenceId = @PreferenceId AND IsActive = 1";
            return await conn.QueryFirstOrDefaultAsync<MemberSchedulePreference>(sql, new { PreferenceId = id });
        }

        public async Task<IEnumerable<MemberSchedulePreference>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = "SELECT * FROM MemberSchedulePreferences WHERE IsActive = 1 ORDER BY MemberId, DayOfWeek, StartTime";
            return await conn.QueryAsync<MemberSchedulePreference>(sql);
        }

        public async Task<IEnumerable<MemberSchedulePreference>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"SELECT * FROM MemberSchedulePreferences 
                        WHERE MemberId = @MemberId AND IsActive = 1 
                        ORDER BY DayOfWeek, StartTime";
            return await conn.QueryAsync<MemberSchedulePreference>(sql, new { MemberId = memberId });
        }

        public async Task<IEnumerable<MemberSchedulePreference>> GetByDayOfWeekAsync(int dayOfWeek)
        {
            using var conn = _db.CreateConnection();
            var sql = @"SELECT * FROM MemberSchedulePreferences 
                        WHERE DayOfWeek = @DayOfWeek AND IsActive = 1 
                        ORDER BY StartTime";
            return await conn.QueryAsync<MemberSchedulePreference>(sql, new { DayOfWeek = dayOfWeek });
        }

        public async Task<MemberSchedulePreference> CreateAsync(MemberSchedulePreference entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsActive = true;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO MemberSchedulePreferences (MemberId, DayOfWeek, StartTime, EndTime, IsActive, CreatedAt, UpdatedAt)
                OUTPUT INSERTED.PreferenceId
                VALUES (@MemberId, @DayOfWeek, @StartTime, @EndTime, @IsActive, @CreatedAt, @UpdatedAt)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.MemberId,
                entity.DayOfWeek,
                entity.StartTime,
                entity.EndTime,
                entity.IsActive,
                entity.CreatedAt,
                entity.UpdatedAt
            });
            
            entity.PreferenceId = id;
            return entity;
        }

        public async Task<MemberSchedulePreference> UpdateAsync(MemberSchedulePreference entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE MemberSchedulePreferences 
                SET DayOfWeek = @DayOfWeek,
                    StartTime = @StartTime,
                    EndTime = @EndTime,
                    IsActive = @IsActive,
                    UpdatedAt = @UpdatedAt
                WHERE PreferenceId = @PreferenceId";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.PreferenceId,
                entity.DayOfWeek,
                entity.StartTime,
                entity.EndTime,
                entity.IsActive,
                entity.UpdatedAt
            });
            
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE MemberSchedulePreferences 
                SET IsActive = 0,
                    UpdatedAt = @UpdatedAt
                WHERE PreferenceId = @PreferenceId";
            
            await conn.ExecuteAsync(sql, new { PreferenceId = id, UpdatedAt = DateTime.UtcNow });
        }
    }
}
