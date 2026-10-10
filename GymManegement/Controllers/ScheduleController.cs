using GymManegement.API.DTOs.Schedule;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManegement.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ScheduleController : ControllerBase
    {
        private readonly IScheduleService _service;
        public ScheduleController(IScheduleService service) => _service = service;

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

        [HttpGet("trainer/{trainerId:int}")]
        public async Task<IActionResult> GetByTrainer(int trainerId)
            => Ok(await _service.GetByTrainerIdAsync(trainerId));

        [HttpGet("date/{date}")]
        public async Task<IActionResult> GetByDate(string date)
        {
            if (!DateTime.TryParse(date, out var parsedDate))
                return BadRequest(new { message = "Invalid date format. Use YYYY-MM-DD format." });
            return Ok(await _service.GetByDateAsync(parsedDate));
        }

        [HttpPost]
        [Authorize(Roles = "SuperAdmin,Admin,Trainer")]
        public async Task<IActionResult> Create([FromBody] CreateScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.ScheduleId }, result);
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "SuperAdmin,Admin,Trainer")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateScheduleRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var result = await _service.UpdateAsync(id, request);
            return result != null ? Ok(result) : NotFound();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Delete(int id)
            => await _service.DeleteAsync(id) ? NoContent() : NotFound();
    }
}
