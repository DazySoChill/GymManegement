using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Checkin;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class CheckinService : ICheckinService
    {
        private readonly ICheckinRepository _repo;
        private readonly IMemberRepository  _memberRepo;
        private readonly ISessionRepository _sessionRepo;
        private readonly IScheduleRepository _scheduleRepo;
        private readonly ITrainerRepository _trainerRepo;

        public CheckinService(
            ICheckinRepository repo, 
            IMemberRepository memberRepo,
            ISessionRepository sessionRepo,
            IScheduleRepository scheduleRepo,
            ITrainerRepository trainerRepo)
        {
            _repo = repo;
            _memberRepo = memberRepo;
            _sessionRepo = sessionRepo;
            _scheduleRepo = scheduleRepo;
            _trainerRepo = trainerRepo;
        }

        public async Task<PagedResult<CheckinResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            var result = await _repo.GetAllAsync(pageNumber, pageSize, searchTerm, sortBy, sortDir);
            
            // Batch fetch member names
            var memberIds = result.Data.Select(c => c.MemberId).Distinct().ToList();
            var members = await _memberRepo.GetByIdsAsync(memberIds);
            var memberDict = members.ToDictionary(m => m.MemberId);
            
            return new PagedResult<CheckinResponse>
            {
                Data = result.Data.Select(c => ToResponse(c, memberDict)).ToList(),
                Total = result.Total,
                PageNumber = result.PageNumber,
                PageSize = result.PageSize
            };
        }

        public async Task<CheckinResponse?> GetByIdAsync(int id)
        {
            var c = await _repo.GetByIdAsync(id);
            return c is null ? null : ToResponse(c);
        }

        public async Task<IEnumerable<CheckinResponse>> GetByMemberIdAsync(int memberId)
        {
            var list = await _repo.GetByMemberIdAsync(memberId);
            return list.Select(ToResponse);
        }

        public async Task<IEnumerable<CheckinResponse>> GetByDateRangeAsync(DateTime from, DateTime to)
        {
            var list = await _repo.GetByDateRangeAsync(from, to);
            return list.Select(ToResponse);
        }

        public async Task<IEnumerable<CheckinResponse>> GetByDateAsync(DateTime date)
        {
            var list = await _repo.GetByDateAsync(date);
            return list.Select(ToResponse);
        }

        public async Task<CheckinResponse> CreateManualAsync(CreateCheckinRequest request, string? userRole = null, string? userEmail = null)
        {
            // Validate member exists
            var member = await _memberRepo.GetByIdAsync(request.MemberId);
            if (member is null)
                throw new InvalidOperationException("Hội viên không tồn tại.");

            // Ownership validation: Trainers can only check-in members enrolled in their own schedules
            if (userRole == "Trainer" && !string.IsNullOrEmpty(userEmail))
            {
                // Get all sessions for this member with status 'Approved'
                var memberSessions = (await _sessionRepo.GetByMemberIdAsync(request.MemberId))
                    .Where(s => s.Status == "Approved")
                    .ToList();

                if (!memberSessions.Any())
                    throw new UnauthorizedAccessException("Member chưa được duyệt vào lớp nào.");

                // Get schedule IDs from approved sessions
                var scheduleIds = memberSessions.Select(s => s.ScheduleId).Distinct().ToList();
                var schedules = await _scheduleRepo.GetByIdsAsync(scheduleIds);

                // Find trainer by email
                var trainersResult = await _trainerRepo.GetAllAsync(1, 1000, null, null, null);
                var trainers = trainersResult.Data;
                
                var trainer = trainers.FirstOrDefault(t => 
                    !string.IsNullOrEmpty(t.Email) && 
                    t.Email.Trim().Equals(userEmail.Trim(), StringComparison.OrdinalIgnoreCase));

                if (trainer is null)
                    throw new UnauthorizedAccessException("Không tìm thấy thông tin trainer.");

                // Check if any of the member's schedules belong to this trainer
                var hasAccessToMember = schedules.Any(s => s.TrainerId == trainer.TrainerId);

                if (!hasAccessToMember)
                    throw new UnauthorizedAccessException("Bạn chỉ có thể check-in member trong lớp học của mình.");
            }

            var entity = new Checkin
            {
                MemberId    = request.MemberId,
                CheckinTime = request.CheckinTime == default ? DateTime.UtcNow : request.CheckinTime
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<CheckinResponse> CheckinByQRAsync(QRCheckinRequest request)
        {
            // Find member by QR code
            var member = await _memberRepo.GetByQRCodeAsync(request.QRCode);
            if (member is null)
                throw new InvalidOperationException("Mã QR không hợp lệ.");

            var entity = new Checkin
            {
                MemberId    = member.MemberId,
                CheckinTime = DateTime.UtcNow
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<CheckinResponse?> CheckoutAsync(int checkinId)
        {
            var entity = await _repo.GetByIdAsync(checkinId);
            if (entity is null) return null;

            entity.CheckoutTime = DateTime.UtcNow;
            await _repo.UpdateAsync(entity);
            return ToResponse(entity);
        }

        private static CheckinResponse ToResponse(Checkin c) => new()
        {
            CheckinId    = c.CheckinId,
            MemberId     = c.MemberId,
            MemberName   = string.Empty,
            CheckinTime  = c.CheckinTime,
            CheckoutTime = c.CheckoutTime,
            CreatedAt    = c.CreatedAt,
            UpdatedAt    = c.UpdatedAt
        };

        private static CheckinResponse ToResponse(Checkin c, Dictionary<int, Member> memberDict) => new()
        {
            CheckinId    = c.CheckinId,
            MemberId     = c.MemberId,
            MemberName   = memberDict.TryGetValue(c.MemberId, out var member) ? member.FullName : string.Empty,
            CheckinTime  = c.CheckinTime,
            CheckoutTime = c.CheckoutTime,
            CreatedAt    = c.CreatedAt,
            UpdatedAt    = c.UpdatedAt
        };
    }
}
