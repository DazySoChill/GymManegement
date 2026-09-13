using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class TrainerConfiguration : IEntityTypeConfiguration<Trainer>
    {
        public void Configure(EntityTypeBuilder<Trainer> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.TrainerId);

            builder.Property(x => x.TrainerId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.FullName)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(x => x.Phone)
                .HasMaxLength(20);

            builder.Property(x => x.Email)
                .HasMaxLength(150)
                .IsRequired();

            builder.Property(x => x.Specialization)
                .HasMaxLength(100);

            // ── Relationships ─────────────────────────────────────────

            // Trainer → Schedules (1-N)
            builder.HasMany(x => x.Schedules)
                .WithOne(x => x.Trainer)
                .HasForeignKey(x => x.TrainerId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
