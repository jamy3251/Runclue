import '../config/supabase_safe.dart';

/// 사장님 자동 제휴 신청 서비스
///
/// Supabase 테이블 `partner_applications`(또는 fallback `store_partners`)에 신청 저장.
/// 운영진이 검토 후 승인 → 매장 정식 등록.
class PartnerApplicationService {
  Future<void> submit({
    required String storeName,
    required String ownerName,
    required String phone,
    required String address,
    required String category,
    String? description,
    String? instagramUrl,
  }) async {
    final client = safeClient;
    final payload = {
      'store_name': storeName,
      'owner_name': ownerName,
      'phone': phone,
      'address': address,
      'category': category,
      'description': description,
      'instagram_url': instagramUrl,
      'status': 'pending',
      'source': 'app_landing',
      'created_at': DateTime.now().toIso8601String(),
    };

    // 우선 partner_applications 테이블 시도, 없으면 store_partners
    try {
      await client.from('partner_applications').insert(payload);
      return;
    } catch (_) {
      // fallback: store_partners
    }

    try {
      await client.from('store_partners').insert(payload);
    } catch (e) {
      // 마지막 fallback — 로컬에 저장된 신청 로그를 reports 테이블에 임시 기록
      throw Exception('신청 저장 실패: $e\n수동 등록이 필요합니다.');
    }
  }
}
