using GymManegement.API.DTOs.MemberSchedule;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MemberSchedulePreferenceController : ControllerBase
    {
        private readonly IMemberSchedulePreferenceService _service;
        
        public MemberSchedulePreferenceController(IMemberSchedulePreferenceService service) 
            => _service = service;

        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
        {
            // Validate member ownership
            var requestingMemberId = GetMemberIdFromToken();
            if (requestingMemberId.HasValue && requestingMemberId.Value != memberId && !User.IsInRole("Admin") && !User.IsInRole("Trainer"))
            {
                return Forbid();
            }
            return Ok(await _service.GetByMemberIdAsync(memberId));
        }

        [HttpGet("day/{dayOfWeek:int}")]
        [Authorize(Roles = "Admin,Trainer")]
        public async Task<IActionResult> GetByDayOfWeek(int dayOfWeek)
            => Ok(await _service.GetByDayOfWeekAsync(dayOfWeek));

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateMemberScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            
            // Validate member ownership
            var requestingMemberId = GetMemberIdFromToken();
            if (requestingMemberId.HasValue && requestingMemberId.Value != request.MemberId && !User.IsInRole("Admin") && !User.IsInRole("Trainer"))
            {
                return Forbid();
            }
            
            var result = await _service.CreateAsync(request);
            return Ok(result);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateMemberScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.UpdateAsync(id, request);
            return result != null ? Ok(result) : NotFound();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            // Get the preference to validate ownership
            var preference = await _service.GetByIdAsync(id);
            if (preference == null) return NotFound();
            
            // Validate member ownership
            var requestingMemberId = GetMemberIdFromToken();
            if (requestingMemberId.HasValue && requestingMemberId.Value != preference.MemberId && !User.IsInRole("Admin") && !User.IsInRole("Trainer"))
            {
                return Forbid();
            }
            
            var success = await _service.DeleteAsync(id);
            return success ? NoContent() : NotFound();
        }
        
        private int? GetMemberIdFromToken()
        {
            var claim = User.FindFirst("memberId");
            if (claim != null && int.TryParse(claim.Value, out int memberId))
            {
                return memberId;
            }
            return null;
        }
    }
}
