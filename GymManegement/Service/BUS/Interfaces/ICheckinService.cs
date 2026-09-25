using GymManegement.API.DTOs.Checkin;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface ICheckinService
    {
        Task<IEnumerable<CheckinResponse>> GetAllAsync();
        Task<CheckinResponse?> GetByIdAsync(int id);
        Task<CheckinResponse> CreateManualAsync(CreateCheckinRequest request);
        Task<object> CheckinByQRAsync(QRCheckinRequest request);
    }
}
