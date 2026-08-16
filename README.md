# 도희의 추가근로 캘린더

한국 공휴일 기준으로 주말·휴일 근무와 평일 야근 시간을 기록하고 월별로 집계하는 캘린더입니다.
GitHub Pages에 정적 파일로 올라가고, 기록은 Supabase에 저장되며, 등록된 구글 계정 하나만 접속할 수 있습니다.

```
index.html               앱 전체 (마크업 + 스타일 + 로직)
config.js                Supabase 접속 정보
schema.sql               테이블 + RLS 정책 ← 신규 설치 시 한 번 실행
migration-leave.sql      휴가 컬럼 추가 ← 기존 설치에서만 한 번 실행
.github/workflows/       Supabase 7일 자동정지 방지
CLAUDE.md                코드 구조와 작업 방식 (이어받을 때 먼저 읽을 것)
```

---

## 현재 운영 정보

여기 적힌 값은 전부 공개돼도 되는 것들입니다. 비밀은 저장소에 두지 않습니다.

| | |
|---|---|
| 서비스 주소 | https://ilopark.github.io/dohee-worktime/ |
| 배포 | `main` 에 push → GitHub Pages 자동 반영 (1~2분) |
| Supabase 프로젝트 | `doriro-accountbook` (ref `dlolqjgiamonfilfntxk`) |
| 테이블 | `dohee_work_log`, `dohee_allowed_emails` |
| 로그인 | 구글 OAuth. `dohee_allowed_emails` 에 등록된 계정만 통과 |

