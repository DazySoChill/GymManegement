using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "SuperAdmin,Admin")]
    public class ReportController : ControllerBase
    {
        private readonly IReportService _service;
        private readonly IExportService _export;

        public ReportController(IReportService service, IExportService export)
        {
            _service = service;
            _export = export;
        }

        [HttpGet("active-members")]
        public async Task<IActionResult> GetActiveMembers()
            => Ok(await _service.GetActiveMembersAsync());

        [HttpGet("revenue")]
        public async Task<IActionResult> GetRevenue([FromQuery] int month, [FromQuery] int year)
            => Ok(await _service.GetRevenueAsync(month, year));

        [HttpGet("revenue/detail")]
        public async Task<IActionResult> GetRevenueDetail([FromQuery] int month, [FromQuery] int year)
            => Ok(await _service.GetRevenueDetailAsync(month, year));

        [HttpGet("expiring-soon")]
        public async Task<IActionResult> GetExpiringSoon([FromQuery] int daysAhead = 7)
            => Ok(await _service.GetExpiringSoonAsync(daysAhead));

        [HttpGet("members")]
        public async Task<IActionResult> GetMembersReport()
            => Ok(await _service.GetMembersReportAsync());

        [HttpGet("revenue/export")]
        public async Task<IActionResult> ExportRevenue([FromQuery] int month, [FromQuery] int year)
        {
            var data = await _service.GetRevenueDetailAsync(month, year);
            var bytes = await _export.ExportToExcelAsync(new[] { data }, $"Revenue_{month:D2}_{year}");
            return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                $"Revenue_{month:D2}_{year}.xlsx");
        }
    }
}
