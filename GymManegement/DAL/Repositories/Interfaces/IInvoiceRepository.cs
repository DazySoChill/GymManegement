using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IInvoiceRepository : IRepository<Invoice>
    {
        Task<IEnumerable<Invoice>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Invoice>> GetByStatusAsync(string status);
        /// <summary>Hóa đơn quá hạn chưa thanh toán</summary>
        Task<IEnumerable<Invoice>> GetOverdueAsync();
        /// <summary>Tổng doanh thu theo tháng/năm</summary>
        Task<decimal> GetTotalRevenueAsync(int month, int year);
    }
}
