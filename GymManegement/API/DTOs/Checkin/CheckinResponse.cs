namespace GymManegement.API.DTOs.Checkin
{
    public class CheckinResponse
    {
        public int CheckinId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public int SessionId { get; set; }
        public DateTime CheckinTime { get; set; }
        public string CheckinMethod { get; set; } = string.Empty;
    }
}
