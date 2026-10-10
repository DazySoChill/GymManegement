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
            var sql = @"
                SELECT * FROM Users 
                WHERE Username = @Username AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<User>(sql, new { Username = username });
        }

        public async Task<User?> GetByEmailAsync(string email)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Users 
                WHERE Email = @Email AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<User>(sql, new { Email = email });
        }

        public async Task<User?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Users 
                WHERE UserId = @UserId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<User>(sql, new { UserId = id });
        }

        public async Task<IEnumerable<User>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Users 
                WHERE IsDeleted = 0 
                ORDER BY CreatedAt DESC";
            return await conn.QueryAsync<User>(sql);
        }

        public async Task<User> CreateAsync(User entity, string plainPassword)
        {
            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor: 11);
            entity.CreatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, IsDeleted)
                OUTPUT INSERTED.UserId
                VALUES (@Username, @PasswordHash, @FullName, @Email, @Role, @IsActive, @CreatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.Username,
                entity.PasswordHash,
                entity.FullName,
                entity.Email,
                entity.Role,
                entity.IsActive,
                entity.CreatedAt,
                entity.IsDeleted
            });
            
            entity.UserId = id;
            return entity;
        }

        public async Task UpdateAsync(User entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Users 
                SET FullName = @FullName,
                    Email = @Email,
                    Role = @Role,
                    IsActive = @IsActive,
                    UpdatedAt = @UpdatedAt
                WHERE UserId = @UserId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, entity);
        }

        public async Task UpdatePasswordAsync(int userId, string newPlainPassword)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword(newPlainPassword, workFactor: 11);
            
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Users 
                SET PasswordHash = @PasswordHash,
                    UpdatedAt = @UpdatedAt
                WHERE UserId = @UserId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                UserId = userId,
                PasswordHash = hash,
                UpdatedAt = DateTime.UtcNow
            });
        }

        public async Task SetActiveAsync(int userId, bool isActive)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Users 
                SET IsActive = @IsActive,
                    UpdatedAt = @UpdatedAt
                WHERE UserId = @UserId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                UserId = userId,
                IsActive = isActive,
                UpdatedAt = DateTime.UtcNow
            });
        }

        public async Task<bool> UsernameExistsAsync(string username)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT COUNT(1) FROM Users 
                WHERE Username = @Username AND IsDeleted = 0";
            var count = await conn.ExecuteScalarAsync<int>(sql, new { Username = username });
            return count > 0;
        }

        public async Task<bool> EmailExistsAsync(string email)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT COUNT(1) FROM Users 
                WHERE Email = @Email AND IsDeleted = 0";
            var count = await conn.ExecuteScalarAsync<int>(sql, new { Email = email });
            return count > 0;
        }

        public async Task UpdateLastLoginAsync(int userId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Users 
                SET LastLoginAt = @LastLoginAt,
                    UpdatedAt = @UpdatedAt
                WHERE UserId = @UserId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                UserId = userId,
                LastLoginAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }
    }
}
