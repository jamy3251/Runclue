import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

/// 사장 본인 메뉴 관리 — CRUD 화면.
class MenuManageScreen extends ConsumerWidget {
  const MenuManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMenusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 가게 메뉴')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: Colors.black,
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('메뉴 추가'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러올 수 없습니다: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '아직 등록된 메뉴가 없어요.\n오른쪽 아래 "메뉴 추가"로 시작하세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myMenusProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _MenuTile(row: items[i]),
            ),
          );
        },
      ),
    );
  }

  static void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MenuEditor(existing: existing),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  const _MenuTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = row['active'] as bool? ?? true;
    final price = (row['price_diamond'] as int?) ?? 0;
    final name = row['name'] as String? ?? '';
    final imageUrl = row['image_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active ? AppColors.borderDefault : AppColors.brandRed,),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppColors.bgElevated,
                          child: Icon(Icons.restaurant),),
                    )
                  : const ColoredBox(
                      color: AppColors.bgElevated,
                      child: Icon(Icons.restaurant,
                          color: AppColors.textMuted,),),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, fontWeight: FontWeight.w800,),),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        size: 12, color: AppColors.brandBlue,),
                    const SizedBox(width: 3),
                    Text('$price',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue,),),
                    const SizedBox(width: 10),
                    if (!active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('비활성',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandRed,),),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final id = row['id'] as String;
              if (v == 'edit') {
                MenuManageScreen._showEditor(context, ref, existing: row);
              } else if (v == 'toggle') {
                await ref
                    .read(storeServiceProvider)
                    .updateMenu(menuId: id, patch: {'active': !active});
                ref.invalidate(myMenusProvider);
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('메뉴 삭제'),
                    content: Text('"$name" 삭제할까요?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('취소'),),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('삭제'),),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(storeServiceProvider).deleteMenu(id);
                  ref.invalidate(myMenusProvider);
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'toggle', child: Text(active ? '비활성화' : '활성화')),
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuEditor extends ConsumerStatefulWidget {
  const _MenuEditor({this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends ConsumerState<_MenuEditor> {
  late final _name = TextEditingController(
      text: widget.existing?['name'] as String? ?? '',);
  late final _desc = TextEditingController(
      text: widget.existing?['description'] as String? ?? '',);
  late final _price = TextEditingController(
      text: (widget.existing?['price_diamond'] as int?)?.toString() ?? '500',);
  late final _imageUrl = TextEditingController(
      text: widget.existing?['image_url'] as String? ?? '',);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 가격을 확인해 주세요')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) return;
      final svc = ref.read(storeServiceProvider);
      if (widget.existing != null) {
        await svc.updateMenu(menuId: widget.existing!['id'] as String, patch: {
          'name': name,
          'description': _desc.text.trim(),
          'price_diamond': price,
          'image_url': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        },);
      } else {
        await svc.createMenu(
          ownerId: uid,
          name: name,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          priceDiamond: price,
          imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        );
      }
      ref.invalidate(myMenusProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: inset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? '새 메뉴' : '메뉴 수정',
                style: GoogleFonts.notoSansKr(
                    fontSize: 16, fontWeight: FontWeight.w800,),),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: '메뉴 이름', hintText: '예: 아메리카노',),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: '설명 (선택)', hintText: '예: 따뜻한 핸드드립',),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: '가격 (다이아)', hintText: '500',),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                  labelText: '이미지 URL (선택)', hintText: 'https://...',),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black,),
                      )
                    : Text(widget.existing == null ? '메뉴 추가' : '저장',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 14, fontWeight: FontWeight.w800,),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
