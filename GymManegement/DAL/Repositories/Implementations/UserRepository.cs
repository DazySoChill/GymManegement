using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class UserRepository : IUserRepository
    {
        private readonly DapperContext _db;
        public UserRepository(DapperContext db) => _db = db;

        public async Task<User?> GetByUsernameAsync(string username)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<User>(
                "sp_User_GetByUsername", new { Username = username },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<User?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<User>(
                "sp_User_GetById", new { UserId = id },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<User>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<User>(
                "sp_User_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<User> CreateAsync(User entity, string plainPassword)
        {
            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor: 11);
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>(
                "sp_User_Create",
                new { entity.Username, entity.PasswordHash, entity.Role, entity.MemberId, entity.TrainerId },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.UserId = id;
            return entity;
        }

        public async Task UpdatePasswordAsync(int userId, string newPlainPassword)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword(newPlainPassword, workFactor: 11);
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_User_UpdatePassword",
                new { UserId = userId, PasswordHash = hash },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task SetActiveAsync(int userId, bool isActive)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_User_SetActive",
                new { UserId = userId, IsActive = isActive },
                commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
