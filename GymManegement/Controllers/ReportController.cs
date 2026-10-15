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

       
        public ReportController(IReportService service)
        {
            _service = service;
        }

        // lấy danh sách các thành viên active
        [HttpGet("active-members")]
        public async Task<IActionResult> GetActiveMembers()
            => Ok(await _service.GetActiveMembersAsync());


        // lấy danh sách các thành viên outdate
        [HttpGet("revenue")]
        public async Task<IActionResult> GetRevenue([FromQuery] int month, [FromQuery] int year)
            => Ok(await _service.GetRevenueAsync(month, year));


        // lấy chi tiết doanh thu 
        [HttpGet("revenue/detail")]
        public async Task<IActionResult> GetRevenueDetail([FromQuery] int month, [FromQuery] int year)
            => Ok(await _service.GetRevenueDetailAsync(month, year));



        [HttpGet("expiring-soon")]
        public async Task<IActionResult> GetExpiringSoon([FromQuery] int daysAhead = 7)
            => Ok(await _service.GetExpiringSoonAsync(daysAhead));



        [HttpGet("members")]
        public async Task<IActionResult> GetMembersReport()
            => Ok(await _service.GetMembersReportAsync());
    }
}