using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class MembershipConfiguration : IEntityTypeConfiguration<Membership>
    {
        public void Configure(EntityTypeBuilder<Membership> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.MembershipId);

            builder.Property(x => x.MembershipId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.MembershipType)
                .HasMaxLength(50)
                .IsRequired();

            builder.Property(x => x.Price)
                .HasPrecision(18, 2);

            builder.Property(x => x.StartDate)
                .IsRequired();

            builder.Property(x => x.EndDate)
                .IsRequired();

            builder.Property(x => x.IsActive)
                .HasDefaultValue(true);

            // ── Relationships ─────────────────────────────────────────
            // (Khai báo ở MemberConfiguration, không cần lặp lại ở đây)
        }
    }
}
