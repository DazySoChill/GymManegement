namespace GymManegement.API.DTOs.Member
{
    public class UpdateMemberRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime DateOfBirth { get; set; }
        /// <summary>Active | Inactive | Suspended</summary>
        public string Status { get; set; } = string.Empty;
    }
}
