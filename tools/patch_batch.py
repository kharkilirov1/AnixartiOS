# -*- coding: utf-8 -*-
import io

def patch(path, repls):
    s = io.open(path, encoding='utf-8').read()
    for old, new in repls:
        assert old in s, ('MISSING in ' + path + ': ' + old[:70])
        s = s.replace(old, new)
    io.open(path, 'w', encoding='utf-8').write(s)
    print('patched', path)

# --- Player: resume + fullscreen toggle ---
patch('lib/ui/player/player_screen.dart', [
    ("""import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';""",
     """import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';"""),
    ("""  String? _error;
  bool _controlsVisible = true;
  Timer? _hideTimer;""",
     """  String? _error;
  bool _controlsVisible = true;
  bool _isFullscreen = false;
  Timer? _hideTimer;"""),
    ("""  @override
  void dispose() {
    _hideTimer?.cancel();
    _vc?.dispose();
    super.dispose();
  }""",
     """  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vc?.dispose();
    super.dispose();
  }

  /// Fullscreen: landscape + immersive.
  void _toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (mounted) setState(() {});
  }"""),
    ("""      final controller = VideoPlayerController.networkUrl(Uri.parse(direct));
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
  }""",
     """      final controller = VideoPlayerController.networkUrl(Uri.parse(direct));
      await controller.initialize();
      final saved = _episode.playbackPosition ?? 0;
      if (saved > 10) {
        await controller.seekTo(Duration(seconds: saved));
      }
      await controller.play();
      if (mounted) {
        setState(() { _mode = PlayerMode.native; _vc = controller; });
        _armAutoHide();
      }
    } catch (_) {
      if (mounted) setState(() { _mode = PlayerMode.error; _error = 'Не удалось открыть видео напрямую'; });
    }
  }"""),
    ("""          if (_index < widget.episodes.length - 1)
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                onPressed: () => _openEpisode(_index + 1)),
        ]),""",
     """          if (_index < widget.episodes.length - 1)
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 34),
                onPressed: () => _openEpisode(_index + 1)),
          const SizedBox(width: 8),
          IconButton(
              icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: Colors.white, size: 30),
              onPressed: _toggleFullscreen),
        ]),"""),
])

# --- Search: profile taps -> ProfileScreen ---
patch('lib/ui/search/search_screen.dart', [
    ("""import '../bookmarks/bookmarks_screen.dart';
import '../home/home_screen.dart';""",
     """import '../bookmarks/bookmarks_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';"""),
    ("""              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(p.avatar ?? '')),
                title: Text(p.login ?? ''),
                subtitle: Text(p.status ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {},
              );""",
     """              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(p.avatar ?? '')),
                title: Text(p.login ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(p.status ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5)),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(viewProfileId: p.id))),
              );"""),
])

# --- Comments (preview + full): author tap -> profile ---
patch('lib/ui/release/comments_screen.dart', [
    ("""import '../../core/theme.dart';
import '../widgets.dart';""",
     """import '../../core/theme.dart';
import '../profile/profile_screen.dart';
import '../widgets.dart';"""),
    ("""          Text(c.profile?.login ?? '',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(_relative(c.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 5),""",
     """          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(viewProfileId: c.profile!.id))),
            child: Text(c.profile?.login ?? '',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(_relative(c.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 5),"""),
    ("""          CircleAvatar(radius: 15, backgroundImage: NetworkImage(c.profile?.avatar ?? '')),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Text(c.profile?.login ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),""",
     """          CircleAvatar(radius: 15, backgroundImage: NetworkImage(c.profile?.avatar ?? '')),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(viewProfileId: c.profile!.id))),
            child: Text(c.profile?.login ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),"""),
])

print('ALL OK')
