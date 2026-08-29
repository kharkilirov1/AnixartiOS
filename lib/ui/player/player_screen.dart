import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// Встроенный плеер.
/// - iframe-эпизоды (Kodik): WebView с anixmirai-обёрткой + JS-перехват
///   прямых ссылок (.m3u8/.mp4) — пойманная ссылка отдаётся нативному
///   плееру с полноценными контролами (как SwiftPlayerActivity в оригинале).
/// - Прямые ссылки: video/parse -> нативный плеер сразу.
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

enum PlayerMode { loading, native, webview, error }

class _PlayerScreenState extends State<PlayerScreen> {
  static const String _iframeEmbedUrl = 'https://anixmirai.com/iframe?url=';

  /// Injected into the WebView: wraps fetch/XHR/HTMLMediaElement.src so the
  /// player's real stream URLs surface through the Sniffer channel.
  static const String _snifferJs = r'''
(function(){
  if (window.__anix_sniff) return; window.__anix_sniff = true;
  var re = /\.(m3u8|mp4)(\?|$)/i;
  var post = function(u){ try { Sniffer.postMessage(u); } catch(e){} };
  var of = window.fetch;
  window.fetch = function(input){
    try { var u = typeof input === 'string' ? input : (input && input.url) || '';
      if (re.test(u)) post(u); } catch(e){}
    return of.apply(this, arguments);
  };
  var oo = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(m, u){
    try { if (re.test(String(u))) post(u); } catch(e){}
    return oo.apply(this, arguments);
  };
  try {
    var d = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
    Object.defineProperty(HTMLMediaElement.prototype, 'src', {
      set: function(v){ try { if (re.test(String(v))) post(v); } catch(e){} d.set.call(this, v); },
      get: function(){ return d.get.call(this); }
    });
  } catch(e){}
})();
''';

  int _index = 0;
  PlayerMode _mode = PlayerMode.loading;
  VideoPlayerController? _vc;
  WebViewController? _web;
  String? _webUrl;
  final Set<String> _seen = {};
  String? _error;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _openEpisode(0);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _vc?.dispose();
    super.dispose();
  }

  Episode get _episode => widget.episodes[_index];

  Future<void> _openEpisode(int index) async {
    _index = index;
    final ep = _episode;
    if (mounted) {
      setState(() {
        _mode = PlayerMode.loading;
        _error = null;
        _seen.clear();
      });
    }
    _vc?.dispose();
    _vc = null;
    _web = null;

    // Синхронизация просмотра (как в оригинале).
    Api.I.markWatched(widget.release.id, ep.sourceId ?? widget.source.id, ep.position ?? index + 1);
    Api.I.saveHistory(widget.release.id, ep.sourceId ?? widget.source.id, ep.position ?? index + 1);

    final raw = ep.url ?? '';
    if (raw.isEmpty) {
      setState(() { _mode = PlayerMode.error; _error = 'Ссылка на эпизод отсутствует'; });
      return;
    }

    if (ep.iframe == true) {
      final wrapped = '$_iframeEmbedUrl${Uri.encodeQueryComponent(raw)}';
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel('Sniffer', onMessageReceived: (msg) => _onSniffed(msg.message))
        ..loadRequest(Uri.parse(wrapped));
      controller.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => controller.runJavaScript(_snifferJs),
        onNavigationRequest: (req) {
          if (RegExp(r'\.(m3u8|mp4)(\?|$)', caseSensitive: false).hasMatch(req.url)) {
            _onSniffed(req.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
      if (mounted) {
        setState(() { _mode = PlayerMode.webview; _web = controller; _webUrl = wrapped; });
      }
      return;
    }

    await _openNative(raw);
  }

  Future<void> _openNative(String url) async {
    try {
      var direct = url;
      if (!RegExp(r'\.(m3u8|mp4)(\?|$)', caseSensitive: false).hasMatch(url)) {
        final links = await Api.I.parseVideo(url);
        direct = links?.best ?? url;
      }
      final controller = VideoPlayerController.networkUrl(Uri.parse(direct));
      await controller.initialize();
      await controller.play();
      if (mounted) {
        setState(() { _mode = PlayerMode.native; _vc = controller; });
        _armAutoHide();
      }
    } catch (_) {
      if (mounted) {
        setState(() { _mode = PlayerMode.error; _error = 'Не удалось открыть видео напрямую'; });
      }
    }
  }

  /// Первая пойманная ссылка потока -> встроенный плеер.
  Future<void> _onSniffed(String url) async {
    if (_seen.contains(url) || _mode == PlayerMode.native) return;
    _seen.add(url);
    if (!RegExp(r'\.(m3u8|mp4)(\?|$)', caseSensitive: false).hasMatch(url)) return;
    if (!mounted) return;
    setState(() { _mode = PlayerMode.loading; });
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.play();
      if (mounted) {
        setState(() { _mode = PlayerMode.native; _vc = controller; });
        _armAutoHide();
      }
    } catch (_) {
      // Поток не открылся нативно — остаёмся в веб-плеере.
      if (mounted) setState(() { _mode = PlayerMode.webview; });
    }
  }

  void _armAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _armAutoHide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(child: GestureDetector(
            onTap: _mode == PlayerMode.native ? _toggleControls : null,
            child: Stack(children: [
              Center(child: _playerArea()),
              if (_mode == PlayerMode.native && _vc != null)
                Positioned.fill(child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: _nativeControls()))),
              if (_mode == PlayerMode.loading)
                const Center(child: CircularProgressIndicator(color: Colors.white70)),
            ]),
          )),
          _episodeStrip(),
        ]),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.release.titleRu ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${widget.type.name} · ${_episode.name ?? ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _playerArea() {
    if (_mode == PlayerMode.error) {
      return Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error ?? '', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            if (_webUrl != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: () => setState(() { _mode = PlayerMode.webview; }),
                  child: const Text('Открыть веб-плеер', style: TextStyle(color: AppColors.light))),
            ],
          ]));
    }
    if (_mode == PlayerMode.webview && _web != null) {
      return SizedBox.expand(child: WebViewWidget(controller: _web!));
    }
    if (_mode == PlayerMode.native && _vc != null) {
      return AspectRatio(aspectRatio: _vc!.value.aspectRatio, child: VideoPlayer(_vc!));
    }
    return const SizedBox.shrink();
  }

  Widget _nativeControls() {
    final vc = _vc!;
    return Container(
      color: Colors.black38,
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: vc,
          builder: (context, value, _) {
            final pos = value.position;
            final dur = value.duration;
            String fmt(Duration d) =>
                '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(children: [
                Text(fmt(pos), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: dur.inMilliseconds > 0
                        ? pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble()
                        : 0,
                    max: dur.inMilliseconds.toDouble(),
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => vc.seekTo(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Text(fmt(dur), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            );
          },
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_index > 0)
            IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 34),
                onPressed: () => _openEpisode(_index - 1)),
          const SizedBox(width: 18),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: vc,
            builder: (context, value, _) => GestureDetector(
              onTap: () => value.isPlaying ? vc.pause() : vc.play(),
              child: Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black, size: 38),
              ),
            ),
          ),
          const SizedBox(width: 18),
          if (_index < widget.episodes.length - 1)
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                onPressed: () => _openEpisode(_index + 1)),
        ]),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _episodeStrip() {
    return Container(
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
    );
  }
}
