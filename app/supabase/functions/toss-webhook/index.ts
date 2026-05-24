// ============================================================================
// toss-webhook · 토스페이먼츠 결제 상태 변경 webhook (Phase 2)
// ============================================================================
// 토스 콘솔에서 webhook URL 설정:
//   https://<project>.functions.supabase.co/toss-webhook
//
// 토스가 결제 상태 변경 (취소/환불/실패) 시 POST 보냄.
// 페이로드 (JSON):
//   {
//     "eventType": "PAYMENT_STATUS_CHANGED",
//     "data": {
//       "paymentKey": "...",
//       "orderId": "...",
//       "status": "CANCELED" | "PARTIAL_CANCELED" | "ABORTED" | ...,
//       "totalAmount": 1000,
//       "canceledAmount": 1000,
//       ...
//     }
//   }
//
// 보안: 토스 secret으로 HMAC-SHA256 서명 검증 (`tosspayments-webhook-signature` 헤더).
// 단 토스 공식 webhook은 IP allowlist 위주이고 서명 헤더는 옵셔널.
// MVP는 멱등성 (paymentKey UNIQUE) 기준으로 안전 처리.
//
// 동작:
//   - status='CANCELED' → wallet_topups.status='cancelled'
//     + 사장 clues.reward_pool_net -= net_amount (음수 방지 가드)
//     + 기존 reward_pool_committed 이상으로 빼지 않음 (이미 지급된 보상 보호)
//   - status='PARTIAL_CANCELED' → 부분 취소 (MVP는 무시, admin 수동)
//   - 기타 → 로깅만
//
// Deploy:
//   1. supabase functions deploy toss-webhook
//   2. supabase secrets set TOSS_SECRET_KEY=<key>
//   3. 토스 콘솔 → webhook URL 등록
// ============================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TOSS_SECRET_KEY = Deno.env.get("TOSS_SECRET_KEY") ?? "";

interface TossWebhookData {
  paymentKey?: string;
  orderId?: string;
  status?: string;
  totalAmount?: number;
  canceledAmount?: number;
}

interface TossWebhookPayload {
  eventType?: string;
  data?: TossWebhookData;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * HMAC-SHA256 서명 검증 (옵셔널 — 토스가 서명 헤더 제공할 때만).
 * 토스 표준 헤더: `tosspayments-webhook-signature: t=<unix>,v1=<base64-hmac>`
 */
async function verifyTossSignature(
  rawBody: string,
  signatureHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader || !secret) return false;
  const parts = Object.fromEntries(
    signatureHeader.split(",").map((kv) => {
      const [k, v] = kv.trim().split("=");
      return [k, v];
    }),
  ) as Record<string, string>;
  const ts = parts["t"];
  const sig = parts["v1"];
  if (!ts || !sig) return false;

  // Replay window: 5분
  const now = Math.floor(Date.now() / 1000);
  const tsNum = Number(ts);
  if (Math.abs(now - tsNum) > 300) return false;

  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const data = enc.encode(`${ts}.${rawBody}`);
  const sigBuf = await crypto.subtle.sign("HMAC", key, data);
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sigBuf)));
  // constant-time compare
  if (sigB64.length !== sig.length) return false;
  let diff = 0;
  for (let i = 0; i < sigB64.length; i++) {
    diff |= sigB64.charCodeAt(i) ^ sig.charCodeAt(i);
  }
  return diff === 0;
}

serve(async (req: Request) => {
  if (req.method !== "POST") return jsonResponse({ ok: false }, 405);
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse({ ok: false, reason: "server_misconfigured" }, 500);
  }

  const rawBody = await req.text();

  // 서명 검증 (선택적 — 토스가 헤더 제공 안 하면 skip 가능하나 운영에선 필수 권장)
  if (TOSS_SECRET_KEY) {
    const sigHeader = req.headers.get("tosspayments-webhook-signature");
    if (sigHeader) {
      const ok = await verifyTossSignature(rawBody, sigHeader, TOSS_SECRET_KEY);
      if (!ok) {
        return jsonResponse({ ok: false, reason: "invalid_signature" }, 401);
      }
    }
    // 서명 헤더 없을 시: IP allowlist 또는 다른 방어를 토스 콘솔에서 설정
  }

  let payload: TossWebhookPayload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ ok: false, reason: "invalid_json" }, 400);
  }

  const data = payload.data;
  if (!data?.paymentKey) {
    return jsonResponse({ ok: false, reason: "missing_payment_key" }, 400);
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 멱등성 — paymentKey로 row 조회
  const { data: topup, error: lookupErr } = await sb
    .from("wallet_topups")
    .select("id, clue_id, net_amount, status, user_id")
    .eq("toss_payment_key", data.paymentKey)
    .maybeSingle();

  if (lookupErr) {
    console.error("topup lookup:", lookupErr);
    return jsonResponse({ ok: false, reason: "db_error" }, 500);
  }
  if (!topup) {
    // 알 수 없는 paymentKey — 토스 재시도 차단을 위해 200 반환
    console.warn("unknown paymentKey:", data.paymentKey);
    return jsonResponse({ ok: true, unknown: true });
  }

  const status = (data.status ?? "").toUpperCase();

  if (status === "CANCELED" || status === "ABORTED") {
    if (topup.status === "cancelled") {
      return jsonResponse({ ok: true, idempotent: true });
    }

    // wallet_topups.status='cancelled'
    await sb.from("wallet_topups").update({ status: "cancelled" }).eq("id", topup.id);

    // 풀 차감 — 이미 지급된 (committed) 이상으로 빼지 않음
    if (topup.clue_id && topup.net_amount > 0) {
      // 원자적 차감 (RPC 통하면 좋지만 단순 UPDATE로)
      const { data: clue } = await sb
        .from("clues")
        .select("reward_pool_net, reward_pool_committed")
        .eq("id", topup.clue_id)
        .single();
      if (clue) {
        const net = (clue.reward_pool_net ?? 0) as number;
        const committed = (clue.reward_pool_committed ?? 0) as number;
        const safeDeduct = Math.min(topup.net_amount, Math.max(0, net - committed));
        await sb
          .from("clues")
          .update({ reward_pool_net: net - safeDeduct })
          .eq("id", topup.clue_id);
        console.log(
          `[toss-webhook] cancel deducted ${safeDeduct} from clue ${topup.clue_id}`,
        );
      }
    }

    return jsonResponse({ ok: true, action: "cancelled" });
  }

  if (status === "PARTIAL_CANCELED") {
    // MVP는 부분 환불 자동 처리 X — admin이 수동 처리
    console.warn("PARTIAL_CANCELED needs manual handling:", data.paymentKey);
    return jsonResponse({ ok: true, action: "manual_required" });
  }

  // 기타 이벤트 — 로깅만
  console.log("toss webhook event:", payload.eventType, status);
  return jsonResponse({ ok: true, action: "logged" });
});
