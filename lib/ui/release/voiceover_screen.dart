import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../player/player_screen.dart';
import '../widgets.dart';

/// Выбор озвучки (screenshot 13): полноэкранный список типов
/// «Название · N эп.» + просмотры справа, бейдж «Новинка».
class VoiceoverScreen extends StatefulWidget {
  final Release release;
  const VoiceoverScreen({super.key, required this.release});

  @override
  State<VoiceoverScreen> createState() => _VoiceoverScreenState();
}

class _VoiceoverScreenState extends State<VoiceoverScreen> {
  List<EpisodeType> _types = [];
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final t = await Api.I.episodeTypes(widget.release.id);
      if (mounted) setState(() => _types = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Выберите вариант',
      actions: [
        IconButton(icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary), onPressed: () {}),
      ],
      body: Column(children: [
        // Hint card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('Подсказка', style: TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
              SizedBox(width: 6),
              Icon(Icons.lightbulb_outline, size: 15, color: AppColors.textTertiary),
            ]),
            const SizedBox(height: 6),
            Text('Напротив каждого варианта озвучки указано общее количество доступных серий. Статистика просмотров обновляется ежедневно.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textTertiary.withOpacity(0.85), height: 1.4)),
          ]),
        ),
        Expanded(
          child: _error != null
              ? ErrorCentered(message: _error!, onRetry: _load)
              : _types.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
                  : ListView.separated(
                      itemCount: _types.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
                      itemBuilder: (context, i) {
                        final t = _types[i];
                        final views = t.viewCount ?? 0;
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PlayerLoaderScreen(
                                  release: widget.release, type: t))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            child: Row(children: [
                              Text(t.name ?? '',
                                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              Text('·  ${t.episodesCount ?? 0} эп.',
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
                              const Spacer(),
                              if ((t.name ?? '').toLowerCase().contains('anistar') ||
                                  (t.name ?? '').toLowerCase().contains('новинк'))
                                Container(margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.badgeNew),
                                        borderRadius: BorderRadius.circular(7)),
                                    child: const Text('НОВИНКА',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                            color: AppColors.badgeNew))),
                              Text(_compact(views),
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
                              const SizedBox(width: 8),
                              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textTertiary),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  String _compact(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 >= 100 ? 1 : 0)}K';
    return '$n';
  }
}

/// Loads episodes for the selected voiceover and navigates to the player.
class PlayerLoaderScreen extends StatefulWidget {
  final Release release;
  final EpisodeType type;
  const PlayerLoaderScreen({super.key, required this.release, required this.type});

  @override
  State<PlayerLoaderScreen> createState() => _PlayerLoaderScreenState();
}

class _PlayerLoaderScreenState extends State<PlayerLoaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    try {
      final sources = await Api.I.episodeSources(widget.release.id, widget.type.id);
      if (sources.isEmpty) throw Exception('Нет источников');
      final source = sources.first;
      final episodes = await Api.I.episodes(widget.release.id, widget.type.id, source.id);
      if (!mounted) return;
      if (episodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет эпизодов у этого источника')));
        Navigator.pop(context);
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => PlayerScreen(
              release: widget.release, type: widget.type, source: source, episodes: episodes)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.bg,
          body: Center(child: CircularProgressIndicator(color: AppColors.textSecondary)));
}
