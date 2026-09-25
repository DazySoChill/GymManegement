using Dapper;
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
            return await conn.QueryAsync<Member>("sp_Member_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<Member?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Member>(
                "sp_Member_GetById", new { MemberId = id },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<Member?> GetByEmailAsync(string email)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Member>(
                "sp_Member_GetByEmail", new { Email = email },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<Member?> GetByQRCodeAsync(string qrCodeValue)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Member>(
                "sp_Member_GetByQRCode", new { QRCodeValue = qrCodeValue },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<Member>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Member>(
                "sp_Member_GetByStatus", new { Status = status },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<bool> EmailExistsAsync(string email, int? excludeMemberId = null)
        {
            var member = await GetByEmailAsync(email);
            return member is not null && (excludeMemberId is null || member.MemberId != excludeMemberId);
        }

        public async Task<Member> CreateAsync(Member entity)
        {
            using var conn = _db.CreateConnection();
            var result = await conn.QuerySingleAsync<int>(
                "sp_Member_Create",
                new { entity.FullName, entity.Phone, entity.Email, entity.DateOfBirth, entity.JoinDate, entity.Status, entity.QRCodeValue },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.MemberId = result;
            return entity;
        }

        public async Task<Member> UpdateAsync(Member entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync(
                "sp_Member_Update",
                new { entity.MemberId, entity.FullName, entity.Phone, entity.Email, entity.DateOfBirth, entity.Status },
                commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Member_Delete", new { MemberId = id },
                commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
