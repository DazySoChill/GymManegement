using System.Reflection;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using GymManegement.API.DTOs.Common;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class ExportService : IExportService
    {
        public ExportService()
        {
            QuestPDF.Settings.License = LicenseType.Community;
        }

        public Task<byte[]> ExportToExcelAsync<T>(IEnumerable<T> data, string sheetName = "Data", List<string>? columns = null)
        {
            throw new NotImplementedException("Excel export moved to frontend. Use CSV export in browser.");
        }

        public async Task<byte[]> ExportToPdfAsync<T>(IEnumerable<T> data, string title = "Report", List<string>? columns = null)
        {
            return await Task.Run(() =>
            {
                var properties = GetProperties<T>(columns);
                var dataList = data.ToList();
                
                var document = Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        page.Size(PageSizes.A4.Landscape());
                        page.Margin(2, Unit.Centimetre);
                        page.PageColor(Colors.White);
                        page.DefaultTextStyle(x => x.FontSize(10));
                        page.Header().Text(title).SemiBold().FontSize(20).FontColor(Colors.Blue.Medium);
                        page.Content().PaddingVertical(1, Unit.Centimetre).Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                for (int i = 0; i < properties.Count; i++)
                                    columns.RelativeColumn();
                            });
                            table.Header(header =>
                            {
                                foreach (var prop in properties)
                                {
                                    header.Cell().Border(1).BorderColor(Colors.Grey.Lighten2).Background(Colors.Grey.Lighten3).Padding(5).Text(GetDisplayName(prop)).Bold();
                                }
                            });
                            foreach (var item in dataList)
                            {
                                foreach (var prop in properties)
                                {
                                    var value = prop.GetValue(item);
                                    table.Cell().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(5).Text(value?.ToString() ?? string.Empty);
                                }
                            }
                        });
                        page.Footer().AlignCenter().Text(x => { x.Span("Page "); x.CurrentPageNumber(); });
                    });
                });
                return document.GeneratePdf();
            });
        }

        public Task<byte[]> ExportAsync<T>(IEnumerable<T> data, ExportRequest request, string sheetName = "Data", string title = "Báo cáo")
        {
            return request.Format.ToLower() switch
            {
                "excel" or "xlsx" => throw new NotImplementedException("Excel export moved to frontend"),
                "pdf" => ExportToPdfAsync(data, title, request.Columns),
                _ => throw new ArgumentException($"Unsupported format: {request.Format}")
            };
        }

        private List<PropertyInfo> GetProperties<T>(List<string>? columns)
        {
            var properties = typeof(T).GetProperties();
            if (columns == null || columns.Count == 0)
                return properties.ToList();
            return properties.Where(p => columns.Contains(p.Name)).ToList();
        }

        private string GetDisplayName(PropertyInfo property)
        {
            var displayAttr = property.GetCustomAttribute<System.ComponentModel.DataAnnotations.DisplayAttribute>();
            return displayAttr?.Name ?? property.Name;
        }
    }
}