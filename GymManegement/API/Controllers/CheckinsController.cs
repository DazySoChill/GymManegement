using GymManegement.API.DTOs.Checkin;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CheckinsController : ControllerBase
    {
        private readonly ICheckinService _service;
        public CheckinsController(ICheckinService service) => _service = service;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _service.GetAllAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var r = await _service.GetByIdAsync(id);
            return r is null ? NotFound() : Ok(r);
        }

        /// <summary>Check-in thủ công (Admin/Trainer)</summary>
        [HttpPost]
        public async Task<IActionResult> CreateManual([FromBody] CreateCheckinRequest request)
        {
            try { return Ok(await _service.CreateManualAsync(request)); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        /// <summary>Check-in bằng QR Code scan</summary>
        [HttpPost("qr")]
        public async Task<IActionResult> CheckinByQR([FromBody] QRCheckinRequest request)
        {
            var result = await _service.CheckinByQRAsync(request);
            return Ok(result);
        }
    }
}
