namespace GymManegement.Service.BUS.Interfaces
{
    public interface IReportService
    {
        Task<object> GetActiveMembersAsync();
        Task<object> GetRevenueAsync(int month, int year);
        Task<object> GetRevenueDetailAsync(int month, int year);
        Task<object> GetExpiringSoonAsync(int daysAhead = 7);
    }
}
