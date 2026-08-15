// Supabase 프로젝트 설정 (doriro-accountbook 프로젝트에 얹음)
//
// anon key는 브라우저에 노출되는 게 정상입니다. 실제 접근 차단은
// schema.sql 의 RLS 정책이 담당하므로 이 값이 공개돼도 데이터는 안전합니다.

export const SUPABASE_URL = "https://dlolqjgiamonfilfntxk.supabase.co";

// Project Settings → API Keys → Publishable key
// (예전 대시보드의 anon public 키에 해당한다. Secret key 는 절대 여기 넣지 말 것)
export const SUPABASE_ANON_KEY = "sb_publishable_k9qS8EfKTJn2sWFI4F7Bcg_rJJac721";
