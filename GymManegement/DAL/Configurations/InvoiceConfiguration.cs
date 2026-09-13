using GymManegement.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GymManegement.DAL.Configurations
{
    public class InvoiceConfiguration : IEntityTypeConfiguration<Invoice>
    {
        public void Configure(EntityTypeBuilder<Invoice> builder)
        {
            // ── Primary Key ──────────────────────────────────────────
            builder.HasKey(x => x.InvoiceId);

            builder.Property(x => x.InvoiceId)
                .ValueGeneratedOnAdd();

            // ── Properties ───────────────────────────────────────────
            builder.Property(x => x.TotalAmount)
                .HasPrecision(18, 2);

            builder.Property(x => x.InvoiceDate)
                .IsRequired();

            builder.Property(x => x.DueDate)
                .IsRequired();

            builder.Property(x => x.Status)
                .HasMaxLength(30)
                .IsRequired()
                .HasDefaultValue("Pending");

            // ── Relationships ─────────────────────────────────────────

            // Invoice → Payments (1-N)
            builder.HasMany(x => x.Payments)
                .WithOne(x => x.Invoice)
                .HasForeignKey(x => x.InvoiceId)
                .OnDelete(DeleteBehavior.NoAction);

            // Member → Invoices: khai báo ở MemberConfiguration
        }
    }
}
