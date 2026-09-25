using GymManegement.API.DTOs.Membership;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MembershipsController : ControllerBase
    {
        private readonly IMembershipService _service;
        public MembershipsController(IMembershipService service) => _service = service;

        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
            => Ok(await _service.GetByMemberAsync(memberId));

        [HttpGet("member/{memberId:int}/active")]
        public async Task<IActionResult> GetActive(int memberId)
        {
            var r = await _service.GetActiveAsync(memberId);
            return r is null ? NotFound("Không có gói tập đang hoạt động.") : Ok(r);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateMembershipRequest request)
        {
            var result = await _service.CreateAsync(request);
            return Ok(result);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateMembershipRequest request)
        {
            var ok = await _service.UpdateAsync(id, request);
            return ok ? Ok() : NotFound();
        }
    }
}
