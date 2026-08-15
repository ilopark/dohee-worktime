// Supabase 프로젝트 설정 (doriro-accountbook 프로젝트에 얹음)
//
// anon key는 브라우저에 노출되는 게 정상입니다. 실제 접근 차단은
// schema.sql 의 RLS 정책이 담당하므로 이 값이 공개돼도 데이터는 안전합니다.

export const SUPABASE_URL = "https://dlolqjgiamonfilfntxk.supabase.co";

// ↓ Supabase 대시보드 → Project Settings → API 에서 anon public 키를 복사해 넣으세요.
//   (대시보드에 따라 API Keys → Publishable key 로 표시되기도 합니다)
export const SUPABASE_ANON_KEY = "여기에-anon-public-키-붙여넣기";
