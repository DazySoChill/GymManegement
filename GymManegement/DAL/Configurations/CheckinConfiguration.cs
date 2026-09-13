using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class CheckinConfiguration : IEntityTypeConfiguration<Checkin>
    {
        public void Configure(EntityTypeBuilder<Checkin> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.CheckinId);

            builder.Property(x => x.CheckinId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.CheckinTime)
                .IsRequired();

            builder.Property(x => x.CheckinMethod)
                .HasMaxLength(50)
                .IsRequired();

            // ── Relationships ─────────────────────────────────────────
            // Member → Checkins: khai báo ở MemberConfiguration
            // Session → Checkins: khai báo ở SessionConfiguration
        }
    }
}