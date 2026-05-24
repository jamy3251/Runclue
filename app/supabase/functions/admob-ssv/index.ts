// ============================================================================
// admob-ssv · Google AdMob Server-Side Verification (Phase 2 보안 강화)
// ============================================================================
// AdMob 콘솔에서 보상형 비디오의 SSV callback URL을 이 Edge Function으로 설정.
//   설정 위치: AdMob → 앱 → 광고 단위 → 보상 설정 → 서버측 인증 → 콜백 URL
//   값: https://<project>.functions.supabase.co/admob-ssv
//
// Google이 광고 시청 완료 시 GET 요청을 보냄. 쿼리 파라미터:
//   - ad_network        : 광고 네트워크 ID
//   - ad_unit           : 광고 단위 ID
//   - custom_data       : 클라이언트가 전달한 데이터 (= user_id)
//   - key_id            : 검증 공개키 ID
//   - reward_amount     : 보상 수량 (AdMob 설정값)
//   - reward_item       : 보상 종류 라벨
//   - signature         : ECDSA 서명 (base64url)
//   - timestamp         : 광고 본 시각 (ms)
//   - transaction_id    : 멱등성 키
//   - user_id           : (선택) 표준 user_id, 우리는 custom_data 사용
//
// 검증 절차 (Google 표준):
//   1. https://gstatic.com/admob/reward/verifier-keys.json에서 공개키 가져옴
//   2. key_id 일치하는 키 찾음
//   3. 쿼리 문자열에서 signature/key_id 제거한 부분이 서명 대상
//   4. ECDSA-SHA256 + secp256r1로 검증
//   5. 통과 시 grant_coin (멱등 토큰 = transaction_id)
//
// 보안 핵심:
//   - SUPABASE_SERVICE_ROLE_KEY로 ad_views 직접 INSERT (RPC 우회 가능)
//   - transaction_id를 view_token으로 사용 (UNIQUE 멱등성)
//   - 서명 검증 실패 시 401, 멱등 충돌 시 200 ok (Google 재시도 안전)
// ============================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const VERIFIER_KEYS_URL =
  "https://gstatic.com/admob/reward/verifier-keys.json";

interface VerifierKey {
  keyId: number;
  pem: string;
  base64: string;
}

interface VerifierKeysResponse {
  keys: VerifierKey[];
}

// 24시간 캐시 (메모리 — 인스턴스 단위)
let _keysCache: VerifierKey[] | null = null;
let _keysCacheAt = 0;
const KEYS_TTL_MS = 24 * 60 * 60 * 1000;

async function getVerifierKeys(): Promise<VerifierKey[]> {
  const now = Date.now();
  if (_keysCache && now - _keysCacheAt < KEYS_TTL_MS) return _keysCache;
  const res = await fetch(VERIFIER_KEYS_URL);
  if (!res.ok) throw new Error(`verifier-keys fetch failed: ${res.status}`);
  const json = (await res.json()) as VerifierKeysResponse;
  _keysCache = json.keys;
  _keysCacheAt = now;
  return json.keys;
}

// base64url → Uint8Array
function b64uToBytes(s: string): Uint8Array {
  const pad = s.length % 4 === 0 ? "" : "=".repeat(4 - (s.length % 4));
  const normalized = s.replace(/-/g, "+").replace(/_/g, "/") + pad;
  const bin = atob(normalized);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

// PEM → CryptoKey (ECDSA P-256)
async function importEcdsaPublicKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PUBLIC KEY-----/g, "")
    .replace(/-----END PUBLIC KEY-----/g, "")
    .replace(/\s+/g, "");
  const der = b64uToBytes(body.replace(/=/g, "")); // base64 (not base64url) but our helper tolerates both with padding
  return await crypto.subtle.importKey(
    "spki",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
}

// Google SSV signature는 ASN.1 DER 형식 → WebCrypto는 raw r||s 64바이트 요구
// DER {SEQ {INT r} {INT s}} → r(32) || s(32)
function derToRawSignature(der: Uint8Array): Uint8Array {
  if (der[0] !== 0x30) throw new Error("invalid_der");
  let off = 2;
  if (der[1] & 0x80) off = 2 + (der[1] & 0x7f);

  // INT r
  if (der[off] !== 0x02) throw new Error("invalid_der_r");
  let rLen = der[off + 1];
  let rStart = off + 2;
  // strip leading 0x00 (sign byte)
  while (rLen > 32 && der[rStart] === 0x00) {
    rStart++;
    rLen--;
  }
  const r = new Uint8Array(32);
  r.set(der.slice(rStart, rStart + rLen), 32 - rLen);
  off = rStart + rLen;

  // INT s
  if (der[off] !== 0x02) throw new Error("invalid_der_s");
  let sLen = der[off + 1];
  let sStart = off + 2;
  while (sLen > 32 && der[sStart] === 0x00) {
    sStart++;
    sLen--;
  }
  const s = new Uint8Array(32);
  s.set(der.slice(sStart, sStart + sLen), 32 - sLen);

  const raw = new Uint8Array(64);
  raw.set(r, 0);
  raw.set(s, 32);
  return raw;
}

