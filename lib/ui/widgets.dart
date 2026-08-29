import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';

/// Убирает HTML-теги (API отдаёт <br>, <b> и т.п. в note/description).
String stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll('  ', ' ');

/// Poster with rounded corners and a fade placeholder.
class Poster extends StatelessWidget {
  final String? url;
  final double width, height;
  final double radius;
  const Poster({super.key, this.url, required this.width, required this.height, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? Container(width: width, height: height, color: AppColors.surface)
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: width, height: height, color: AppColors.surface),
              errorWidget: (_, __, ___) => Container(width: width, height: height, color: AppColors.surface),
            ),
    );
  }
}

/// The list item used across Home/Bookmarks/Popular/Search (screenshot 01/06/16).
class ReleaseListItem extends StatelessWidget {
  final Release release;
  final int? rank;
  final VoidCallback? onTap;

  const ReleaseListItem({super.key, required this.release, this.rank, this.onTap});

  @override
  Widget build(BuildContext context) {
    final desc = release.description ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: rank != null ? 30 : 0,
              child: rank != null
                  ? Text('$rank', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary))
                  : null,
            ),
            Poster(url: release.image, width: 86, height: 122),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(release.titleRu ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.25)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(release.episodesLabel,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                    const SizedBox(width: 6),
                    if (release.grade != null && release.grade! > 0) ...[
                      Text(release.grade!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.textSecondary),
                    ],
                  ]),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(desc,
                        maxLines: 4, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary, height: 1.35)),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textTertiary),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal tabs row with the active underline (screenshot 01).
class UnderlineTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const UnderlineTabs({super.key, required this.tabs, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tabs[i],
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? AppColors.textPrimary : AppColors.textTertiary)),
                const SizedBox(height: 6),
                Container(height: 2.5, width: tabs[i].length * 9.0,
                    decoration: BoxDecoration(
                        color: active ? AppColors.textPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2))),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Big rounded dark pill used in Discover (screenshot 05) and elsewhere.
class BigPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const BigPillButton({super.key, required this.icon, required this.label, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}

/// Light filled pill button (Воспроизвести / Применить / Создать коллекцию).
class LightPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const LightPillButton({super.key, required this.label, this.icon, this.loading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: loading ? null : onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black54))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 22, color: Colors.black), const SizedBox(width: 10)],
                  Text(label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                ]),
        ),
      ),
    );
  }
}

class ErrorCentered extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorCentered({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ]),
      ),
    );
  }
}

/// Standard page scaffold: back arrow + title (screenshots 09/14/15/16/17).
class PageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  const PageScaffold({super.key, required this.title, required this.body, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          SizedBox(
            height: 60,
            child: Row(children: [
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              ),
              ...actions,
              const SizedBox(width: 8),
            ]),
          ),
          const Divider(height: 1, color: AppColors.outline),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

/// Paged scroll list helper with "load more" on scroll end.
class PagedScroll<T> extends StatefulWidget {
  final Future<Pageable<T>> Function(int page) loader;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? header;
  const PagedScroll({super.key, required this.loader, required this.itemBuilder, this.header});

  @override
  State<PagedScroll<T>> createState() => _PagedScrollState<T>();
}

class _PagedScrollState<T> extends State<PagedScroll<T>> {
  final List<T> _items = [];
  int _page = 0;
  bool _loading = false;
  bool _canMore = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(reset: true); }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) { _page = 0; _canMore = true; _items.clear(); _error = null; }
    if (!_canMore) return;
    if (mounted) setState(() { _loading = true; });
    try {
      final resp = await widget.loader(_page);
      if (!mounted) return;
      setState(() {
        _items.addAll(resp.content);
        _canMore = resp.content.length >= 20;
        _page += 1;
      });
    } catch (e) {
      if (_items.isEmpty && mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.textSecondary));
    }
    if (_items.isEmpty && _error != null) {
      return ErrorCentered(message: _error!, onRetry: () => _load(reset: true));
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Здесь пока пусто', style: TextStyle(color: AppColors.textTertiary)));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) _load();
        return false;
      },
      child: ListView.builder(
        itemCount: _items.length + (widget.header != null ? 1 : 0) + (_canMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (widget.header != null) {
            if (i == 0) return widget.header!;
            i -= 1;
          }
          if (i >= _items.length) {
            return const Padding(padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.textSecondary)));
          }
          return widget.itemBuilder(context, _items[i], i);
        },
      ),
    );
  }
}
