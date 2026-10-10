namespace GymManegement.DAL.Entities
{
    public class Session
    {
        public int SessionId { get; set; }

        public int ScheduleId { get; set; }

        public int MemberId { get; set; }

        public DateTime RegistrationDate { get; set; }

        /// <summary>Status: Registered | Attended | Cancelled</summary>
        public string Status { get; set; } = "Registered";

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }

        // Navigation - SQL2 relationships
        public Schedule Schedule { get; set; } = null!;

        public Member Member { get; set; } = null!;
        // Note: Checkins → Members directly, not via Sessions
    }
}
