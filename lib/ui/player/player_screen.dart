import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// Плеер: прямые ссылки — video_player, iframe (Kodik) — WebView.
class PlayerScreen extends StatefulWidget {
  final Release release;
  final EpisodeType type;
  final EpisodeSource source;
  final List<Episode> episodes;
  const PlayerScreen({super.key, required this.release, required this.type,
      required this.source, required this.episodes});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _index = 0;
  VideoPlayerController? _vc;
  bool _isIframe = false;
  WebViewController? _web;
  String? _error;

  /// Episodes marked iframe=true must be opened through the Anixart embed
  /// wrapper (same as WebPlayerActivity in the original app): a bare
  /// kodikplayer.com link responds 404.
  static const String _iframeEmbedUrl = 'https://anixmirai.com/iframe?url=';

  @override
  void initState() {
    super.initState();
    _openEpisode(0);
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  Future<void> _openEpisode(int index) async {
    _index = index;
    final ep = widget.episodes[index];
    setState(() { _error = null; _vc?.dispose(); _vc = null; _isIframe = false; _web = null; });

    Api.I.markWatched(widget.release.id, ep.sourceId ?? widget.source.id, ep.position ?? index + 1);
    Api.I.saveHistory(widget.release.id, ep.sourceId ?? widget.source.id, ep.position ?? index + 1);

    final raw = ep.url ?? '';
    if (raw.isEmpty) { setState(() => _error = 'Ссылка на эпизод отсутствует'); return; }

    if (ep.iframe == true) {
      final wrapped = '$_iframeEmbedUrl${Uri.encodeQueryComponent(raw)}';
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(wrapped));
      setState(() { _isIframe = true; _web = controller; });
      return;
    }

    try {
      final links = await Api.I.parseVideo(raw);
      final url = links?.best ?? raw;
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() => _vc = controller);
    } catch (e) {
      // Fallback: try raw URL directly
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(raw));
        await controller.initialize();
        await controller.play();
        if (mounted) setState(() => _vc = controller);
      } catch (_) {
        if (mounted) setState(() => _error = 'Не удалось открыть видео');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = widget.episodes[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.release.titleRu ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${widget.type.name} · ${ep.name ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: Center(
              child: _error != null
                  ? Text(_error!, style: const TextStyle(color: Colors.white70))
                  : _isIframe && _web != null
                      ? SizedBox.expand(child: WebViewWidget(controller: _web!))
                      : _vc != null
                          ? AspectRatio(aspectRatio: _vc!.value.aspectRatio,
                              child: VideoPlayer(_vc!))
                          : const CircularProgressIndicator(color: Colors.white70),
            ),
          ),
          // Episode strip
          Container(
            color: AppColors.bg,
            height: 86,
            child: ListView.separated(
              controller: ScrollController(
                  initialScrollOffset: (_index * 62.0).clamp(0.0, double.maxFinite)),
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: widget.episodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final e = widget.episodes[i];
                final active = i == _index;
                return GestureDetector(
                  onTap: () => _openEpisode(i),
                  child: Container(
                    width: 54,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${e.position ?? i + 1}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.textSecondary))),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
