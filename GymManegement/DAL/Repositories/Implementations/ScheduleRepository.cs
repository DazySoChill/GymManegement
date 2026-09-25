using Dapper;
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
            return await conn.QueryAsync<Schedule>("sp_Schedule_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Schedule?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Schedule>(
                "sp_Schedule_GetById", new { ScheduleId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Schedule>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Schedule>("SELECT * FROM Schedules WHERE MemberId = @MemberId", new { MemberId = memberId });
        }
        public async Task<IEnumerable<Schedule>> GetByTrainerIdAsync(int trainerId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Schedule>("SELECT * FROM Schedules WHERE TrainerId = @TrainerId", new { TrainerId = trainerId });
        }
        public async Task<IEnumerable<Schedule>> GetByFacilityIdAsync(int facilityId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Schedule>("SELECT * FROM Schedules WHERE FacilityId = @FacilityId", new { FacilityId = facilityId });
        }
        public async Task<bool> HasConflictAsync(int trainerId, int facilityId, DateTime start, DateTime end, int? excludeScheduleId = null)
        {
            using var conn = _db.CreateConnection();
            var result = await conn.QuerySingleAsync<int>("sp_Schedule_CheckConflict",
                new { TrainerId = trainerId, FacilityId = facilityId, StartTime = start, EndTime = end, ExcludeId = excludeScheduleId ?? 0 },
                commandType: System.Data.CommandType.StoredProcedure);
            return result > 0;
        }
        public async Task<Schedule> CreateAsync(Schedule entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Schedule_Create",
                new { entity.MemberId, entity.TrainerId, entity.FacilityId, entity.StartTime, entity.EndTime },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.ScheduleId = id;
            return entity;
        }
        public async Task<Schedule> UpdateAsync(Schedule entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Schedule_Update",
                new { entity.ScheduleId, entity.TrainerId, entity.FacilityId, entity.StartTime, entity.EndTime },
                commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Schedule_Delete", new { ScheduleId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