async function verifySignature(
  url: URL,
  signature: string,
  keyId: number,
): Promise<boolean> {
  const keys = await getVerifierKeys();
  const key = keys.find((k) => k.keyId === keyId);
  if (!key) return false;

  // Signed content = full query string with signature/key_id removed
  // Google docs: "Signed content is everything up to (but not including) &signature="
  const fullQuery = url.search.startsWith("?")
    ? url.search.slice(1)
    : url.search;
  const sigIdx = fullQuery.indexOf("&signature=");
  if (sigIdx < 0) return false;
  const signedContent = fullQuery.slice(0, sigIdx);

  const pubKey = await importEcdsaPublicKey(key.pem);
  const derSig = b64uToBytes(signature);
  let rawSig: Uint8Array;
  try {
    rawSig = derToRawSignature(derSig);
  } catch {
    return false;
  }
  const data = new TextEncoder().encode(signedContent);
  return await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    pubKey,
    rawSig,
    data,
  );
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  // Google SSV는 GET only
  if (req.method !== "GET") return jsonResponse({ ok: false }, 405);
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse({ ok: false, reason: "server_misconfigured" }, 500);
  }

  const url = new URL(req.url);
  const q = url.searchParams;
  const signature = q.get("signature");
  const keyIdStr = q.get("key_id");
  const transactionId = q.get("transaction_id");
  const userId = q.get("custom_data") ?? q.get("user_id");
  const adUnit = q.get("ad_unit");
  const rewardAmount = Number(q.get("reward_amount") ?? "20");

  if (!signature || !keyIdStr || !transactionId || !userId || !adUnit) {
    return jsonResponse({ ok: false, reason: "missing_fields" }, 400);
  }

  const keyId = Number(keyIdStr);
  let verified = false;
  try {
    verified = await verifySignature(url, signature, keyId);
  } catch (e) {
    console.error("ssv verify error:", e);
    return jsonResponse({ ok: false, reason: "verify_error" }, 401);
  }
  if (!verified) {
    return jsonResponse({ ok: false, reason: "invalid_signature" }, 401);
  }

  // 검증 통과 — service_role로 ad_views 멱등 INSERT + grant_coin
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 일일 캡 (5회)은 RPC와 일관 — 직접 카운트
  const today = new Date(
    Date.now() + 9 * 60 * 60 * 1000, // KST shift
  ).toISOString().slice(0, 10);
  const { count } = await sb
    .from("ad_views")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("day_date", today);
  if ((count ?? 0) >= 5) {
    // 캡 초과 — Google에는 200으로 답 (재시도 차단)
    return jsonResponse({ ok: true, capped: true });
  }

  // 멱등 INSERT (UNIQUE user_id+view_token 위반 시 swallow)
  const { error: insertErr } = await sb.from("ad_views").insert({
    user_id: userId,
    ad_unit_id: adUnit,
    view_token: transactionId,
    reward_coin: rewardAmount,
  });
  if (insertErr) {
    if (insertErr.code === "23505") {
      // UNIQUE 충돌 — 이미 처리됨, 200 OK
      return jsonResponse({ ok: true, idempotent: true });
    }
    console.error("ad_views insert error:", insertErr);
    return jsonResponse({ ok: false, reason: "insert_failed" }, 500);
  }

  // grant_coin 호출 (service_role이므로 일일 캡 검증은 RPC 내부에서 처리)
  const { data: grantRes, error: grantErr } = await sb.rpc("grant_coin_admin", {
    user_id_in: userId,
    delta_in: rewardAmount,
    reason_in: "ad_ssv",
    source_id_in: transactionId,
  });

  if (grantErr) {
    console.error("grant_coin_admin error:", grantErr);
    return jsonResponse({ ok: false, reason: "grant_failed" }, 500);
  }

  return jsonResponse({ ok: true, grant: grantRes });
});
