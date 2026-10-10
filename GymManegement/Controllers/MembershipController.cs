using GymManegement.API.DTOs.Membership;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MembershipController : ControllerBase
    {
        private readonly IMembershipService _service;
        public MembershipController(IMembershipService service) => _service = service;

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

        [HttpGet("member/{memberId:int}/active")]
        public async Task<IActionResult> GetActiveMembership(int memberId)
        {
            var result = await _service.GetActiveMembershipAsync(memberId);
            return result != null ? Ok(result) : NotFound();
        }

        [HttpGet("active")]
        public async Task<IActionResult> GetActive()
            => Ok(await _service.GetActiveAsync());

        [HttpGet("expiring")]
        public async Task<IActionResult> GetExpiring([FromQuery] int daysAhead = 7)
            => Ok(await _service.GetExpiringSoonAsync(daysAhead));

        [HttpPost("purchase")]
        [Authorize] // Allow all authenticated users (including Members)
        public async Task<IActionResult> Purchase([FromBody] CreateMembershipRequest request)
        {
            // Members can only purchase for themselves
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            if (userRole == "Member")
            {
                // Verify memberId matches current user
                var userMemberIdStr = User.FindFirst("memberId")?.Value;
                if (int.TryParse(userMemberIdStr, out int userMemberId) && userMemberId != request.MemberId)
                {
                    return Forbid(); // Member can only buy for themselves
                }
            }
            
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.MembershipId }, result);
        }

        [HttpPost]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Create([FromBody] CreateMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.MembershipId }, result);
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.UpdateAsync(id, request);
            return result != null ? Ok(result) : NotFound();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> Delete(int id)
            => await _service.DeleteAsync(id) ? NoContent() : NotFound();

        /// <summary>Renew membership - creates new membership based on existing one</summary>
        [HttpPost("{id:int}/renew")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Renew(int id, [FromBody] CreateMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            
            // Get existing membership to copy MemberId
            var existing = await _service.GetByIdAsync(id);
            if (existing == null) return NotFound();
            
            // Override MemberId from existing
            request.MemberId = existing.MemberId;
            
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.MembershipId }, result);
        }

        /// <summary>Cancel membership - sets EndDate to today</summary>
        [HttpPost("{id:int}/cancel")]
        [Authorize]
        public async Task<IActionResult> Cancel(int id)
        {
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            
            // Admin/SuperAdmin can cancel any membership
            if (userRole == "Admin" || userRole == "SuperAdmin")
            {
                var membership = await _service.GetByIdAsync(id);
                if (membership == null) return NotFound();
                
                var ok = await _service.CancelAsync(id);
                return ok ? Ok(new { message = "Hủy gói tập thành công." }) : NotFound();
            }
            
            // Member can only cancel own membership - check ownership
            if (userRole == "Member")
            {
                var userMemberIdStr = User.FindFirst("memberId")?.Value;
                if (!int.TryParse(userMemberIdStr, out int userMemberId))
                    return Forbid();
                
                // Verify ownership
                var membership = await _service.GetByIdAsync(id);
                if (membership == null) return NotFound();
                if (membership.MemberId != userMemberId) return Forbid(); // Member can only cancel their own
                
                var ok = await _service.CancelAsync(id);
                return ok ? Ok(new { message = "Hủy gói tập thành công." }) : NotFound();
            }
            
            return Forbid();
        }
    }
}
