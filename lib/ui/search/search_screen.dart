import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Поиск (screenshot 08): back, поле с микрофоном, история, результаты.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  int _scope = 0; // 0 аниме, 1 коллекции, 2 профили
  bool _searched = false;
  bool _loading = false;
  List<Release> _releases = [];
  List<Collection> _collections = [];
  List<Profile> _profiles = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // Search app bar (screenshot 08)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.maybePop(context)),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'Поиск аниме',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none),
                  onSubmitted: (_) => _run(),
                ),
              ),
              IconButton(icon: const Icon(Icons.mic_none, color: AppColors.textSecondary), onPressed: () {}),
              IconButton(icon: const Icon(Icons.tune, color: AppColors.textSecondary), onPressed: () {}),
            ]),
          ),
          const Divider(height: 1, color: AppColors.outline),
          SizedBox(
            height: 44,
            child: Row(children: [
              const SizedBox(width: 16),
              for (final (i, label) in ['Аниме', 'Коллекции', 'Профили'].indexed) ...[
                GestureDetector(
                  onTap: () => setState(() { _scope = i; if (_searched) _run(); }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Text(label, style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: _scope == i ? FontWeight.w700 : FontWeight.w400,
                        color: _scope == i ? AppColors.textPrimary : AppColors.textTertiary)),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ]),
          ),
          Expanded(child: _results()),
        ]),
      ),
    );
  }

  Widget _results() {
    if (!_searched) {
      return const Center(child: Text('Введите название',
          style: TextStyle(color: AppColors.textTertiary)));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.textSecondary));
    }
    if (_error != null) return ErrorCentered(message: _error!);
    switch (_scope) {
      case 0:
        return ListView.builder(
            itemCount: _releases.length,
            itemBuilder: (_, i) => ReleaseListItem(release: _releases[i],
                onTap: () => Navigator.pushNamed(context, Routes.release,
                    arguments: ReleaseArgs(release: _releases[i]))));
      case 1:
        return ListView.builder(
            itemCount: _collections.length,
            itemBuilder: (_, i) => CollectionCard(collection: _collections[i]));
      default:
        return ListView.builder(
            itemCount: _profiles.length,
            itemBuilder: (_, i) {
              final p = _profiles[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(p.avatar ?? '')),
                title: Text(p.login ?? ''),
                subtitle: Text(p.status ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {},
              );
            });
    }
  }

  Future<void> _run() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searched = true; _error = null; });
    try {
      switch (_scope) {
        case 0:
          final r = await Api.I.searchReleases(q, 0);
          _releases = r.content;
        case 1:
          final r = await Api.I.searchCollections(q, 0);
          _collections = r.content;
        default:
          final r = await Api.I.searchProfiles(q, 0);
          _profiles = r.content;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }
}
