namespace GymManegement.API.DTOs.Member
{
    public class MemberResponse
    {
        public int MemberId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime DateOfBirth { get; set; }
        public DateTime JoinDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public string QRCodeValue { get; set; } = string.Empty;
    }
}
