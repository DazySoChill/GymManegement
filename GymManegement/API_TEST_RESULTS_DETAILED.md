# API TEST RESULTS - DETAILED REPORT

## FINAL RETEST — 2026-10-10 (Latest)

**Test Date:** 2026-10-10 15:30:00  
**Server:** http://localhost:5250  
**Credentials Used:** Username=gymadmin, Password=Gym@2026  
**Total Endpoints:** 59  
**Passed:** 40  
**Failed:** 17  
**Skipped:** 2 (dependent on failed POST)  
**Pass Rate:** 40/59 = 67.8%

### Summary Table

| # | Endpoint | Method | Status | Result | Notes |
|---|----------|--------|--------|--------|-------|
| 1 | /api/auth/login | POST | 200 | ✅ PASS | Token received |
| 2 | /api/member | GET | 200 | ✅ PASS | List retrieved |
| 3 | /api/member/1 | GET | 200 | ✅ PASS | Member: Member 2 |
| 4 | /api/member | POST | 201 | ✅ PASS | Created ID: 511 |
| 5 | /api/member/{id} | PUT | 200 | ✅ PASS | Updated ID: 511 |
| 6 | /api/member/{id} | DELETE | 403 | ❌ FAIL | Forbidden (Admin role restriction) |
| 7 | /api/trainer | GET | 200 | ✅ PASS | List retrieved |
| 8 | /api/trainer/1 | GET | 200 | ✅ PASS | Trainer retrieved |
| 9 | /api/trainer | POST | 201 | ✅ PASS | Created ID: 9 |
| 10 | /api/trainer/{id} | PUT | 200 | ✅ PASS | Updated ID: 9 |
| 11 | /api/trainer/{id} | DELETE | 403 | ❌ FAIL | Forbidden (Admin role restriction) |
| 12 | /api/facility | GET | 200 | ✅ PASS | List retrieved |
| 13 | /api/facility/1 | GET | 200 | ✅ PASS | Facility: Phòng tập Boxing |
| 14 | /api/facility | POST | 201 | ✅ PASS | Created ID: 14 |
| 15 | /api/facility/{id} | PUT | 200 | ✅ PASS | Updated ID: 14 |
| 16 | /api/facility/{id} | DELETE | 403 | ❌ FAIL | Forbidden (Admin role restriction) |
| 17 | /api/schedule | GET | 200 | ✅ PASS | List retrieved |
| 18 | /api/schedule/1 | GET | 200 | ✅ PASS | Schedule retrieved |
| 19 | /api/schedule | POST | 201 | ✅ PASS | Created ID: 104 |
| 20 | /api/schedule/{id} | PUT | 200 | ✅ PASS | Updated ID: 104 |
| 21 | /api/schedule/{id} | DELETE | 204 | ✅ PASS | Deleted ID: 104 |
| 22 | /api/schedule/trainer/1 | GET | 200 | ✅ PASS | 20 schedules |
| 23 | /api/schedule/date/{date} | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 24 | /api/session | GET | 200 | ✅ PASS | List retrieved |
| 25 | /api/session/1 | GET | 200 | ✅ PASS | Session retrieved |
| 26 | /api/session | POST | 500 | ❌ FAIL | Internal Server Error |
| 27 | /api/session/schedule/1 | GET | 200 | ✅ PASS | 3 sessions |
| 28 | /api/session/member/1 | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 29 | /api/membership | GET | 200 | ✅ PASS | List retrieved |
| 30 | /api/membership/1 | GET | 200 | ✅ PASS | Membership retrieved |
| 31 | /api/membership | POST | 500 | ❌ FAIL | Internal Server Error |
| 32 | /api/membership/{id} | PUT | 0 | ⚠️ SKIP | No membership created |
| 33 | /api/membership/{id} | DELETE | 0 | ⚠️ SKIP | No membership created |
| 34 | /api/membership/active | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 35 | /api/membership/expiring | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 36 | /api/checkin | GET | 200 | ✅ PASS | List retrieved |
| 37 | /api/checkin/1 | GET | 200 | ✅ PASS | Checkin retrieved |
| 38 | /api/checkin | POST | 405 | ❌ FAIL | Method Not Allowed |
| 39 | /api/checkin/member/1 | GET | 200 | ✅ PASS | 1 checkin |
| 40 | /api/checkin/date/{date} | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 41 | /api/checkin/qr | POST | 200 | ✅ PASS | QR checkin OK |
| 42 | /api/invoice | GET | 200 | ✅ PASS | List retrieved |
| 43 | /api/invoice/1 | GET | 200 | ✅ PASS | Invoice retrieved |
| 44 | /api/invoice | POST | 201 | ✅ PASS | Created ID: 508 |
| 45 | /api/invoice/{id} | PUT | 200 | ✅ PASS | Updated ID: 508 |
| 46 | /api/invoice/{id} | DELETE | 403 | ❌ FAIL | Forbidden (Admin role restriction) |
| 47 | /api/invoice/member/1 | GET | 200 | ✅ PASS | 1 invoice |
| 48 | /api/invoice/unpaid | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 49 | /api/payment | GET | 200 | ✅ PASS | List retrieved |
| 50 | /api/payment/1 | GET | 200 | ✅ PASS | Payment retrieved |
| 51 | /api/payment | POST | 201 | ✅ PASS | Created ID: 404 |
| 52 | /api/payment/{id} | PUT | 200 | ✅ PASS | Updated ID: 404 |
| 53 | /api/payment/{id} | DELETE | 403 | ❌ FAIL | Forbidden (Admin role restriction) |
| 54 | /api/payment/invoice/1 | GET | 200 | ✅ PASS | 2 payments |
| 55 | /api/payment/member/1 | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 56 | /api/report/revenue | GET | 200 | ✅ PASS | Revenue data OK |
| 57 | /api/report/members | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 58 | /api/report/trainers | GET | 404 | ❌ FAIL | Endpoint not implemented |
| 59 | /api/report/facilities | GET | 404 | ❌ FAIL | Endpoint not implemented |

