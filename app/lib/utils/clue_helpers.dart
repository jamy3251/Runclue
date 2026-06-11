/// Clue 데이터에서 크리에이터 정보를 안전하게 읽는 헬퍼.
/// 여러 쿼리 경로(embed / RPC / fallback)에서 다른 키로 들어와도 단일 진입점으로 통일.
library;

/// 크리에이터 닉네임 우선순위:
/// 1. clue['creator']['nickname'] (PostgREST embed: profiles!creator_id)
/// 2. clue['creator_profile']['nickname'] (legacy embed)
/// 3. clue['creator_nickname'] (denormalized)
/// 4. clue['creator_name'] (legacy denormalized)
/// 5. fallback '크리에이터'
String clueCreatorName(Map<String, dynamic>? clue) {
  if (clue == null) return '크리에이터';
  final creator = clue['creator'];
  if (creator is Map && creator['nickname'] is String) {
    return creator['nickname'] as String;
  }
  final profile = clue['creator_profile'];
  if (profile is Map && profile['nickname'] is String) {
    return profile['nickname'] as String;
  }
  final n = clue['creator_nickname'] ?? clue['creator_name'];
  if (n is String && n.isNotEmpty) return n;
  return '크리에이터';
}

/// 크리에이터 아바타 URL (없으면 null).
String? clueCreatorAvatarUrl(Map<String, dynamic>? clue) {
  if (clue == null) return null;
  final creator = clue['creator'];
  if (creator is Map && creator['avatar_url'] is String) {
    return creator['avatar_url'] as String;
  }
  final profile = clue['creator_profile'];
  if (profile is Map && profile['avatar_url'] is String) {
    return profile['avatar_url'] as String;
  }
  return null;
}

/// 크리에이터 역할 라벨 — design 결정에 따라 사장/크리에이터/탐험가 구분.
/// profiles.role 컬럼이 'owner'|'business'|'creator'|'explorer' 등으로 들어옴.
String clueCreatorRoleLabel(Map<String, dynamic>? clue) {
  if (clue == null) return '크리에이터';
  final creator = clue['creator'];
  String? role;
  if (creator is Map) {
    role = creator['role']?.toString();
  }
  if (role == null) {
    final profile = clue['creator_profile'];
    if (profile is Map) role = profile['role']?.toString();
  }
  return switch (role) {
    'owner' || 'business' || 'merchant' => '사장',
    'creator' => '크리에이터',
    'explorer' || 'player' => '탐험가',
    _ => '크리에이터',
  };
}
