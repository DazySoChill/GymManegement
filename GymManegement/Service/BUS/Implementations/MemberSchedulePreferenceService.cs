using GymManegement.API.DTOs.MemberSchedule;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class MemberSchedulePreferenceService : IMemberSchedulePreferenceService
    {
        private readonly IMemberSchedulePreferenceRepository _repo;
        private readonly IMemberRepository _memberRepo;

        public MemberSchedulePreferenceService(
            IMemberSchedulePreferenceRepository repo, 
            IMemberRepository memberRepo)
        {
            _repo = repo;
            _memberRepo = memberRepo;
        }

        public async Task<MemberScheduleResponse?> GetByIdAsync(int preferenceId)
        {
            var pref = await _repo.GetByIdAsync(preferenceId);
            if (pref is null) return null;
            
            var member = await _memberRepo.GetByIdAsync(pref.MemberId);
            return ToResponse(pref, member?.FullName ?? string.Empty);
        }

        public async Task<IEnumerable<MemberScheduleResponse>> GetByMemberIdAsync(int memberId)
        {
            var list = await _repo.GetByMemberIdAsync(memberId);
            var member = await _memberRepo.GetByIdAsync(memberId);
            return list.Select(p => ToResponse(p, member?.FullName ?? string.Empty));
        }

        public async Task<IEnumerable<MemberScheduleResponse>> GetByDayOfWeekAsync(int dayOfWeek)
        {
            var list = await _repo.GetByDayOfWeekAsync(dayOfWeek);
            var responses = new List<MemberScheduleResponse>();
            
            foreach (var pref in list)
            {
                var member = await _memberRepo.GetByIdAsync(pref.MemberId);
                responses.Add(ToResponse(pref, member?.FullName ?? string.Empty));
            }
            
            return responses;
        }

        public async Task<MemberScheduleResponse> CreateAsync(CreateMemberScheduleRequest request)
        {
            // Validate member exists
            var member = await _memberRepo.GetByIdAsync(request.MemberId);
            if (member is null)
                throw new InvalidOperationException("Hội viên không tồn tại.");

            // Validate DayOfWeek
            if (request.DayOfWeek < 0 || request.DayOfWeek > 6)
                throw new ArgumentException("Ngày trong tuần phải từ 0 (Chủ Nhật) đến 6 (Thứ Bảy).");

            // Parse and validate times
            if (!TimeSpan.TryParse(request.StartTime, out var startTime))
                throw new ArgumentException("Định dạng giờ bắt đầu không hợp lệ.");
            if (!TimeSpan.TryParse(request.EndTime, out var endTime))
                throw new ArgumentException("Định dạng giờ kết thúc không hợp lệ.");
            if (endTime <= startTime)
                throw new ArgumentException("Giờ kết thúc phải sau giờ bắt đầu.");

            var entity = new MemberSchedulePreference
            {
                MemberId = request.MemberId,
                DayOfWeek = request.DayOfWeek,
                StartTime = startTime,
                EndTime = endTime
            };
            
            await _repo.CreateAsync(entity);
            return ToResponse(entity, member.FullName);
        }

        public async Task<MemberScheduleResponse?> UpdateAsync(int preferenceId, UpdateMemberScheduleRequest request)
        {
            var entity = await _repo.GetByIdAsync(preferenceId);
            if (entity is null) return null;

            // Validate DayOfWeek
            if (request.DayOfWeek < 0 || request.DayOfWeek > 6)
                throw new ArgumentException("Ngày trong tuần phải từ 0 (Chủ Nhật) đến 6 (Thứ Bảy).");

            // Parse and validate times
            if (!TimeSpan.TryParse(request.StartTime, out var startTime))
                throw new ArgumentException("Định dạng giờ bắt đầu không hợp lệ.");
            if (!TimeSpan.TryParse(request.EndTime, out var endTime))
                throw new ArgumentException("Định dạng giờ kết thúc không hợp lệ.");
            if (endTime <= startTime)
                throw new ArgumentException("Giờ kết thúc phải sau giờ bắt đầu.");

            entity.DayOfWeek = request.DayOfWeek;
            entity.StartTime = startTime;
            entity.EndTime = endTime;
            entity.IsActive = request.IsActive;

            await _repo.UpdateAsync(entity);
            
            var member = await _memberRepo.GetByIdAsync(entity.MemberId);
            return ToResponse(entity, member?.FullName ?? string.Empty);
        }

        public async Task<bool> DeleteAsync(int preferenceId)
        {
            await _repo.DeleteAsync(preferenceId);
            return true;
        }

        private static MemberScheduleResponse ToResponse(MemberSchedulePreference pref, string memberName) => new()
        {
            PreferenceId = pref.PreferenceId,
            MemberId = pref.MemberId,
            MemberName = memberName,
            DayOfWeek = pref.DayOfWeek,
            DayOfWeekName = GetDayOfWeekName(pref.DayOfWeek),
            StartTime = pref.StartTime,
            EndTime = pref.EndTime,
            IsActive = pref.IsActive,
            CreatedAt = pref.CreatedAt
        };

        private static string GetDayOfWeekName(int dayOfWeek) => dayOfWeek switch
        {
            0 => "Chủ Nhật",
            1 => "Thứ Hai",
            2 => "Thứ Ba",
            3 => "Thứ Tư",
            4 => "Thứ Năm",
            5 => "Thứ Sáu",
            6 => "Thứ Bảy",
            _ => "Không xác định"
        };
    }
}
