using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class MemberConfiguration : IEntityTypeConfiguration<Member>
    {
        public void Configure(EntityTypeBuilder<Member> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.MemberId);

            builder.Property(x => x.MemberId)
                .ValueGeneratedOnAdd();   // IDENTITY – SQL Server tự sinh ID

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.FullName)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(x => x.Phone)
                .HasMaxLength(20);

            builder.Property(x => x.Email)
                .HasMaxLength(150)
                .IsRequired();

            builder.Property(x => x.DateOfBirth)
                .IsRequired();

            builder.Property(x => x.JoinDate)
                .IsRequired();

            builder.Property(x => x.Status)
                .HasMaxLength(20)
                .IsRequired()
                .HasDefaultValue("Active");

            builder.Property(x => x.QRCodeValue)
                .HasMaxLength(50)
                .IsRequired();

            // ── Relationships ─────────────────────────────────────────

            // Member → Memberships (1-N)
            builder.HasMany(x => x.Memberships)
                .WithOne(x => x.Member)
                .HasForeignKey(x => x.MemberId)
                .OnDelete(DeleteBehavior.NoAction);

            // Member → Schedules (1-N)
            builder.HasMany(x => x.Schedules)
                .WithOne(x => x.Member)
                .HasForeignKey(x => x.MemberId)
                .OnDelete(DeleteBehavior.NoAction);

            // Member → Checkins (1-N)
            builder.HasMany(x => x.Checkins)
                .WithOne(x => x.Member)
                .HasForeignKey(x => x.MemberId)
                .OnDelete(DeleteBehavior.NoAction);

            // Member → Invoices (1-N)
            builder.HasMany(x => x.Invoices)
                .WithOne(x => x.Member)
                .HasForeignKey(x => x.MemberId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
