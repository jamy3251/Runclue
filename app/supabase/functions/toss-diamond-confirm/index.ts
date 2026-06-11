// ============================================================================
// toss-diamond-confirm · 사용자 다이아 충전 결제 승인 검증 + 적립
// ============================================================================
// pay-success.html (또는 앱)이 토스 성공 redirect 파라미터로 호출.
// JWT 불필요 — 주문이 create_diamond_order로 사전 등록되어 있고,
// paymentKey는 토스 승인 API로 실검증되므로 위조 불가.
//
// 검증 체인:
//   1. diamond_topups에 pending 주문 존재 (orderId)
//   2. 클라이언트 amount == 주문 price_krw
//   3. 토스 /v1/payments/confirm 승인 성공 + totalAmount == amount
//   4. confirm_diamond_topup RPC (멱등: payment_key UNIQUE)
//
// 호출:
//   POST /functions/v1/toss-diamond-confirm
//   { paymentKey, orderId, amount }
// ============================================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const TOSS_SECRET_KEY = Deno.env.get("TOSS_SECRET_KEY") ?? "";
const TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm";

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

  let body: { paymentKey?: string; orderId?: string; amount?: number };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ ok: false, reason: "invalid_json" }, 400);
  }
  const { paymentKey, orderId, amount } = body;
  if (!paymentKey || !orderId || typeof amount !== "number" || amount <= 0) {
    return jsonResponse({ ok: false, reason: "missing_fields" }, 400);
  }
  if (!orderId.startsWith("dia_")) {
    return jsonResponse({ ok: false, reason: "invalid_order_id" }, 400);
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 1. 사전 등록된 pending 주문 확인 + 금액 검증
  const { data: order, error: orderErr } = await admin
    .from("diamond_topups")
    .select("id, user_id, price_krw, diamond_amount, status, toss_payment_key")
    .eq("order_id", orderId)
    .maybeSingle();
  if (orderErr || !order) {
    return jsonResponse({ ok: false, reason: "order_not_found" }, 404);
  }
  if (order.status === "approved") {
    // 멱등 응답
    return jsonResponse({
      ok: true,
      idempotent: true,
      diamond_amount: order.diamond_amount,
    });
  }
  if (order.status !== "pending") {
    return jsonResponse(
      { ok: false, reason: "invalid_status", status: order.status },
      409,
    );
  }
  if (order.price_krw !== amount) {
    return jsonResponse(
      {
        ok: false,
        reason: "amount_mismatch",
        detail: { order: order.price_krw, client: amount },
      },
      400,
    );
  }

  // 2. 토스 결제 승인 API
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
      await admin
        .from("diamond_topups")
        .update({ status: "failed", raw_response: tossResp })
        .eq("id", order.id)
        .eq("status", "pending");
      return jsonResponse(
        { ok: false, reason: "toss_rejected", detail: tossResp },
        402,
      );
    }
  } catch (e) {
    return jsonResponse(
      { ok: false, reason: "toss_network_error", detail: String(e) },
      502,
    );
  }

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

  // 3. 적립 확정 (멱등 RPC)
  const { data: rpcResult, error: rpcErr } = await admin.rpc(
    "confirm_diamond_topup",
    {
      order_id_in: orderId,
      payment_key_in: paymentKey,
      raw_in: tossResp,
    },
  );
  if (rpcErr) {
    return jsonResponse(
      { ok: false, reason: "rpc_failed", detail: rpcErr.message },
      500,
    );
  }

  return jsonResponse({ ok: true, result: rpcResult });
});
