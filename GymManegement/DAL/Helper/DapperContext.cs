using Microsoft.Data.SqlClient;
using System.Data;

namespace GymManegement.DAL.Helper
{
    /// <summary>
    /// Quản lý IDbConnection cho Dapper.
    /// Đăng ký Scoped trong DI: mỗi request tạo 1 connection.
    /// </summary>
    public class DapperContext
    {
        private readonly string _connectionString;

        public DapperContext(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
        }

        public IDbConnection CreateConnection()
            => new SqlConnection(_connectionString);
    }
}
