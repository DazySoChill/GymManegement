using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class MemberRepository : IMemberRepository
    {
        private readonly DapperContext _db;
        public MemberRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Member>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Members 
                WHERE IsDeleted = 0 
                ORDER BY CreatedAt DESC";
            return await conn.QueryAsync<Member>(sql);
        }

        public async Task<PagedResult<Member>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            
            sortBy ??= "MemberId";
            sortDir ??= "ASC";
            
            var whereClause = "WHERE IsDeleted = 0";
            if (!string.IsNullOrEmpty(searchTerm))
                whereClause += " AND (FullName LIKE @SearchTerm OR Email LIKE @SearchTerm OR Phone LIKE @SearchTerm)";

            var sql = $@"
                SELECT * FROM Members 
                {whereClause}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

                SELECT COUNT(*) FROM Members {whereClause};";

            var parameters = new
            {
                SearchTerm = searchTerm != null ? $"%{searchTerm}%" : null,
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            };

            using var multi = await conn.QueryMultipleAsync(sql, parameters);
            var data = (await multi.ReadAsync<Member>()).ToList();
            var total = await multi.ReadSingleAsync<int>();

            return new PagedResult<Member>
            {
                Data = data,
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<Member?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Members 
                WHERE MemberId = @MemberId AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Member>(sql, new { MemberId = id });
        }

        public async Task<Member?> GetByEmailAsync(string email)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Members 
                WHERE Email = @Email AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Member>(sql, new { Email = email });
        }

        public async Task<Member?> GetByQRCodeAsync(string qrCode)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Members 
                WHERE QRCode = @QRCode AND IsDeleted = 0";
            return await conn.QueryFirstOrDefaultAsync<Member>(sql, new { QRCode = qrCode });
        }

        public async Task<IEnumerable<Member>> GetByStatusAsync(string status)
        {
            // SQL2 không có Status column nữa
            // Trả về empty list hoặc throw exception
            throw new NotSupportedException("Status filtering is not supported in SQL2 schema.");
        }

        public async Task<bool> EmailExistsAsync(string email, int? excludeMemberId = null)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT COUNT(1) FROM Members 
                WHERE Email = @Email AND IsDeleted = 0 
                AND (@ExcludeMemberId IS NULL OR MemberId != @ExcludeMemberId)";
            var count = await conn.ExecuteScalarAsync<int>(sql, new { Email = email, ExcludeMemberId = excludeMemberId });
            return count > 0;
        }

        public async Task<Member> CreateAsync(Member entity)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = DateTime.UtcNow;
            entity.IsDeleted = false;

            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
                OUTPUT INSERTED.MemberId
                VALUES (@FullName, @Email, @Phone, @DateOfBirth, @QRCode, @CreatedAt, @UpdatedAt, @IsDeleted)";
            
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.FullName,
                entity.Email,
                entity.Phone,
                entity.DateOfBirth,
                entity.QRCode,
                entity.CreatedAt,
                entity.UpdatedAt,
                entity.IsDeleted
            });
            
            entity.MemberId = id;
            return entity;
        }

        public async Task<Member> UpdateAsync(Member entity)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Members 
                SET FullName = @FullName,
                    Email = @Email,
                    Phone = @Phone,
                    DateOfBirth = @DateOfBirth,
                    UpdatedAt = @UpdatedAt
                WHERE MemberId = @MemberId AND IsDeleted = 0";
            
            await conn.ExecuteAsync(sql, new
            {
                entity.MemberId,
                entity.FullName,
                entity.Email,
                entity.Phone,
                entity.DateOfBirth,
                entity.UpdatedAt
            });
            
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Members 
                SET IsDeleted = 1,
                    DeletedAt = @DeletedAt
                WHERE MemberId = @MemberId";
            
            await conn.ExecuteAsync(sql, new { MemberId = id, DeletedAt = DateTime.UtcNow });
        }

        public async Task<List<Member>> GetByIdsAsync(List<int> memberIds)
        {
            if (memberIds == null || !memberIds.Any())
                return new List<Member>();
            
            var query = @"
                SELECT * FROM Members 
                WHERE MemberId IN @MemberIds AND IsDeleted = 0";
            
            using var connection = _db.CreateConnection();
            var members = await connection.QueryAsync<Member>(query, new { MemberIds = memberIds });
            return members.ToList();
        }
    }
}
