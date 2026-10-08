using GymManegement.API.DTOs.Schedule;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SchedulesController : ControllerBase
    {
        private readonly IScheduleRepository _repo;
        public SchedulesController(IScheduleRepository repo) => _repo = repo;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _repo.GetAllAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var r = await _repo.GetByIdAsync(id);
            return r is null ? NotFound() : Ok(r);
        }

        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
            => Ok(await _repo.GetByMemberIdAsync(memberId));

        [HttpGet("trainer/{trainerId:int}")]
        public async Task<IActionResult> GetByTrainer(int trainerId)
            => Ok(await _repo.GetByTrainerIdAsync(trainerId));

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateScheduleRequest req)
        {
            var hasConflict = await _repo.HasConflictAsync(req.TrainerId, req.FacilityId, req.StartTime, req.EndTime);
            if (hasConflict) return Conflict("Huấn luyện viên hoặc phòng đã có lịch trong khung giờ này.");

            var entity = new Schedule { MemberId=req.MemberId, TrainerId=req.TrainerId, FacilityId=req.FacilityId, StartTime=req.StartTime, EndTime=req.EndTime };
            await _repo.CreateAsync(entity);
            return CreatedAtAction(nameof(GetById), new { id = entity.ScheduleId }, entity);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateScheduleRequest req)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return NotFound();
            var hasConflict = await _repo.HasConflictAsync(req.TrainerId, req.FacilityId, req.StartTime, req.EndTime, id);
            if (hasConflict) return Conflict("Xung đột lịch.");
            entity.TrainerId=req.TrainerId; entity.FacilityId=req.FacilityId; entity.StartTime=req.StartTime; entity.EndTime=req.EndTime;
            await _repo.UpdateAsync(entity);
            return Ok(entity);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return NotFound();
            await _repo.DeleteAsync(id);
            return NoContent();
        }
    }
}
