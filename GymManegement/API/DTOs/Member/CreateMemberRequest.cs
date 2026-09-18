namespace GymManegement.API.DTOs.Member
{
    public class CreateMemberRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime DateOfBirth { get; set; }
        /// <summary>Ngày tham gia (mặc định = hôm nay nếu không truyền)</summary>
        public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    }
}
