import 'package:flutter_test/flutter_test.dart';
import 'package:runclue/services/participation_service.dart';

void main() {
  group('ParticipationService.mapRewardType', () {
    test('cash/prize → prize', () {
      expect(ParticipationService.mapRewardType('cash'), 'prize');
      expect(ParticipationService.mapRewardType('prize'), 'prize');
    });

    test('menu_discount/gifticon/coupon → coupon', () {
      expect(ParticipationService.mapRewardType('menu_discount'), 'coupon');
      expect(ParticipationService.mapRewardType('gifticon'), 'coupon');
      expect(ParticipationService.mapRewardType('coupon'), 'coupon');
    });

    test('points/badge/raffle → 그대로', () {
      expect(ParticipationService.mapRewardType('points'), 'points');
      expect(ParticipationService.mapRewardType('badge'), 'badge');
      expect(ParticipationService.mapRewardType('raffle'), 'raffle');
    });

    test('null/알 수 없는 값 → coupon (안전한 기본값)', () {
      expect(ParticipationService.mapRewardType(null), 'coupon');
      expect(ParticipationService.mapRewardType(''), 'coupon');
      expect(ParticipationService.mapRewardType('unknown_type'), 'coupon');
    });
  });

  group('ParticipationService.generateCouponCode', () {
    test('RC- 프리픽스 + 4-4 형식', () {
      final code = ParticipationService.generateCouponCode();
      expect(code, matches(RegExp(r'^RC-[A-Z0-9]{4}-[A-Z0-9]{4}$')));
    });

    test('헷갈리는 글자(0/O, 1/I) 미포함', () {
      // 다수 생성해 통계적으로 검증 — 100회 중 단 1번도 0/O/1/I 안 나와야 함
      for (var i = 0; i < 100; i++) {
        final code = ParticipationService.generateCouponCode();
        expect(code, isNot(contains('0')));
        expect(code, isNot(contains('O')));
        expect(code, isNot(contains('1')));
        expect(code, isNot(contains('I')));
      }
    });

    test('호출마다 다른 코드 생성', () {
      final codes =
          List.generate(20, (_) => ParticipationService.generateCouponCode());
      expect(codes.toSet().length, 20); // 모두 유니크
    });
  });
}
