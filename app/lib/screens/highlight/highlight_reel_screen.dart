import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

/// 미션 완료 후 인증 사진들을 자동 슬라이드쇼로 보여주는 화면.
///
/// Phase 1: 인앱 슬라이드쇼 + 개별 사진 공유
/// Phase 2: GIF/동영상 내보내기 (TODO)
///
/// 전환: 3초마다 페이드 + 스텝 정보 오버레이
class HighlightReelScreen extends StatefulWidget {
  final String clueTitle;
  final List<HighlightItem> items;

  const HighlightReelScreen({
    super.key,
    required this.clueTitle,
    required this.items,
  });

  @override
  State<HighlightReelScreen> createState() => _HighlightReelScreenState();
}

class HighlightItem {
  final String imageUrl;
  final String stepTitle;
  final String stepType;
  final int stepIndex;

  HighlightItem({
    required this.imageUrl,
    required this.stepTitle,
    required this.stepType,
    required this.stepIndex,
  });
}

class _HighlightReelScreenState extends State<HighlightReelScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _autoPlay = true;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_autoPlay) return false;

      final next = (_currentIndex + 1) % widget.items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _autoPlay = false;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('하이라이트')),
        body: const Center(child: Text('인증 사진이 없습니다')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 슬라이드쇼
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 배경 이미지
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),

                  // 하단 스텝 정보 오버레이
                  Positioned(
                    bottom: 100,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Text(
                              '${item.stepIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.stepTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  item.stepType,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 상단 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.clueTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        Share.share(
                          '🏃 "${widget.clueTitle}" 미션 하이라이트! #RunClue',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 진행 인디케이터
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(widget.items.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _currentIndex
                          ? Colors.white
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 일시정지/재생 토글 (탭)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _autoPlay = !_autoPlay;
                  if (_autoPlay) _startAutoPlay();
                });
              },
              child: _autoPlay
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
