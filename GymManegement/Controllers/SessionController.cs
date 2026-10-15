using GymManegement.API.DTOs.Session;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SessionController : ControllerBase
    {
        private readonly ISessionService _service;
        public SessionController(ISessionService service) => _service = service;

        // lấy danh sách session
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10,
            [FromQuery] string? searchTerm = null, [FromQuery] string? sortBy = null, [FromQuery] string? sortDir = null)
            => Ok(await _service.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir));

        // lấy danh sách session theo id
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            return result != null ? Ok(result) : NotFound();
        }

        // lấy danh sách session theo scheduleId
        [HttpGet("schedule/{scheduleId:int}")]
        public async Task<IActionResult> GetBySchedule(int scheduleId)
            => Ok(await _service.GetByScheduleIdAsync(scheduleId));



        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
            => Ok(await _service.GetByMemberIdAsync(memberId));



        [HttpPost]
        [Authorize(Roles = "SuperAdmin,Admin,Trainer")]
        public async Task<IActionResult> Create([FromBody] CreateSessionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.SessionId }, result);
        }


        // cập nhật session
        [HttpPut("{id:int}")]
        [Authorize(Roles = "SuperAdmin,Admin,Trainer")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateSessionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            
            // Get current user's role and email for ownership validation
            var role = User.FindFirstValue(System.Security.Claims.ClaimTypes.Role) ?? User.FindFirstValue("role");
            var email = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email);
            
            var result = await _service.UpdateAsync(id, request, role, email);
            return result != null ? Ok(result) : NotFound();
        }


        // xóa id session
        [HttpDelete("{id:int}")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Delete(int id)
            => await _service.DeleteAsync(id) ? NoContent() : NotFound();


        //trạng thái của session
        [HttpPut("{id:int}/status")]
        [Authorize(Roles = "SuperAdmin,Admin,Trainer")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateSessionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            
            // Get current user's role and email for ownership validation
            var role = User.FindFirstValue(System.Security.Claims.ClaimTypes.Role) ?? User.FindFirstValue("role");
            var email = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email);
            
            var result = await _service.UpdateAsync(id, request, role, email);
            return result != null ? Ok(result) : NotFound();
        }
    }
}
