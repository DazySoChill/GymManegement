using GymManegement.API.DTOs.Common;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IExportService
    {
        Task<byte[]> ExportToExcelAsync<T>(IEnumerable<T> data, string sheetName = "Data", List<string>? columns = null);
        Task<byte[]> ExportToPdfAsync<T>(IEnumerable<T> data, string title, List<string>? columns = null);
        Task<byte[]> ExportAsync<T>(IEnumerable<T> data, ExportRequest request, string sheetName = "Data", string title = "Báo cáo");
    }
}
