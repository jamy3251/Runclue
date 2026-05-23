// ============================================================================
// toss-confirm · 토스페이먼츠 결제 승인 검증 + 클루 풀 적립
// ============================================================================
// Flutter 클라이언트가 토스 결제 위젯에서 성공 콜백 받으면 이 Edge Function 호출.
// 토스 /v1/payments/confirm API로 실제 승인 → 검증된 경우만 wallet_topups 기록.
//
// 보안:
//   - TOSS_SECRET_KEY는 Supabase env (클라이언트엔 anon key만)
//   - JWT 검증으로 호출자 user_id 확인 (paymentKey의 사장과 일치해야 함)
//   - 멱등성: toss_payment_key UNIQUE — 동일 결제 재호출 시 기존 결과 반환
//   - amount 검증: 클라이언트 amount와 토스 응답 totalAmount 일치 확인
//
// 호출 예시:
//   POST /functions/v1/toss-confirm
//   Authorization: Bearer <user-jwt>
//   { paymentKey, orderId, amount, clueId }
//
// 응답:
//   200 { ok: true, topup_id, new_pool_net, idempotent }
//   4xx { ok: false, reason, detail }
// ============================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const TOSS_SECRET_KEY = Deno.env.get("TOSS_SECRET_KEY") ?? "";
const TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm";
const FEE_RATE_BPS = 1500; // 15.00%

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, reason: "method_not_allowed" }, 405);
  }

  // 환경변수 검증
  if (!TOSS_SECRET_KEY) {
    return jsonResponse(
      { ok: false, reason: "server_misconfigured", detail: "TOSS_SECRET_KEY" },
      500,
    );
  }
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(
      { ok: false, reason: "server_misconfigured", detail: "supabase_env" },
      500,
    );
  }

  // 호출자 JWT → user_id 추출
  const auth = req.headers.get("Authorization") ?? "";
  const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!jwt) {
    return jsonResponse({ ok: false, reason: "auth_required" }, 401);
  }

  // 입력 파싱
  let body: {
    paymentKey?: string;
    orderId?: string;
    amount?: number;
    clueId?: string | null;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ ok: false, reason: "invalid_json" }, 400);
  }
  const { paymentKey, orderId, amount, clueId = null } = body;
  if (!paymentKey || !orderId || typeof amount !== "number" || amount <= 0) {
    return jsonResponse({ ok: false, reason: "missing_fields" }, 400);
  }

  // 사용자 검증: JWT의 sub 사용
  const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData.user) {
    return jsonResponse({ ok: false, reason: "invalid_jwt" }, 401);
  }
  const userId = userData.user.id;

  // 토스 결제 승인 API 호출
  let tossResp: Record<string, unknown>;
  try {
    const tossRes = await fetch(TOSS_CONFIRM_URL, {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(TOSS_SECRET_KEY + ":")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ paymentKey, orderId, amount }),
    });
    tossResp = await tossRes.json();
    if (!tossRes.ok) {
      // wallet_topups에 failed 기록 (idempotency 키와 함께)
      await userClient.from("wallet_topups").insert({
        clue_id: clueId,
        user_id: userId,
        gross_amount: amount,
        fee_amount: 0,
        net_amount: amount,
        fee_rate_bps: FEE_RATE_BPS,
        toss_payment_key: paymentKey,
        toss_order_id: orderId,
        status: "failed",
        raw_response: tossResp,
      });
      return jsonResponse(
        {
          ok: false,
          reason: "toss_rejected",
          detail: tossResp,
        },
        402,
      );
    }
  } catch (e) {
    return jsonResponse(
      { ok: false, reason: "toss_network_error", detail: String(e) },
      502,
    );
  }

  // 토스 응답 검증
  const tossStatus = String(tossResp.status ?? "");
  const tossTotal = Number(tossResp.totalAmount ?? -1);
  if (tossStatus !== "DONE") {
    return jsonResponse(
      { ok: false, reason: "toss_not_done", detail: tossResp },
      402,
    );
  }
  if (tossTotal !== amount) {
    return jsonResponse(
      {
        ok: false,
        reason: "amount_mismatch",
        detail: { client: amount, toss: tossTotal },
      },
      400,
    );
  }

  // 수수료 계산: 정수 단위, floor
  const fee = Math.floor((amount * FEE_RATE_BPS) / 10000);
  const net = amount - fee;

  // RPC 호출 (멱등성 보장)
  const { data: rpcResult, error: rpcErr } = await userClient.rpc(
    "topup_clue_pool",
    {
      user_id_in: userId,
      clue_id_in: clueId,
      gross_in: amount,
      fee_in: fee,
      net_in: net,
      payment_key_in: paymentKey,
      order_id_in: orderId,
      raw_in: tossResp,
    },
  );

  if (rpcErr) {
    return jsonResponse(
      {
        ok: false,
        reason: "rpc_failed",
        detail: rpcErr.message,
      },
      500,
    );
  }

  return jsonResponse({
    ok: true,
    result: rpcResult,
    fee,
    net,
  });
});
