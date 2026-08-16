# 작업 안내

도희의 추가근로 캘린더. 이 문서는 **코드를 이어받는 사람(또는 에이전트)** 을 위한 것입니다.
사용법과 설치 절차는 [README.md](README.md)에 있습니다.

## 한눈에

- 빌드 도구 없는 **정적 페이지 한 장**. `index.html` 하나에 마크업·CSS·JS가 다 들어 있습니다.
  번들러도 패키지 매니저도 없습니다. 파일 고치고 push 하면 그게 배포입니다.
- 외부 의존은 두 개뿐이고 둘 다 CDN 직접 import 입니다.
  - `@supabase/supabase-js@2` (jsdelivr, ESM)
  - `date.nager.at` 공휴일 API (키 불필요, CORS 열림)
- 데이터는 Supabase Postgres. 로컬 저장은 쓰지 않습니다 —
  단, 공휴일 목록만 `localStorage`에 연도별 캐시합니다(공개 자료라 유실돼도 무해).

## 데이터 모델

`dohee_work_log`, 하루에 한 행. **기준에서 벗어나는 값만 저장합니다.**
평일 8시간 정규근무는 어디에도 저장되지 않고 계산할 때 만들어집니다.

| 컬럼 | 뜻 |
|---|---|
| `day` | PK, `YYYY-MM-DD` |
| `work_hours` | 주말·휴일에 일한 시간. 평일이면 항상 0 |
| `ot_hours` | 평일 야근 시간. 주말·휴일이면 항상 0 |
| `leave_hours` | 평일 휴가. `0 / 2(반반차) / 4(반차) / 8(연차)` 만 허용 |
| `day_override` | `'hol'` = 평일을 휴일로, `'wd'` = 공휴일을 평일로. 그 외엔 null |

화면의 시간 입력칸은 **하나뿐**이고, 그날이 쉬는 날이면 `work_hours`로,
평일이면 `ot_hours`로 들어갑니다. 저장할 때 **반대쪽은 0으로 지웁니다** —
나중에 휴일↔평일을 뒤집었을 때 옛 값이 되살아나 합계를 흔들지 않게 하려는 것입니다.
같은 이유로 달력 태그와 목록도 그날 성격에 안 맞는 값은 아예 그리지 않습니다.

### 하루의 성격을 정하는 순서

`isRest(day)` 하나로 판정하며 우선순위가 있습니다.

1. `day_override`가 있으면 그것이 최종 (사람이 고친 값이 제일 세다)
2. 없으면 공휴일 API 결과
3. 그것도 없으면 요일 (토·일)

공휴일 이름도 같은 규칙(`holidayName`)이고, API 이름이 `'지정 휴일'`보다 우선합니다.

> **API 자료가 틀릴 수 있습니다.** 예를 들어 nager.at은 7월 17일 제헌절을 공휴일로 주는데
> 한국에서 제헌절은 2008년부터 공휴일이 아닙니다. `day_override`가 존재하는 이유가 이것입니다.
> 그래서 override는 **양방향**입니다 — 공휴일을 평일로 되돌리는 것도 됩니다.

### 집계

`summarize()` 하나에 모여 있습니다. 카드 네 개가 전부 여기서 나옵니다.

```
평일 실근무 = 8h × (그 달 평일 수) − 휴가 합계
총 근로시간 = 평일 실근무 + 휴일 근무 + 평일 야근
총 추가근로 = 휴일 근무 + 평일 야근
```

**평일 수를 세는 범위에 의도적인 규칙이 있습니다** (`baseCountLimit`).
이번 달이면 오늘까지만, 지난 달이면 월 전체, 다음 달이면 0입니다.
달 전체를 세면 8월 3일에 접속했을 때 176시간이 찍혀 명백히 틀린 숫자로 보이기 때문입니다.
바꾸려면 이 함수 하나만 고치면 됩니다.

## 접근 제한

**RLS가 유일한 방어선입니다.** `config.js`의 publishable key는 공개돼도 되는 값이고,
화면을 가리는 것으로는 아무것도 막지 못합니다.

- `dohee_is_allowed()` — `security definer` 함수. `auth.jwt() ->> 'email'`이
  `dohee_allowed_emails`에 있는지 본다. 이 테이블에는 클라이언트 정책을 하나도 주지 않아
  브라우저에서 직접 조회할 수 없습니다.
