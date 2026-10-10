namespace GymManegement.API.DTOs.Checkin
{
    public class CreateCheckinRequest
    {
        public int MemberId { get; set; }
        public DateTime CheckinTime { get; set; } = DateTime.UtcNow;
    }
}
