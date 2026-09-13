using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
    {
        public void Configure(EntityTypeBuilder<Payment> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.PaymentId);

            builder.Property(x => x.PaymentId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.Amount)
                .HasPrecision(18, 2);

            builder.Property(x => x.PaymentDate)
                .IsRequired();

            builder.Property(x => x.PaymentMethod)
                .HasMaxLength(30)
                .IsRequired();

            builder.Property(x => x.Status)
                .HasMaxLength(30)
                .IsRequired()
                .HasDefaultValue("Pending");

            // ── Relationships ─────────────────────────────────────────
            // Invoice → Payments: khai báo ở InvoiceConfiguration
        }
    }
}
