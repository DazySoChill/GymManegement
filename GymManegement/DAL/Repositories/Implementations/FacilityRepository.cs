using Dapper;
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
            return await conn.QueryAsync<Facility>("sp_Facility_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Facility?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Facility>("sp_Facility_GetById", new { FacilityId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Facility>> GetActiveAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Facility>("sp_Facility_GetActive", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Facility> CreateAsync(Facility entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Facility_Create",
                new { entity.Name, entity.Description, entity.IsActive },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.FacilityId = id;
            return entity;
        }
        public async Task<Facility> UpdateAsync(Facility entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Facility_Update",
                new { entity.FacilityId, entity.Name, entity.Description, entity.IsActive },
                commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Facility_Delete", new { FacilityId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
