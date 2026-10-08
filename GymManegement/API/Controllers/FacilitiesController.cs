using GymManegement.API.DTOs.Facility;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FacilitiesController : ControllerBase
    {
        private readonly IFacilityRepository _repo;
        public FacilitiesController(IFacilityRepository repo) => _repo = repo;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _repo.GetAllAsync());

        [HttpGet("active")]
        public async Task<IActionResult> GetActive() => Ok(await _repo.GetActiveAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var r = await _repo.GetByIdAsync(id);
            return r is null ? NotFound() : Ok(r);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateFacilityRequest req)
        {
            var entity = new Facility { Name=req.Name, Description=req.Description, IsActive=req.IsActive };
            await _repo.CreateAsync(entity);
            return CreatedAtAction(nameof(GetById), new { id = entity.FacilityId }, entity);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateFacilityRequest req)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return NotFound();
            entity.Name = req.Name; entity.Description = req.Description; entity.IsActive = req.IsActive;
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
