using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class AuditLogRepository : IAuditLogRepository
    {
        private readonly DapperContext _db;
        public AuditLogRepository(DapperContext db) => _db = db;

        public async Task CreateAsync(string tableName, int recordId, string action, int? userId = null,
            string? username = null, string? oldValues = null, string? newValues = null, string? ipAddress = null)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_AuditLog_Create",
                new { TableName = tableName, RecordId = recordId, Action = action, UserId = userId,
                      Username = username, OldValues = oldValues, NewValues = newValues, IpAddress = ipAddress },
                commandType: System.Data.CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<AuditLog>> GetByRecordAsync(string tableName, int recordId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<AuditLog>("sp_AuditLog_GetByRecord",
                new { TableName = tableName, RecordId = recordId },
                commandType: System.Data.CommandType.StoredProcedure);
        }
    }
}
