using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Member;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ExportController : ControllerBase
    {
        private readonly IExportService _exportService;
        private readonly IMemberService _memberService;

        public ExportController(IExportService exportService, IMemberService memberService)
        {
            _exportService = exportService;
            _memberService = memberService;
        }

        /// <summary>
        /// Xuất danh sách hội viên ra Excel/PDF
        /// </summary>
        [HttpPost("members")]
        public async Task<IActionResult> ExportMembers([FromBody] ExportRequest request)
        {
            try
            {
                // Lấy dữ liệu từ service (có thể thêm filter/search sau)
                var members = await _memberService.GetAllAsync();
                
                // Áp dụng filter đơn giản nếu có
                if (!string.IsNullOrWhiteSpace(request.SearchTerm))
                {
                    var term = request.SearchTerm.ToLower();
                    members = members.Where(m => 
                        m.FullName.ToLower().Contains(term) ||
                        m.Email.ToLower().Contains(term) ||
                        m.Phone.Contains(term) ||
                        m.QRCodeValue.Contains(term)
                    ).ToList();
                }

                // Áp dụng filter trạng thái
                if (request.Filters != null && request.Filters.TryGetValue("status", out var status))
                {
                    members = members.Where(m => m.Status.Equals(status, StringComparison.OrdinalIgnoreCase)).ToList();
                }

                var fileBytes = await _exportService.ExportAsync(members, request, "HoiVien", "Danh sách hội viên");
                var contentType = request.Format?.ToLower() == "pdf" 
                    ? "application/pdf" 
                    : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var extension = request.Format?.ToLower() == "pdf" ? "pdf" : "xlsx";
                var fileName = $"DanhSachHoiVien_{DateTime.Now:yyyyMMdd_HHmmss}.{extension}";

                return File(fileBytes, contentType, fileName);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Lỗi khi xuất file: {ex.Message}" });
            }
        }

        /// <summary>
        /// Xuất mẫu import hội viên (Excel template)
        /// </summary>
        [HttpGet("members/template")]
        public async Task<IActionResult> GetMemberImportTemplate()
        {
            try
            {
                // Tạo dữ liệu mẫu
                var sampleData = new List<MemberResponse>
                {
                    new MemberResponse
                    {
                        MemberId = 0,
                        FullName = "Nguyễn Văn A",
                        Phone = "0901234567",
                        Email = "nguyenvana@email.com",
                        DateOfBirth = new DateTime(1990, 1, 15),
                        JoinDate = DateTime.Now,
                        Status = "Active",
                        QRCodeValue = "QR001"
                    }
                };

                var request = new ExportRequest { Format = "excel" };
                var fileBytes = await _exportService.ExportAsync(sampleData, request, "MauImport", "Mẫu import hội viên");
                
                var fileName = $"MauImport_HoiVien_{DateTime.Now:yyyyMMdd}.xlsx";
                return File(fileBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Lỗi khi tạo mẫu: {ex.Message}" });
            }
        }
    }
}