Supabase 프로젝트는 **도리로 가계부와 함께 씁니다.** 그래서 이름에 `dohee_` 접두어가 붙어 있고,
Auth 설정을 만질 때 주의가 필요합니다. 아래 [주의사항](#주의사항)을 보세요.

### 허용 계정 바꾸기

앱 코드를 고칠 필요 없이 SQL 한 줄이면 됩니다. Supabase → SQL Editor:

```sql
-- 추가
insert into public.dohee_allowed_emails (email) values ('someone@gmail.com')
on conflict (email) do nothing;

-- 제거
delete from public.dohee_allowed_emails where email = 'someone@gmail.com';
```

---

## 접근 제한이 동작하는 방식

`config.js`의 anon key는 브라우저에 그대로 노출됩니다. **이것은 정상이며**, 화면을 가리는 것으로는
아무것도 막을 수 없습니다. 실제 차단은 `schema.sql`의 RLS 정책이 합니다.

- `dohee_allowed_emails` 테이블에 등록된 이메일만 `dohee_work_log`를 읽고 쓸 수 있습니다.
- 다른 구글 계정으로 로그인 자체는 성공하더라도, 데이터는 한 행도 조회되지 않고 저장도 거부됩니다.
- 로그인 화면에서 즉시 로그아웃시키는 건 사용자에게 이유를 알려주기 위한 것이지 방어선이 아닙니다.

---

## 설정 순서

### 1. Supabase 프로젝트 만들기

[supabase.com](https://supabase.com)에서 새 프로젝트를 만듭니다. 무료 플랜으로 충분합니다.

### 2. 테이블과 정책 만들기

`schema.sql`을 열어 **맨 아래 `WIFE_EMAIL@gmail.com`을 실제 구글 계정으로 바꾼 뒤**,
파일 전체를 복사해 Supabase 대시보드의 **SQL Editor**에 붙여넣고 실행합니다.

> 나중에 허용 계정을 바꾸려면 SQL Editor에서 `dohee_allowed_emails` 테이블에 INSERT 하거나
> 기존 행을 DELETE 하면 됩니다. 앱 코드는 건드릴 필요가 없습니다.

#### 이미 쓰고 있는 Supabase 프로젝트에 얹는 경우

무료 플랜은 사용자당 활성 프로젝트 2개까지라 새로 못 만들 수 있습니다. 기존 프로젝트에 그대로 얹어도 됩니다.
테이블과 함수 이름에 모두 `dohee_` 접두어가 붙어 있어 충돌하지 않고, 정책도 `dohee_work_log` 에만 걸립니다.
다만 5단계에서 **`Site URL` 은 건드리지 말고 `Redirect URLs` 에 추가만** 하세요. Site URL 을 바꾸면
그 프로젝트를 쓰는 기존 앱의 로그인이 깨집니다. 이 앱은 `redirectTo` 를 직접 넘기므로 Redirect URLs 에만
등록돼 있으면 정상 동작합니다.

### 3. GitHub 저장소 만들고 배포하기

이 폴더는 이미 git 저장소로 초기화되어 있습니다. GitHub에서 빈 저장소를 하나 만든 뒤:

```bash
git remote add origin https://github.com/<사용자명>/dohee-worktime.git
git branch -M main
git push -u origin main
```

저장소 **Settings → Pages**에서 Source를 `Deploy from a branch`, 브랜치를 `main` / `(root)`로
설정하면 잠시 후 아래 주소로 열립니다.

```
https://<사용자명>.github.io/dohee-worktime/
```

이 주소를 다음 단계에서 씁니다.

### 4. 구글 OAuth 클라이언트 만들기

[Google Cloud Console](https://console.cloud.google.com) → **APIs & Services**

1. **OAuth consent screen**: User Type을 `External`로 만들고 앱 이름을 채웁니다.
   게시하지 않고 테스트 상태로 두려면 **Test users**에 와이프 계정을 추가하세요.
   (테스트 상태에서는 등록된 테스트 사용자만 로그인할 수 있어 제한이 한 겹 더 생깁니다.)
2. **Credentials → Create Credentials → OAuth client ID**
   - Application type: `Web application`
   - **Authorized redirect URIs**에 아래를 추가합니다. Pages 주소가 아니라 **Supabase 주소**입니다.
     ```
     https://<프로젝트-ref>.supabase.co/auth/v1/callback
     ```
3. 생성된 **Client ID**와 **Client Secret**을 복사합니다.

### 5. Supabase에 구글 로그인 연결하기

Supabase 대시보드에서:

- **Authentication → Providers → Google**: 활성화하고 위의 Client ID / Secret을 붙여넣습니다.
- **Authentication → URL Configuration**:
  - `Site URL`에 `https://<사용자명>.github.io/dohee-worktime/`
  - `Redirect URLs`에도 같은 주소를 추가합니다.

### 6. config.js 채우기

Supabase **Project Settings → API**에서 값을 복사해 `config.js`에 넣고 커밋·푸시합니다.

```js
export const SUPABASE_URL = "https://<프로젝트-ref>.supabase.co";
export const SUPABASE_ANON_KEY = "eyJ...";
```

```bash
git add config.js
git commit -m "Supabase 접속 정보 설정"
git push
```

---

## 사용법

날짜를 누르면 입력칸이 그날 성격에 맞게 바뀝니다. **시간 입력칸은 하나뿐**이고, 그날이 평일이냐
쉬는 날이냐에 따라 뜻이 바뀝니다. 어느 쪽이든 그대로 추가 근로시간이 됩니다.

| | 화면에 나오는 것 |
|---|---|
| 평일 | `기본 근무` 8시간 (고정, 입력 불가) + `휴가` 선택 + **`야근 시간`** |
| 주말·휴일 | **`휴일 근무 시간`** |

평일 8시간은 자동으로 잡히므로 따로 입력하지 않습니다. 휴가는 반반차 2h / 반차 4h / 연차 8h 중에
고르며, 고른 만큼 총 근로시간에서 빠집니다. 휴가는 평일에만 있습니다.

`+0.5` `+1` `+2` `+4` `+8` 버튼은 **누를 때마다 기존 값에 더해집니다.** 값을 비우려면 옆의 `지우기`를 누르세요.

상단 카드 네 개는 이번 달 기준입니다.

| 카드 | 뜻 |
|---|---|
| 주말·휴일 근무 | 쉬는 날에 일한 시간과 일수 |
| 평일 야근 | 평일에 정규시간 넘겨 일한 시간과 일수 |
| 총 근로시간 | 평일 실근무(8h × 평일수 − 휴가) + 휴일 근무 + 야근 |
| 이번 달 총 추가근로 | 주말·휴일 근무 + 평일 야근 |

> **총 근로시간의 평일 집계 범위** — 이번 달은 오늘까지만, 지난 달은 월 전체를 셉니다.
> 달 전체를 세면 월초에 아직 일하지도 않은 시간이 찍혀서 틀린 숫자로 보이기 때문입니다.

### 화면 크기에 따라 달라지는 것

| 폭 | 달라지는 점 |
|---|---|
| 900px 이하 | 한 줄 배치로 바뀌고 **달력 → 기록 입력 → 근무 내역** 순이 됩니다. 내역이 길어져도 날짜를 고른 뒤 한참 스크롤할 일이 없습니다. |
| 640px 이하 | 달력 한 칸이 50px 남짓이라 태그에서 라벨을 빼고 숫자만 남깁니다 (`근무 8h` → `8h`). 초록은 휴일근무, 주황은 야근, 보라는 휴가이고 전체 문구는 태그 툴팁에 남아 있습니다. |

### 공휴일이 틀렸을 때

공휴일은 [date.nager.at](https://date.nager.at) API에서 가져오며 대체공휴일도 반영됩니다.
다만 이 자료가 항상 맞지는 않습니다 — 예를 들어 **7월 17일 제헌절이 공휴일로 들어오는데,
한국에서 제헌절은 2008년부터 공휴일이 아닙니다.**

그런 날은 날짜를 선택한 뒤 체크박스로 직접 고칠 수 있습니다. 체크박스의 의미는 그날 성격에 따라 뒤집힙니다.

- 공휴일·주말로 잡힌 날 → `이 날은 휴일이 아님 (평일로 처리)`
- 평일 → `이 날을 휴일로 직접 지정` (회사 창립기념일, 임시공휴일 등)

이 지정값도 Supabase에 함께 저장되므로 기기를 바꿔도 유지됩니다.

---

## 로컬에서 실행하기

`file://`로 열면 ES 모듈과 OAuth 리다이렉트가 동작하지 않습니다. 로컬 확인은 HTTP 서버로 하세요.

```bash
python -m http.server 5173 --directory .
```

그리고 `http://localhost:5173`을 Supabase의 `Redirect URLs`와 구글 OAuth 설정에 추가하면
로컬에서도 로그인이 됩니다. 로그인 없이 화면만 확인하는 방법은 [CLAUDE.md](CLAUDE.md)에 있습니다.

---

## 문제 해결

### 고친 게 화면에 안 나올 때

GitHub Pages는 `Cache-Control: max-age=600`을 줍니다. 브라우저가 이전 파일을 최대 10분간 들고 있어서,
push 직후에는 옛 화면이 보일 수 있습니다. 특히 폰에서는 새로고침만으로 안 풀릴 때가 있습니다.

주소 뒤에 아무 쿼리나 붙이면 즉시 우회됩니다.

```
https://ilopark.github.io/dohee-worktime/?v=2
```

배포본에 실제로 반영됐는지는 이렇게 확인합니다.

```bash
curl -s https://ilopark.github.io/dohee-worktime/index.html | grep "찾을문구"
```

### `Could not find the 'xxx' column ... in the schema cache`

코드는 새 컬럼을 쓰는데 DB에 아직 없다는 뜻입니다. 안 돌린 마이그레이션이 있는지 확인하세요.
현재까지 필요한 것은 `migration-leave.sql` 하나입니다.

### 로그인 후 엉뚱한 주소로 튕길 때

Supabase는 앱이 넘긴 복귀 주소가 **Redirect URLs 목록에 없으면 무시하고 Site URL로 보냅니다.**
이 프로젝트는 가계부와 공유하므로 Site URL이 가계부 주소로 잡혀 있습니다.
`https://ilopark.github.io/dohee-worktime/`가 Redirect URLs에 들어 있는지 확인하세요.

### Supabase 프로젝트가 일시정지됐을 때

무료 플랜은 7일간 요청이 없으면 정지됩니다. `.github/workflows/keep-alive.yml`이 매일 찔러서
막고 있지만, 이미 정지됐다면 핑으로는 못 깨웁니다. 대시보드에서 **Restore**를 눌러야 하고
데이터는 그대로 보존됩니다.

---

## 주의사항

- **Secret key(`sb_secret_...`)를 `config.js`에 넣지 마세요.** RLS를 통째로 무시하는 키라
  공개 저장소에 올라가면 계정 제한이 무의미해집니다. 여기 들어갈 값은 Publishable key 뿐입니다.
- **Supabase의 `Site URL`을 바꾸지 마세요.** 도리로 가계부가 그 값에 의존합니다.
  이 앱은 복귀 주소를 직접 넘기므로 `Redirect URLs`에 등록만 되어 있으면 됩니다.
- **Auth는 프로젝트 단위로 공유됩니다.** 가계부 사용자도 이 앱에 로그인 시도는 할 수 있지만
  `dohee_allowed_emails`에 없으면 데이터는 한 행도 못 봅니다. 반대로 이 앱의 계정도
  가계부에 로그인은 됩니다 — 가계부 쪽 RLS가 느슨하다면 그쪽을 따로 점검하세요.
- **접속 토큰을 어디에도 붙여넣지 마세요.** 로그인 후 주소창에 붙는 `#access_token=...`에는
  refresh token이 함께 들어 있어 사실상 비밀번호에 준합니다.
