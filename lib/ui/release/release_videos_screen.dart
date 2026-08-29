import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Видео-раздел релиза (по тапу на баннер трейлеров/опенингов).
class ReleaseVideosScreen extends StatelessWidget {
  final Release release;
  const ReleaseVideosScreen({super.key, required this.release});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Видео',
      body: FutureBuilder<List<VideoBlock>>(
        future: Api.I.releaseVideos(release.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textSecondary));
          }
          if (snap.hasError) return ErrorCentered(message: '${snap.error}');
          final blocks = snap.data ?? [];
          return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            for (final block in blocks) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Text(block.categoryName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              for (final video in block.videos)
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TrailerPlayerScreen(video: video))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(children: [
                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                              imageUrl: video.image ?? '', width: 150, height: 84,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                  width: 150, height: 84, color: AppColors.surface)),
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 34, color: Colors.white70),
                          ),
                        ),
                      ]),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(video.title ?? 'Видео',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        if ((video.hostingName ?? '').isNotEmpty)
                          Text(video.hostingName!,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                      ])),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (blocks.isEmpty) const ErrorCentered(message: 'Видео пока нет'),
          ]);
        },
      ),
    );
  }
}

/// Полноэкранный WebView-плеер для трейлеров (YouTube embed и т.п.).
class TrailerPlayerScreen extends StatefulWidget {
  final ReleaseVideo video;
  const TrailerPlayerScreen({super.key, required this.video});

  @override
  State<TrailerPlayerScreen> createState() => _TrailerPlayerScreenState();
}

class _TrailerPlayerScreenState extends State<TrailerPlayerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final raw = (video.playerUrl ?? video.url ?? '').isNotEmpty
        ? (video.playerUrl ?? video.url!)
        : '';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(raw));
  }

  ReleaseVideo get video => widget.video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.maybePop(context)),
            Expanded(child: Text(video.title ?? 'Трейлер',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15))),
          ]),
          Expanded(child: WebViewWidget(controller: _controller)),
        ]),
      ),
    );
  }
}
