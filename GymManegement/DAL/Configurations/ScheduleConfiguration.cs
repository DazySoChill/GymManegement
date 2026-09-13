using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class ScheduleConfiguration : IEntityTypeConfiguration<Schedule>
    {
        public void Configure(EntityTypeBuilder<Schedule> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.ScheduleId);

            builder.Property(x => x.ScheduleId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.StartTime)
                .IsRequired();

            builder.Property(x => x.EndTime)
                .IsRequired();

            // ── Relationships ─────────────────────────────────────────

            // Schedule → Sessions (1-N)
            builder.HasMany(x => x.Sessions)
                .WithOne(x => x.Schedule)
                .HasForeignKey(x => x.ScheduleId)
                .OnDelete(DeleteBehavior.NoAction);

            // Lưu ý: Quan hệ Member/Trainer/Facility → Schedule
            // đã được khai báo ở MemberConfig, TrainerConfig, FacilityConfig
        }
    }
}
