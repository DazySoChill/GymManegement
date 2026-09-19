using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;

namespace GymManegement.DAL.DbContext;

public class GymDbContext : Microsoft.EntityFrameworkCore.DbContext
{
    public GymDbContext(DbContextOptions<GymDbContext> options)
        : base(options)
    {
    }

    public DbSet<Member> Members { get; set; }
    public DbSet<Membership> Memberships { get; set; }
    public DbSet<Trainer> Trainers { get; set; }
    public DbSet<Facility> Facilities { get; set; }
    public DbSet<Schedule> Schedules { get; set; }
    public DbSet<Session> Sessions { get; set; }
    public DbSet<Checkin> Checkins { get; set; }
    public DbSet<Invoice> Invoices { get; set; }
    public DbSet<Payment> Payments { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Tự động tìm và áp dụng tất cả IEntityTypeConfiguration<T>
        // trong cùng assembly → không cần viết tay từng bảng ở đây
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(GymDbContext).Assembly);
    }
}
