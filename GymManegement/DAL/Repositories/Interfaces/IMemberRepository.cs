using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IMemberRepository : IRepository<Member>
    {
        Task<Member?> GetByEmailAsync(string email);
        Task<Member?> GetByQRCodeAsync(string qrCodeValue);
        Task<IEnumerable<Member>> GetByStatusAsync(string status);
        Task<bool> EmailExistsAsync(string email, int? excludeMemberId = null);
    }
}
