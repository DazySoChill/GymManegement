namespace GymManegement.API.DTOs.Schedule
{
    public class UpdateScheduleRequest
    {
        public int TrainerId { get; set; }
        public int FacilityId { get; set; }
        public string ClassName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public int MaxCapacity { get; set; } = 20;
    }
}
