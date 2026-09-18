namespace GymManegement.API.DTOs.Trainer
{
    public class TrainerResponse
    {
        public int TrainerId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Specialization { get; set; } = string.Empty;
    }
}
