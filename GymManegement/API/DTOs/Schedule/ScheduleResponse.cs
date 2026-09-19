namespace GymManegement.API.DTOs.Schedule
{
    public class ScheduleResponse
    {
        public int ScheduleId { get; set; }
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public int TrainerId { get; set; }
        public string TrainerName { get; set; } = string.Empty;
        public int FacilityId { get; set; }
        public string FacilityName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }
}
