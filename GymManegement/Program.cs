using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Implementations;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Implementations;
using GymManegement.Service.BUS.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// ── Dapper ───────────────────────────────────────────────────
builder.Services.AddSingleton<DapperContext>();

// ── Repositories ─────────────────────────────────────────────
builder.Services.AddScoped<IMemberRepository,     MemberRepository>();
builder.Services.AddScoped<ITrainerRepository,    TrainerRepository>();
builder.Services.AddScoped<IFacilityRepository,   FacilityRepository>();
builder.Services.AddScoped<IMembershipRepository, MembershipRepository>();
builder.Services.AddScoped<IScheduleRepository,   ScheduleRepository>();
builder.Services.AddScoped<ISessionRepository,    SessionRepository>();
builder.Services.AddScoped<ICheckinRepository,    CheckinRepository>();
builder.Services.AddScoped<IInvoiceRepository,    InvoiceRepository>();
builder.Services.AddScoped<IPaymentRepository,    PaymentRepository>();

// ── Business Services ─────────────────────────────────────────
builder.Services.AddScoped<IMemberService,     MemberService>();
builder.Services.AddScoped<IMembershipService, MembershipService>();
builder.Services.AddScoped<ICheckinService,    CheckinService>();
builder.Services.AddScoped<IInvoiceService,    InvoiceService>();
builder.Services.AddScoped<IPaymentService,    PaymentService>();
builder.Services.AddScoped<IReportService,     ReportService>();

// ── API ───────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Gym Management API", Version = "v1" });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// ── Serve frontend từ wwwroot/ ─────────────────────────────────
app.UseDefaultFiles();   // index.html at root
app.UseStaticFiles();

app.UseAuthorization();
app.MapControllers();
app.Run();
