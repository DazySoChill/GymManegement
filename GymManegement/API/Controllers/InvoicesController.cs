using GymManegement.API.DTOs.Invoice;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Gym.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class InvoicesController : ControllerBase
    {
        private readonly IInvoiceService _service;
        public InvoicesController(IInvoiceService service) => _service = service;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _service.GetAllAsync());

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var r = await _service.GetByIdAsync(id);
            return r is null ? NotFound() : Ok(r);
        }

        [HttpGet("member/{memberId:int}")]
        public async Task<IActionResult> GetByMember(int memberId)
            => Ok(await _service.GetByMemberAsync(memberId));

        [HttpGet("overdue")]
        public async Task<IActionResult> GetOverdue() => Ok(await _service.GetOverdueAsync());

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateInvoiceRequest request)
            => Ok(await _service.CreateAsync(request));

        [HttpPut("{id:int}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateInvoiceRequest request)
        {
            var ok = await _service.UpdateStatusAsync(id, request);
            return ok ? Ok() : NotFound();
        }
    }
}
