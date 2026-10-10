using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IAuditLogRepository
    {
        Task CreateAsync(string tableName, int recordId, string action, int? userId = null, 
            string? username = null, string? oldValues = null, string? newValues = null, string? ipAddress = null);
        Task<IEnumerable<AuditLog>> GetByRecordAsync(string tableName, int recordId);
    }
}
