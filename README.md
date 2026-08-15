# 도희의 추가근로 캘린더

한국 공휴일 기준으로 주말·휴일 근무와 평일 야근 시간을 기록하고 월별로 집계하는 캘린더입니다.
GitHub Pages에 정적 파일로 올라가고, 기록은 Supabase에 저장되며, 등록된 구글 계정 하나만 접속할 수 있습니다.

```
index.html    앱 전체 (마크업 + 스타일 + 로직)
config.js     Supabase 접속 정보 ← 직접 채워야 함
schema.sql    Supabase 테이블 + RLS 정책 ← 한 번 실행
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

날짜를 누르면 오른쪽 입력칸이 그날 성격에 맞게 바뀝니다.

| | 입력하는 값 |
|---|---|
| 주말·휴일 | `근무 시간` + `그중 야근 시간` |
| 평일 | `야근 시간`만 (정규근무는 추가근로가 아니라 근무 시간 칸이 잠깁니다) |

상단 카드는 이번 달 기준으로 주말·휴일 근무 시간과 일수, 평일 야근 시간과 일수,
그리고 휴일에 근무하면서 야근까지 한 시간을 각각 보여줍니다.

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
python -m http.server 5173
```

그리고 `http://localhost:5173`을 Supabase의 `Redirect URLs`와 구글 OAuth 설정에 추가하면
로컬에서도 로그인이 됩니다. 배포만 할 거라면 필요 없습니다.
