using System.Reflection;
using OfficeOpenXml;
using OfficeOpenXml.Style;
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
            // Cấu hình EPPlus license (non-commercial)
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            
            // Cấu hình QuestPDF license (community)
            QuestPDF.Settings.License = LicenseType.Community;
        }

        public async Task<byte[]> ExportToExcelAsync<T>(IEnumerable<T> data, string sheetName = "Data", List<string>? columns = null)
        {
            return await Task.Run(() =>
            {
                using var package = new ExcelPackage();
                var worksheet = package.Workbook.Worksheets.Add(sheetName);
                
                var properties = GetProperties<T>(columns);
                var dataList = data.ToList();
                
                // Header
                for (int i = 0; i < properties.Count; i++)
                {
                    var cell = worksheet.Cells[1, i + 1];
                    cell.Value = GetDisplayName(properties[i]);
                    cell.Style.Font.Bold = true;
                    cell.Style.Fill.PatternType = ExcelFillStyle.Solid;
                    cell.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.FromArgb(41, 98, 155));
                    cell.Style.Font.Color.SetColor(System.Drawing.Color.White);
                    cell.Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
                    cell.Style.Border.BorderAround(ExcelBorderStyle.Thin);
                }
                
                // Data rows
                for (int row = 0; row < dataList.Count; row++)
                {
                    var item = dataList[row];
                    for (int col = 0; col < properties.Count; col++)
                    {
                        var value = properties[col].GetValue(item);
                        var cell = worksheet.Cells[row + 2, col + 1];
                        cell.Value = value ?? string.Empty;
                        cell.Style.Border.BorderAround(ExcelBorderStyle.Thin);
                        
                        // Format datetime
                        if (value is DateTime dt)
                        {
                            cell.Style.Numberformat.Format = "dd/MM/yyyy HH:mm";
                        }
                    }
                }
                
                // Auto-fit columns
                worksheet.Cells.AutoFitColumns(10, 50);
                
                // Freeze header row
                worksheet.View.FreezePanes(2, 1);
                
                return package.GetAsByteArray();
            });
        }

        public async Task<byte[]> ExportToPdfAsync<T>(IEnumerable<T> data, string title, List<string>? columns = null)
        {
            return await Task.Run(() =>
            {
                var properties = GetProperties<T>(columns);
                var dataList = data.ToList();
                
                var document = Document.Create(container =>
                {
                    container.Page(page =>
                    {
                        page.Margin(30);
                        page.DefaultTextStyle(x => x.FontSize(9).FontFamily("Arial"));
                        
                        page.Header().Column(col =>
                        {
                            col.Item().AlignCenter().Text(title)
                                .FontSize(18).Bold().FontColor(Colors.Blue.Darken3);
                            col.Item().AlignCenter().Text($"Ngày xuất: {DateTime.Now:dd/MM/yyyy HH:mm}")
                                .FontSize(10).FontColor(Colors.Grey.Darken2);
                            col.Item().PaddingTop(10).LineHorizontal(1).LineColor(Colors.Blue.Darken3);
                        });
                        
                        page.Content().Table(table =>
                        {
                            // Columns definition
                            table.ColumnsDefinition(columnsDef =>
                            {
                                foreach (var _ in properties)
                                {
                                    columnsDef.RelativeColumn();
                                }
                            });
                            
                            // Header
                            table.Header(header =>
                            {
                                foreach (var prop in properties)
                                {
                                    header.Cell().Background(Colors.Blue.Darken3)
                                        .Padding(5).AlignCenter()
                                        .Text(GetDisplayName(prop))
                                        .FontColor(Colors.White).Bold().FontSize(9);
                                }
                                header.Cell().ColumnSpan((uint)properties.Count).PaddingBottom(5).BorderBottom(1).BorderColor(Colors.Blue.Darken3);
                            });
                            
                            // Data rows
                            foreach (var item in dataList)
                            {
                                foreach (var prop in properties)
                                {
                                    var value = prop.GetValue(item);
                                    string displayValue = FormatValue(value);
                                    
                                    table.Cell().Padding(4).BorderBottom(0.5f).BorderColor(Colors.Grey.Lighten2)
                                        .Text(displayValue).FontSize(8);
                                }
                            }
                        });
                        
                        page.Footer().AlignCenter().Text(text =>
                        {
                            text.Span("Trang ").FontSize(8);
                            text.CurrentPageNumber().FontSize(8);
                            text.Span(" / ").FontSize(8);
                            text.TotalPages().FontSize(8);
                        });
                    });
                });
                
                return document.GeneratePdf();
            });
        }

        public async Task<byte[]> ExportAsync<T>(IEnumerable<T> data, ExportRequest request, string sheetName = "Data", string title = "Báo cáo")
        {
            var format = request.Format?.ToLowerInvariant() ?? "excel";
            
            if (format == "pdf")
            {
                return await ExportToPdfAsync(data, title, request.Columns);
            }
            
            return await ExportToExcelAsync(data, sheetName, request.Columns);
        }

        private List<PropertyInfo> GetProperties<T>(List<string>? columns)
        {
            var allProps = typeof(T).GetProperties(BindingFlags.Public | BindingFlags.Instance)
                .Where(p => p.CanRead)
                .ToList();
            
            if (columns != null && columns.Count > 0)
            {
                return allProps.Where(p => columns.Contains(p.Name, StringComparer.OrdinalIgnoreCase)).ToList();
            }
            
            return allProps;
        }

        private string GetDisplayName(PropertyInfo prop)
        {
            // Có thể thêm Attribute [Display(Name = "...")] sau
            return prop.Name switch
            {
                "MemberId" => "Mã hội viên",
                "FullName" => "Họ tên",
                "Phone" => "Số điện thoại",
                "Email" => "Email",
                "DateOfBirth" => "Ngày sinh",
                "QRCode" => "Mã QR",
                "TrainerId" => "Mã HLĐ",
                "TrainerName" => "Tên HLĐ",
                "Specialization" => "Chuyên môn",
                "ExperienceYears" => "Số năm kinh nghiệm",
                "FacilityId" => "Mã phòng",
                "FacilityName" => "Tên phòng",
                "Capacity" => "Sức chứa",
                "MembershipId" => "Mã gói",
                "MembershipName" => "Tên gói",
                "PackageName" => "Tên gói tập",
                "Price" => "Giá",
                "DurationMonths" => "Thời hạn (tháng)",
                "ScheduleId" => "Mã lịch",
                "SessionId" => "Mã buổi",
                "CheckinId" => "Mã check-in",
                "CheckinTime" => "Thời gian check-in",
                "CheckoutTime" => "Thời gian check-out",
                "InvoiceId" => "Mã hóa đơn",
                "TotalAmount" => "Tổng tiền",
                "PaidAmount" => "Đã thanh toán",
                "PaymentDate" => "Ngày thanh toán",
                "PaymentMethod" => "Phương thức TT",
                _ => prop.Name
            };
        }

        private string FormatValue(object? value)
        {
            if (value == null) return string.Empty;
            
            return value switch
            {
                DateTime dt => dt.ToString("dd/MM/yyyy HH:mm"),
                DateOnly d => d.ToString("dd/MM/yyyy"),
                TimeOnly t => t.ToString("HH:mm"),
                decimal d => d.ToString("N0"),
                double dbl => dbl.ToString("N2"),
                bool b => b ? "Có" : "Không",
                _ => value.ToString() ?? string.Empty
            };
        }
    }
}