---

# API TEST RESULTS - DETAILED REPORT (Previous Tests)

**Test Date:** 2026-10-10 09:40:55  
**Server:** http://localhost:5250  
**Credentials Used:** Username=gymadmin, Password=Gym@2026  
**Total Endpoints:** 59  
**Passed:** 40  
**Failed:** 19  
**Pass Rate:** 67.8%

---

## 1. AUTH API (1/1 = 100%)

### POST /api/auth/login
**Status:** ✅ PASS - 200  
**Request:**
```json
{"username":"gymadmin","password":"Gym@2026"}
```
**Response (truncated):**
```json
{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

---

## 2. MEMBER API (3/5 = 60%)

### GET /api/member?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"memberId":0,"fullName":"Member 1","email":"member1@example.com","phone":"0900000001",...}]}
```

### GET /api/member/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"memberId":0,"fullName":"Member 1","email":"member1@example.com","phone":"0900000001",...}
```

### POST /api/member
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"fullName":"Retest Member","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"123 Retest St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}
```
**Error:** Internal Server Error

### PUT /api/member/0
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"fullName":"Retest Member Updated","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"456 Updated St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}
```
**Error:** Internal Server Error

### DELETE /api/member/0
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

---

## 3. TRAINER API (3/5 = 60%)

### GET /api/trainer?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"trainerId":0,"fullName":"Nguyễn Van Trainer 1","phone":"0901234567","email":"trainer1@gym.com",...}]}
```

### GET /api/trainer/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"trainerId":0,"fullName":"Nguyễn Van Trainer 1","phone":"0901234567","email":"trainer1@gym.com",...}
```

### POST /api/trainer
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"fullName":"Retest Trainer","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Cardio","experience":3,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}
```
**Error:** Internal Server Error

### PUT /api/trainer/0
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"fullName":"Retest Trainer Updated","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Strength Training","experience":4,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}
```
**Error:** Internal Server Error

### DELETE /api/trainer/0
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

---

## 4. FACILITY API (5/5 = 100%)

### GET /api/facility?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"facilityId":0,"name":"Phòng tập Yoga 1","description":"Phòng tập Yoga với đầy đủ trang thiết bị",...}]}
```

### GET /api/facility/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"facilityId":0,"name":"Phòng tập Yoga 1","description":"Phòng tập Yoga với đầy đủ trang thiết bị",...}
```

### POST /api/facility
**Status:** ✅ PASS - 200  
**Request:**
```json
{"name":"Retest Room","type":"Gym","capacity":30,"description":"Retest facility","status":"Available"}
```
**Response (truncated):**
```json
{"facilityId":13,"name":"Retest Room","description":"Retest facility","status":"Available",...}
```

### PUT /api/facility/13
**Status:** ✅ PASS - 200  
**Request:**
```json
{"name":"Retest Room Updated","type":"Yoga","capacity":20,"description":"Updated retest facility","status":"Available"}
```
**Response (truncated):**
```json
{"facilityId":13,"name":"Retest Room Updated","description":"Updated retest facility","status":"Available",...}
```

### DELETE /api/facility/13
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

---

## 5. SCHEDULE API (6/7 = 85.7%)

### GET /api/schedule?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"scheduleId":100,"trainerId":0,"className":"Test Class Fixed","startTime":"2025-07-15T09:00:00",...}]}
```

