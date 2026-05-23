import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_safe.dart';

/// 가게 커머스 — 메뉴 CRUD + QR 결제 + redemption (트랙 E, Step 16).
class StoreService {
  final SupabaseClient _client = safeClient;

  // ── 사장 본인 메뉴 관리 ──

  Future<List<Map<String, dynamic>>> myMenus(String ownerId) async {
    final rows = await _client
        .from('store_menus')
        .select('id, name, description, price_diamond, image_url, active, display_order, created_at')
        .eq('owner_id', ownerId)
        .order('active', ascending: false)
        .order('display_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> createMenu({
    required String ownerId,
    required String name,
    String? description,
    required int priceDiamond,
    String? imageUrl,
    int displayOrder = 100,
  }) async {
    final res = await _client
        .from('store_menus')
        .insert({
          'owner_id': ownerId,
          'name': name,
          'description': description,
          'price_diamond': priceDiamond,
          'image_url': imageUrl,
          'display_order': displayOrder,
          'active': true,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> updateMenu({
    required String menuId,
    Map<String, dynamic>? patch,
  }) async {
    if (patch == null || patch.isEmpty) return;
    await _client
        .from('store_menus')
        .update({...patch, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', menuId);
  }

  Future<void> deleteMenu(String menuId) async {
    await _client.from('store_menus').delete().eq('id', menuId);
  }

  // ── 사용자가 가게 메뉴 보기 ──

  Future<List<Map<String, dynamic>>> storeMenus(String ownerId) async {
    final rows = await _client
        .from('store_menus')
        .select('id, owner_id, name, description, price_diamond, image_url, display_order')
        .eq('owner_id', ownerId)
        .eq('active', true)
        .order('display_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── 다이아 결제 ──

  Future<Map<String, dynamic>> purchase(String menuId) async {
    final res = await _client.rpc('purchase_store_menu', params: {
      'menu_id_in': menuId,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  // ── 사장 QR 스캔 ──

  Future<Map<String, dynamic>> redeem(String qrToken) async {
    final res = await _client.rpc('redeem_store_purchase', params: {
      'qr_token_in': qrToken,
    });
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': false, 'reason': 'unexpected_response'};
  }

  // ── 내 구매 내역 (buyer 시점) ──

  Future<List<Map<String, dynamic>>> myPurchases(String userId) async {
    final rows = await _client
        .from('store_purchases')
        .select('id, menu_id, store_owner_id, diamond_cost, qr_token, '
            'redeemed_at, expires_at, created_at, '
            'store_menus(name, image_url, description)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── 사장 받은 주문 (owner 시점) ──

  Future<List<Map<String, dynamic>>> myStoreOrders(String ownerId) async {
    final rows = await _client
        .from('store_purchases')
        .select('id, menu_id, user_id, diamond_cost, qr_token, '
            'redeemed_at, expires_at, created_at, '
            'store_menus(name, image_url)')
        .eq('store_owner_id', ownerId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }
}
