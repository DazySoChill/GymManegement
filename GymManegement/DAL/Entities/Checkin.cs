namespace GymManegement.DAL.Entities
{
    public class Checkin
    {
        public int CheckinId { get; set; }

        public int MemberId { get; set; }

        public DateTime CheckinTime { get; set; }

        public DateTime? CheckoutTime { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation
        public Member Member { get; set; } = null!;
    }
}