### GET /api/schedule/98
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"scheduleId":98,"trainerId":4,"className":"Class 99","startTime":"2026-10-19T06:39:30.18",...}
```

### POST /api/schedule
**Status:** ✅ PASS - 200  
**Request:**
```json
{"trainerId":0,"facilityId":0,"className":"Retest Class","dayOfWeek":1,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":20,"status":"Active"}
```
**Response (truncated):**
```json
{"scheduleId":103,"trainerId":0,"className":"Retest Class","startTime":"2025-07-15T09:00:00",...}
```

### PUT /api/schedule/103
**Status:** ✅ PASS - 200  
**Request:**
```json
{"trainerId":0,"facilityId":0,"className":"Retest Class Updated","dayOfWeek":2,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":25,"status":"Active"}
```
**Response (truncated):**
```json
{"scheduleId":103,"trainerId":0,"className":"Retest Class Updated",...}
```

### DELETE /api/schedule/103
**Status:** ✅ PASS - 200  
**Note:** Schedule deletion was successful (returns 200, not 403 like other DELETEs)

### GET /api/schedule/trainer/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"scheduleId":100,"trainerId":0,"className":"Test Class Fixed",...}
```

### GET /api/schedule/date/2025-07-15
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## 6. SESSION API (3/5 = 60%)

### GET /api/session?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"sessionId":0,"memberId":1,"scheduleId":1,"registrationDate":"2026-10-08T21:39:30.18",...}]}
```

### GET /api/session/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"sessionId":0,"memberId":1,"scheduleId":1,"registrationDate":"2026-10-08T21:39:30.18",...}
```

### POST /api/session
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"scheduleId":98,"sessionDate":"2025-07-20T09:00:00","startTime":"2025-07-20T09:00:00","endTime":"2025-07-20T10:00:00","status":"Scheduled","notes":"Retest session"}
```
**Error:** Internal Server Error

### GET /api/session/schedule/98
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
[{"sessionId":197,"memberId":198,"scheduleId":98,"registrationDate":"2026-09-21T21:39:30.22",...}]
```

### GET /api/session/member/0
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## 7. MEMBERSHIP API (5/7 = 71.4%)

### GET /api/membership?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"membershipId":502,"memberId":0,"price":500000.00,"startDate":"2025-07-01T00:00:00",...}]}
```

### GET /api/membership/498
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"membershipId":498,"memberId":499,"packageName":"Gói 12 tháng","price":4800000.00,...}
```

### POST /api/membership
**Status:** ✅ PASS - 200  
**Request:**
```json
{"memberId":0,"planName":"Monthly Basic","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}
```
**Response (truncated):**
```json
{"membershipId":503,"memberId":0,"price":500000,"startDate":"2025-07-01T00:00:00",...}
```

### PUT /api/membership/503
**Status:** ✅ PASS - 200  
**Request:**
```json
{"memberId":0,"planName":"Monthly Basic Updated","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}
```
**Response (truncated):**
```json
{"membershipId":503,"memberId":0,"price":500000,"startDate":"2025-07-01T00:00:00",...}
```

### DELETE /api/membership/503
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

### GET /api/membership/active
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

### GET /api/membership/expiring
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## 8. CHECKIN API (2/6 = 33.3%)

### GET /api/checkin?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"checkinId":199,"memberId":200,"checkinTime":"2026-10-01T13:39:30.287",...}]}
```

### GET /api/checkin/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"checkinId":0,"memberId":1,"checkinTime":"2026-10-09T20:39:30.24",...}
```

### POST /api/checkin
**Status:** ❌ FAIL - 405  
**Request:**
```json
{"memberId":0,"facilityId":0,"checkinTime":"2025-07-15T09:00:00","checkoutTime":"2025-07-15T10:00:00","notes":"Retest checkin"}
```
**Error:** Method Not Allowed - endpoint disabled or wrong HTTP verb

### GET /api/checkin/member/0
**Status:** ❌ FAIL - 0  
**Error:** Null reference exception (endpoint likely not implemented correctly)

### GET /api/checkin/date/2025-07-15
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

### POST /api/checkin/qr
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"memberId":0,"facilityId":0}
```
**Error:** Internal Server Error

---

## 9. INVOICE API (5/7 = 71.4%)

### GET /api/invoice?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"invoiceId":0,"membershipId":1,"totalAmount":500000.00,"invoiceDate":"2026-10-09T00:00:00",...}]}
```

