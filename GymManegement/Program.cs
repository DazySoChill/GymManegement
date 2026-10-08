using System.Text;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Implementations;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Implementations;
using GymManegement.Service.BUS.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

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
builder.Services.AddScoped<IUserRepository,       UserRepository>();

// ── Business Services ─────────────────────────────────────────
builder.Services.AddScoped<IMemberService,     MemberService>();
builder.Services.AddScoped<IMembershipService, MembershipService>();
builder.Services.AddScoped<ICheckinService,    CheckinService>();
builder.Services.AddScoped<IInvoiceService,    InvoiceService>();
builder.Services.AddScoped<IPaymentService,    PaymentService>();
builder.Services.AddScoped<IReportService,     ReportService>();
builder.Services.AddScoped<IAuthService,       AuthService>();
builder.Services.AddScoped<IExportService,     ExportService>();

// ── JWT Authentication ────────────────────────────────────────
var jwtKey = builder.Configuration["Jwt:Key"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = builder.Configuration["Jwt:Issuer"],
            ValidAudience            = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew                = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// ── API ───────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Gym Management API", Version = "v1" });

    // Cho phép nhập JWT token vào Swagger UI
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name         = "Authorization",
        Type         = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme       = "Bearer",
        BearerFormat = "JWT",
        In           = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description  = "Nhập token dạng: Bearer {token}"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                    { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// ── CORS (cho frontend gọi API) ───────────────────────────────
builder.Services.AddCors(opt =>
    opt.AddDefaultPolicy(p => p
        .AllowAnyOrigin()
        .AllowAnyMethod()
        .AllowAnyHeader()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();

// ── Serve frontend từ wwwroot/ ─────────────────────────────────
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
