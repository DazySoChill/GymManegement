namespace GymManegement.API.DTOs.Schedule
{
    public class UpdateScheduleRequest
    {
        public int TrainerId { get; set; }
        public int FacilityId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }
}
