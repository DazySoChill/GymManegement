using GymManegement.API.DTOs.Invoice;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IInvoiceService
    {
        Task<IEnumerable<InvoiceResponse>> GetAllAsync();
        Task<InvoiceResponse?> GetByIdAsync(int id);
        Task<IEnumerable<InvoiceResponse>> GetByMemberAsync(int memberId);
        Task<IEnumerable<InvoiceResponse>> GetOverdueAsync();
        Task<InvoiceResponse> CreateAsync(CreateInvoiceRequest request);
        Task<bool> UpdateStatusAsync(int id, UpdateInvoiceRequest request);
    }
}
