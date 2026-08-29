import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Комментарии релиза: список + отправка + голоса.
class CommentsScreen extends StatefulWidget {
  final Release release;
  const CommentsScreen({super.key, required this.release});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  final List<ReleaseComment> _items = [];
  int _page = 0;
  bool _loading = false, _canMore = true, _sending = false;
  String? _error;
  ReleaseComment? _replyTo;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; });
    try {
      final resp = await Api.I.comments(widget.release.id, _page);
      setState(() {
        _items.addAll(resp.content);
        _canMore = resp.content.length >= 20;
        _page += 1;
      });
    } catch (e) {
      if (_items.isEmpty) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; });
    try {
      await Api.I.addComment(widget.release.id, text,
          parentCommentId: _replyTo?.id);
      _controller.clear();
      _replyTo = null;
      _items.clear();
      _page = 0;
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Комментарии',
      body: Column(children: [
        Expanded(
          child: _items.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
              : _items.isEmpty && _error != null
                  ? ErrorCentered(message: _error!, onRetry: () { _items.clear(); _page = 0; _load(); })
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) _load();
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _items.length + (_canMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _items.length) {
                            return const Padding(padding: EdgeInsets.all(14),
                                child: Center(child: CircularProgressIndicator(color: AppColors.textSecondary)));
                          }
                          return _commentCell(_items[i]);
                        },
                      ),
                    ),
        ),
        // Composer
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(color: AppColors.bg),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_replyTo != null)
                Row(children: [
                  Text('Ответ → ${_replyTo!.profile?.login ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  IconButton(icon: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
                      onPressed: () => setState(() => _replyTo = null)),
                ]),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1, maxLines: 4,
                    style: const TextStyle(fontSize: 14.5),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppColors.surface,
                      hintText: Api.I.isAuthorized ? 'Комментарий…' : 'Войдите, чтобы комментировать',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)))
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.textPrimary),
                        onPressed: Api.I.isAuthorized ? _send : null),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _commentCell(ReleaseComment c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 15, backgroundImage: NetworkImage(c.profile?.avatar ?? '')),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Text(c.profile?.login ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(_relative(c.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 6, 0, 0),
          child: Text(c.message ?? '',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 6, 0, 0),
          child: Row(children: [
            InkWell(onTap: () => Api.I.voteComment(c.id, 2), child:
                const Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: AppColors.textTertiary)),
            Text('${c.voteCount ?? 0}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            InkWell(onTap: () => Api.I.voteComment(c.id, 1), child:
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textTertiary)),
            const SizedBox(width: 16),
            InkWell(onTap: () => setState(() => _replyTo = c), child:
                const Text('Ответить', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary))),
          ]),
        ),
      ]),
    );
  }

  String _relative(int? ts) {
    if (ts == null) return '';
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
    if (d.inMinutes < 60) return '${d.inMinutes} мин';
    if (d.inHours < 24) return '${d.inHours} ч';
    return '${d.inDays} дн';
  }
}