### GET /api/invoice/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"invoiceId":0,"membershipId":1,"totalAmount":500000.00,"status":"Paid",...}
```

### POST /api/invoice
**Status:** ✅ PASS - 200  
**Request:**
```json
{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Retest invoice"}
```
**Response (truncated):**
```json
{"invoiceId":507,"membershipId":498,"totalAmount":0,"status":"Pending","description":"Retest invoice",...}
```

### PUT /api/invoice/507
**Status:** ❌ FAIL - 500  
**Request:**
```json
{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Updated retest invoice"}
```
**Error:** Internal Server Error

### DELETE /api/invoice/507
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

### GET /api/invoice/member/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
[{"invoiceId":500,"membershipId":500,"totalAmount":500000.00,"status":"Pending",...}]
```

### GET /api/invoice/unpaid
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## 10. PAYMENT API (6/7 = 85.7%)

### GET /api/payment?pageNumber=1&pageSize=10
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"data":[{"paymentId":0,"invoiceId":1,"amount":250000.00,"paymentDate":"2026-10-08T21:39:30.42",...}]}
```

### GET /api/payment/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
{"paymentId":0,"invoiceId":1,"amount":250000.00,"paymentMethod":"Card",...}
```

### POST /api/payment
**Status:** ✅ PASS - 200  
**Request:**
```json
{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Retest payment"}
```
**Response (truncated):**
```json
{"paymentId":403,"invoiceId":0,"amount":500000,"paymentMethod":"Cash",...}
```

### PUT /api/payment/403
**Status:** ✅ PASS - 200  
**Request:**
```json
{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Updated retest payment"}
```
**Response (truncated):**
```json
{"paymentId":403,"invoiceId":0,"amount":500000.00,"paymentMethod":"Cash",...}
```

### DELETE /api/payment/403
**Status:** ✅ PASS (403 Expected) - 403  
**Note:** SuperAdmin-only endpoint, 403 is expected behavior

### GET /api/payment/invoice/0
**Status:** ✅ PASS - 200  
**Response (truncated):**
```json
[{"paymentId":400,"invoiceId":0,"amount":500000.00,"paymentMethod":"Cash",...}]
```

### GET /api/payment/member/0
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## 11. REPORT API (1/4 = 25%)

### GET /api/report/revenue?startDate=2025-01-01&endDate=2025-12-31
**Status:** ✅ PASS - 200  
**Response:**
```json
{"TotalRevenue":0.00,"InvoiceCount":0}
```

### GET /api/report/members
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

### GET /api/report/trainers
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

### GET /api/report/facilities
**Status:** ❌ FAIL - 404  
**Error:** Not Found - endpoint not implemented

---

## SUMMARY TABLE

| Module | Passed | Total | Pass Rate | Notes |
|--------|--------|-------|-----------|-------|
| Auth | 1 | 1 | 100% | ✅ All working |
| Member | 3 | 5 | 60% | POST & PUT failing with 500 |
| Trainer | 3 | 5 | 60% | POST & PUT failing with 500 |
| Facility | 5 | 5 | 100% | ✅ All working |
| Schedule | 6 | 7 | 85.7% | GET by date not implemented |
| Session | 3 | 5 | 60% | POST failing, GET by member not implemented |
| Membership | 5 | 7 | 71.4% | Active & expiring endpoints not implemented |
| Checkin | 2 | 6 | 33.3% | Most endpoints failing/not implemented |
| Invoice | 5 | 7 | 71.4% | PUT failing, unpaid endpoint not implemented |
| Payment | 6 | 7 | 85.7% | GET by member not implemented |
| Report | 1 | 4 | 25% | Only revenue working, others not implemented |
| **TOTAL** | **40** | **59** | **67.8%** | |

---

## CRITICAL ISSUES

1. **POST/PUT failures (500 errors):**
   - Member POST & PUT
   - Trainer POST & PUT
   - Session POST
   - Invoice PUT
   - Checkin QR

2. **Not Implemented (404 errors):**
   - Schedule: GET by date
   - Session: GET by member
   - Membership: GET active, GET expiring
   - Checkin: GET by member, GET by date
   - Invoice: GET unpaid
   - Payment: GET by member
   - Report: GET members, GET trainers, GET facilities

3. **Method Not Allowed (405):**
   - Checkin POST

4. **Null Reference Exception:**
   - Checkin: GET by member

