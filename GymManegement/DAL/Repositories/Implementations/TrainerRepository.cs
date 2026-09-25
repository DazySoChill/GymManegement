using Dapper;
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
            return await conn.QueryAsync<Trainer>("sp_Trainer_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Trainer?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Trainer>("sp_Trainer_GetById", new { TrainerId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Trainer?> GetByEmailAsync(string email)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Trainer>("SELECT * FROM Trainers WHERE Email = @Email", new { Email = email });
        }
        public async Task<IEnumerable<Trainer>> GetWithSchedulesAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Trainer>("SELECT * FROM Trainers", commandType: System.Data.CommandType.Text);
        }
        public async Task<Trainer> CreateAsync(Trainer entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Trainer_Create",
                new { entity.FullName, entity.Phone, entity.Email, entity.Specialization },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.TrainerId = id;
            return entity;
        }
        public async Task<Trainer> UpdateAsync(Trainer entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Trainer_Update",
                new { entity.TrainerId, entity.FullName, entity.Phone, entity.Email, entity.Specialization },
                commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Trainer_Delete", new { TrainerId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
