using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class MembershipRepository : IMembershipRepository
    {
        private readonly DapperContext _db;
        public MembershipRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Membership>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Membership>("SELECT * FROM Memberships ORDER BY StartDate DESC");
        }
        public async Task<Membership?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Membership>(
                "sp_Membership_GetById", new { MembershipId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Membership>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Membership>(
                "sp_Membership_GetByMember", new { MemberId = memberId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Membership?> GetActiveMembershipAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Membership>(
                "sp_Membership_GetActive", new { MemberId = memberId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Membership>> GetExpiringSoonAsync(int daysAhead = 7)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Membership>(
                "sp_Membership_GetExpiringSoon", new { DaysAhead = daysAhead }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Membership> CreateAsync(Membership entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Membership_Create",
                new { entity.MemberId, entity.MembershipType, entity.Price, entity.StartDate, entity.EndDate },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.MembershipId = id;
            return entity;
        }
        public async Task<Membership> UpdateAsync(Membership entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Membership_Update",
                new { entity.MembershipId, entity.MembershipType, entity.Price, entity.StartDate, entity.EndDate, entity.IsActive },
                commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("DELETE FROM Memberships WHERE MembershipId = @MembershipId", new { MembershipId = id });
        }
    }
}
