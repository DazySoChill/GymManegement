using GymManegement.API.DTOs.Trainer;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TrainersController : ControllerBase
    {
        private readonly ITrainerRepository _repo;
        public TrainersController(ITrainerRepository repo) => _repo = repo;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _repo.GetAllAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var r = await _repo.GetByIdAsync(id);
            return r is null ? NotFound() : Ok(new TrainerResponse { TrainerId=r.TrainerId, FullName=r.FullName, Phone=r.Phone, Email=r.Email, Specialization=r.Specialization });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateTrainerRequest req)
        {
            var entity = new Trainer { FullName=req.FullName, Phone=req.Phone, Email=req.Email, Specialization=req.Specialization };
            await _repo.CreateAsync(entity);
            return CreatedAtAction(nameof(GetById), new { id = entity.TrainerId }, entity);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateTrainerRequest req)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return NotFound();
            entity.FullName = req.FullName; entity.Phone = req.Phone; entity.Email = req.Email; entity.Specialization = req.Specialization;
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
