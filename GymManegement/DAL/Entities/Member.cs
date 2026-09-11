namespace GymManegement.DAL.Entities
{
    public class Member
    {
        public int MemberId { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public DateTime DateOfBirth { get; set; }

        public DateTime JoinDate { get; set; }

        /// <summary>Trạng thái hội viên: Active | Inactive | Suspended</summary>
        public string Status { get; set; } = "Active";

        /// <summary>Giá trị QR Code dùng để check-in (GUID duy nhất)</summary>
        public string QRCodeValue { get; set; } = string.Empty;

        // Navigation
        public ICollection<Membership> Memberships { get; set; }
            = new List<Membership>();

        public ICollection<Schedule> Schedules { get; set; }
            = new List<Schedule>();

        public ICollection<Checkin> Checkins { get; set; }
            = new List<Checkin>();

        public ICollection<Invoice> Invoices { get; set; }
            = new List<Invoice>();
    }
}
