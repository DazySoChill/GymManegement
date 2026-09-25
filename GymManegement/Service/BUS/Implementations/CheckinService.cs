using Dapper;
using GymManegement.API.DTOs.Checkin;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class CheckinService : ICheckinService
    {
        private readonly ICheckinRepository _repo;
        private readonly IMemberRepository  _memberRepo;
        private readonly IMembershipRepository _membershipRepo;
        private readonly DapperContext      _db;

        public CheckinService(ICheckinRepository repo, IMemberRepository memberRepo,
            IMembershipRepository membershipRepo, DapperContext db)
        {
            _repo = repo; _memberRepo = memberRepo;
            _membershipRepo = membershipRepo; _db = db;
        }

        public async Task<IEnumerable<CheckinResponse>> GetAllAsync()
        {
            var list = await _repo.GetAllAsync();
            return list.Select(ToResponse);
        }

        public async Task<CheckinResponse?> GetByIdAsync(int id)
        {
            var c = await _repo.GetByIdAsync(id);
            return c is null ? null : ToResponse(c);
        }

        public async Task<CheckinResponse> CreateManualAsync(CreateCheckinRequest request)
        {
            // Validate membership
            var active = await _membershipRepo.GetActiveMembershipAsync(request.MemberId);
            if (active is null)
                throw new InvalidOperationException("Hội viên không có gói tập còn hiệu lực.");

            var entity = new Checkin
            {
                MemberId      = request.MemberId,
                SessionId     = request.SessionId,
                CheckinTime   = request.CheckinTime == default ? DateTime.UtcNow : request.CheckinTime,
                CheckinMethod = request.CheckinMethod
            };
            await _repo.CreateAsync(entity);
            return ToResponse(entity);
        }

        public async Task<object> CheckinByQRAsync(QRCheckinRequest request)
        {
            using var conn = _db.CreateConnection();
            var result = await conn.QuerySingleAsync(
                "sp_Checkin_ByQRCode",
                new { request.QRCodeValue, request.SessionId },
                commandType: System.Data.CommandType.StoredProcedure);
            return new { CheckinId = (int)result.CheckinId, Message = (string)result.Message };
        }

        private static CheckinResponse ToResponse(Checkin c) => new()
        {
            CheckinId     = c.CheckinId,
            MemberId      = c.MemberId,
            MemberName    = string.Empty,
            SessionId     = c.SessionId,
            CheckinTime   = c.CheckinTime,
            CheckinMethod = c.CheckinMethod
        };
    }
}
