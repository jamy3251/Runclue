import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/participate/participate_screen.dart';
import '../screens/create/create_clue_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/clue/detail/clue_detail_screen.dart';
import '../screens/clue/play/clue_play_screen.dart';
import '../screens/clue/clue_result_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/profile/rewards_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/host/host_dashboard_screen.dart';
import '../screens/join/join_via_link_screen.dart';
import '../screens/mission/mission_map_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/progress/my_progress_screen.dart';
import '../screens/biz/biz_landing_screen.dart';
import '../screens/landing/why_runclue_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/routines/routines_screen.dart';
import '../screens/minigames/minigames_screen.dart';
import '../screens/minigames/rps_game.dart';
import '../screens/minigames/coin_grab_game.dart';
import '../screens/minigames/tap_battle_game.dart';
import '../screens/minigames/othello_game.dart';
import '../screens/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      bool isLoggedIn = false;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        isLoggedIn = session != null;
      } catch (_) {
        // Supabase not initialized — UI preview mode
      }
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/';

      // 스플래시 화면은 항상 허용
      if (isSplash) return null;

      // 딥링크 참여 화면과 공개 페이지는 비회원도 접근 가능
      final isJoinRoute = state.matchedLocation.startsWith('/join');
      final isPublicRoute = state.matchedLocation == '/why-runclue' ||
          state.matchedLocation == '/biz';
      if (!isLoggedIn && !isAuthRoute && !isJoinRoute && !isPublicRoute) {
        return '/auth';
      }

      // 이미 로그인한 경우 인증 화면 접근 시 홈으로 리다이렉트
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      ),

      // Main Shell (Bottom Navigation) — 명세 v2.0: 4탭 한글 라벨
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // 홈 (Home) — Screen 02
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // 탐색 (Explore / ClueList) — Screen 03
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: 'explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),

          // 랭킹 (Rank / MyProgress) — Screen 05
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rank',
                name: 'rank',
                builder: (context, state) => const MyProgressScreen(),
              ),
            ],
          ),

          // 내 정보 (My XP / Profile) — Screen on profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-xp',
                name: 'myXp',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // 제작 (Create) — 셸 외부, FAB로만 진입
      GoRoute(
        path: '/create',
        name: 'create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateClueScreen(),
      ),

      // 참여 진입점 (셸 외부)
      GoRoute(
        path: '/participate',
        name: 'participate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ParticipateScreen(),
      ),

      // 소통 (Community) — 셸 외부, 홈/배너에서 진입
      GoRoute(
        path: '/community',
        name: 'community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunityScreen(),
      ),

      // Clue Detail (outside shell for full-screen experience)
      GoRoute(
        path: '/clue/:id',
        name: 'clueDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final clueId = state.pathParameters['id']!;
          return ClueDetailScreen(clueId: clueId);
        },
        routes: [
          GoRoute(
            path: 'play',
            name: 'cluePlay',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final clueId = state.pathParameters['id']!;
              return CluePlayScreen(clueId: clueId);
            },
          ),
          GoRoute(
            path: 'result',
            name: 'clueResult',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final clueId = state.pathParameters['id']!;
              return ClueResultScreen(clueId: clueId);
            },
          ),
        ],
      ),

      // Mission Map (실시간 미션 맵)
      GoRoute(
        path: '/mission/:id/map',
        name: 'missionMap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final clueId = state.pathParameters['id']!;
          final isHost = state.uri.queryParameters['host'] == 'true';
          return MissionMapScreen(clueId: clueId, isHost: isHost);
        },
      ),

      // Join via Deep Link (비회원도 접근 가능)
      GoRoute(
        path: '/join/:id',
        name: 'joinViaLink',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final clueId = state.pathParameters['id']!;
          return JoinViaLinkScreen(clueId: clueId);
        },
      ),

      // Host Dashboard
      GoRoute(
        path: '/host/:id',
        name: 'hostDashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final clueId = state.pathParameters['id']!;
          return HostDashboardScreen(clueId: clueId);
        },
      ),

      // Post Detail
      GoRoute(
        path: '/post/:id',
        name: 'postDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),

      // Notifications (알림 센터)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationCenterScreen(),
      ),

      // Admin (관리자 페이지) — is_admin() RPC + admin RLS 정책으로 보호
      GoRoute(
        path: '/admin',
        name: 'admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminScreen(),
      ),

      // Routines (루틴 인증) — 매일 가는 곳 streak retention
      GoRoute(
        path: '/routines',
        name: 'routines',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoutinesScreen(),
      ),

      // Minigames (#24) — RPS / 동전줍기 / 때리기 / 오셀로
      GoRoute(
        path: '/minigames',
        name: 'minigames',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MinigamesScreen(),
      ),
      GoRoute(
        path: '/minigames/rps',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RpsGame(),
      ),
      GoRoute(
        path: '/minigames/coin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CoinGrabGame(),
      ),
      GoRoute(
        path: '/minigames/tap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TapBattleGame(),
      ),
      GoRoute(
        path: '/minigames/othello',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OthelloGame(),
      ),

      // My Progress (랭킹 & 기록)
      GoRoute(
        path: '/progress',
        name: 'myProgress',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyProgressScreen(),
      ),

      // Biz Landing (사장님 모드)
      GoRoute(
        path: '/biz',
        name: 'bizLanding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BizLandingScreen(),
      ),

      // Why RunClue (경쟁 우위)
      GoRoute(
        path: '/why-runclue',
        name: 'whyRunClue',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WhyRunClueScreen(),
      ),

      // Search (검색)
      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),

      // Profile Edit
      GoRoute(
        path: '/profile/edit',
        name: 'profileEdit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // 보상함 — 선물함(미수령) + 인벤토리(수령) 2탭
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'gifts';
          return RewardsScreen(initialTab: tab);
        },
      ),

      // Settings
      GoRoute(
        path: '/settings/notifications',
        name: 'notificationSettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: 'privacySettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/blocks',
        name: 'blockManagement',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BlockManagementScreen(),
      ),
      GoRoute(
        path: '/settings/terms',
        name: 'terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TextContentScreen(
          title: '이용약관',
          content: 'RunClue 이용약관\n\n'
              '제1조 (목적)\n본 약관은 RunClue(이하 "서비스")의 이용 조건 및 절차, '
              '이용자와 서비스 제공자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'
              '제2조 (정의)\n1. "서비스"란 RunClue가 제공하는 위치기반 미션 플랫폼을 말합니다.\n'
              '2. "이용자"란 본 약관에 따라 서비스를 이용하는 자를 말합니다.\n\n'
              '제3조 (약관의 효력)\n본 약관은 서비스를 이용하고자 하는 모든 이용자에게 적용됩니다.',
        ),
      ),
      GoRoute(
        path: '/settings/privacy-policy',
        name: 'privacyPolicy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TextContentScreen(
          title: '개인정보처리방침',
          content: 'RunClue 개인정보처리방침\n\n'
              '1. 개인정보의 수집 및 이용 목적\n'
              'RunClue는 회원가입, 서비스 제공을 위해 아래 개인정보를 수집합니다.\n'
              '- 이메일, 닉네임, 프로필 이미지\n'
              '- 위치정보 (클루 참여 시)\n\n'
              '2. 개인정보의 보유 및 이용 기간\n'
              '회원 탈퇴 시까지 보유하며, 탈퇴 후 즉시 파기합니다.\n\n'
              '3. 개인정보의 제3자 제공\n'
              'RunClue는 이용자의 동의 없이 개인정보를 제3자에게 제공하지 않습니다.',
        ),
      ),
    ],
  );
});

