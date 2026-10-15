using GymManegement.API.DTOs.Checkin;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CheckinController : ControllerBase
    {
        private readonly ICheckinService _service;
        public CheckinController(ICheckinService service) => _service = service;

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10,
            [FromQuery] string? searchTerm = null, [FromQuery] string? sortBy = null, [FromQuery] string? sortDir = null)
            => Ok(await _service.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir));

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            return result != null ? Ok(result) : NotFound();
        }

        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
            => Ok(await _service.GetByMemberIdAsync(memberId));

        [HttpGet("date-range")]
        public async Task<IActionResult> GetByDateRange([FromQuery] DateTime from, [FromQuery] DateTime to)
            => Ok(await _service.GetByDateRangeAsync(from, to));

        [HttpGet("date/{date}")]
        public async Task<IActionResult> GetByDate(DateTime date)
            => Ok(await _service.GetByDateAsync(date));

        /// <summary>Check-in thủ công bởi Admin/Trainer hoặc Member tự check-in</summary>
        [HttpPost("manual")]
        public async Task<IActionResult> CreateManual([FromBody] CreateCheckinRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            
            var userRole = User.FindFirstValue(System.Security.Claims.ClaimTypes.Role) ?? User.FindFirstValue("role");
            var userEmail = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email);
            
            // Member can only check-in for themselves
            if (User.IsInRole("Member"))
            {
                var userMemberIdStr = User.FindFirst("memberId")?.Value;
                if (!int.TryParse(userMemberIdStr, out int userMemberId))
                {
                    return Forbid();
                }
                
                // Ensure member is checking in for themselves
                if (userMemberId != request.MemberId)
                {
                    return Forbid();
                }
            }
            
            var result = await _service.CreateManualAsync(request, userRole, userEmail);
            return CreatedAtAction(nameof(GetById), new { id = result.CheckinId }, result);
        }

    }
}
