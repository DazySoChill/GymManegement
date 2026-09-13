using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class SessionConfiguration : IEntityTypeConfiguration<Session>
    {
        public void Configure(EntityTypeBuilder<Session> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.SessionId);

            builder.Property(x => x.SessionId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.SessionDate)
                .IsRequired();

            builder.Property(x => x.Status)
                .HasMaxLength(30)
                .IsRequired()
                .HasDefaultValue("Scheduled");

            // ── Relationships ─────────────────────────────────────────

            // Session → Checkins (1-N)
            builder.HasMany(x => x.Checkins)
                .WithOne(x => x.Session)
                .HasForeignKey(x => x.SessionId)
                .OnDelete(DeleteBehavior.NoAction);

            // Lưu ý: Quan hệ Schedule → Session
            // đã được khai báo ở ScheduleConfiguration
        }
    }
}