- `dohee_work_log`의 모든 정책이 이 함수를 탑니다.
- 로그인 화면에서 미등록 계정을 즉시 로그아웃시키는 코드가 있는데,
  이건 **이유를 알려주기 위한 UX**이지 보안 장치가 아닙니다. 지워도 데이터는 안전합니다.

## 로그인 없이 화면 확인하기

Supabase 자격증명 없이 UI와 계산 로직을 돌려보는 방법입니다. **검증할 때 이걸 쓰세요.**
`index.html`의 import 두 줄을 메모리 스텁으로 바꾼 사본을 만듭니다.

```bash
python - <<'PY'
import io
src = io.open('index.html', encoding='utf-8').read()
old = '''import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";'''
stub = '''const SUPABASE_URL="stub", SUPABASE_ANON_KEY="stub";
const _db = {};   // 필요하면 여기에 {day:..., work_hours:...} 행을 미리 넣는다
const createClient = () => ({
  from: () => ({
    select: async () => ({ data: Object.values(_db), error: null }),
    upsert: async (row) => { _db[row.day] = row; return { error: null }; },
    delete: () => ({ eq: async (_c, v) => { delete _db[v]; return { error: null }; } })
  }),
  rpc: async () => ({ data: true, error: null }),
  auth: {
    getSession: async () => ({ data: { session: { user: { id:"t", email:"test@example.com" } } } }),
    onAuthStateChange: () => {}, signOut: async () => {}, signInWithOAuth: async () => ({ error: null })
  }
});'''
assert old in src, "import block changed — stub 갱신 필요"
io.open('_test.html','w',encoding='utf-8').write(src.replace(old, stub))
PY

python -m http.server 5173 --directory .
# http://localhost:5173/_test.html 로 접속하면 로그인 없이 바로 캘린더가 뜬다
```

**`_test.html`은 커밋하지 마세요.** 확인 끝나면 지웁니다.

달력 태그가 잘리는지 같은 건 눈으로 보지 말고 재는 편이 확실합니다.

```js
[...document.querySelectorAll('.day .tag')].filter(t => t.scrollWidth > t.clientWidth + 1)
```

## 반응형

두 개의 분기점이 있고 목적이 다릅니다.

- **900px** — 2열에서 1열로. `grid-template-areas`로 순서를 `cal → side → list`로 바꿉니다.
  모바일에서 근무 내역이 길어져도 날짜를 고른 뒤 한참 스크롤하지 않게 하려는 것입니다.
- **640px** — 달력 한 칸이 50px 남짓이 되는 지점. 태그의 `.tl`(라벨)만 숨겨
  `근무 8h`를 `8h`로 만듭니다. 색으로 구분되고 전체 문구는 `title`에 남습니다.

## 배포와 확인

`main`에 push하면 GitHub Pages가 1~2분 안에 반영합니다. 별도 빌드 단계는 없습니다.

**반영 확인은 배포본을 직접 받아서 하세요.** 브라우저 캐시(`max-age=600`)에 속기 쉽습니다.

```bash
curl -s https://ilopark.github.io/dohee-worktime/index.html | grep "방금-넣은-문구"
```

## DB를 바꿔야 할 때

컬럼을 추가하면 **코드보다 마이그레이션이 먼저** 나가야 합니다. 순서가 뒤집히면
사용자 화면에 `Could not find the 'xxx' column ... in the schema cache`가 뜹니다.

1. `migration-*.sql`을 새로 만든다 (기존 설치용, `add column if not exists`로 멱등하게)
2. `schema.sql`도 같이 고친다 (신규 설치용)
3. 사용자가 SQL Editor에서 마이그레이션을 돌린 것을 확인한 뒤 코드를 push

## 건드리면 안 되는 것

- **Supabase `Site URL`** — 도리로 가계부가 이 값에 의존합니다. 이 앱은 복귀 주소를
  `redirectTo`로 직접 넘기므로 `Redirect URLs`에 등록만 되어 있으면 됩니다.
- **`dohee_` 접두어** — 가계부와 한 프로젝트를 공유하므로 이름 충돌을 막는 장치입니다.
- **`.github/workflows/keep-alive.yml`의 월 1회 커밋 단계** — GitHub은 public 저장소에서
  60일간 활동이 없으면 스케줄 워크플로를 꺼버립니다. 워크플로가 도는 것 자체는
  활동으로 안 쳐줍니다. 이 커밋이 없으면 두 달 뒤 조용히 멈춥니다.
