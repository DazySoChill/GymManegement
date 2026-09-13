using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class FacilityConfiguration : IEntityTypeConfiguration<Facility>
    {
        public void Configure(EntityTypeBuilder<Facility> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.FacilityId);

            builder.Property(x => x.FacilityId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.Name)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(x => x.Description)
                .HasMaxLength(500);

            builder.Property(x => x.IsActive)
                .HasDefaultValue(true);

            // ── Relationships ─────────────────────────────────────────

            // Facility → Schedules (1-N)
            builder.HasMany(x => x.Schedules)
                .WithOne(x => x.Facility)
                .HasForeignKey(x => x.FacilityId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
