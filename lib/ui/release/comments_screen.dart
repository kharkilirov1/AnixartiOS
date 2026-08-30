import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../profile/profile_screen.dart';
import '../widgets.dart';

/// Блок «Комментарии — популярные и актуальные» прямо на странице релиза
/// (первые несколько штук + «Показать все»).
class CommentsPreview extends StatefulWidget {
  final int releaseId;
  final int commentCount;
  const CommentsPreview({super.key, required this.releaseId, required this.commentCount});

  @override
  State<CommentsPreview> createState() => _CommentsPreviewState();
}

class _CommentsPreviewState extends State<CommentsPreview> {
  List<ReleaseComment> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final resp = await Api.I.comments(widget.releaseId, 0);
      if (mounted) setState(() => _items = resp.content.take(5).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(color: AppColors.outline, height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Комментарии', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Популярные и актуальные',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          ])),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CommentsScreen(releaseId: widget.releaseId))),
            child: const Text('Показать все',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          ),
        ]),
      ),
      for (final c in _items) _previewCell(c),
      const SizedBox(height: 8),
    ]);
  }

  Widget _previewCell(ReleaseComment c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 13, backgroundImage: NetworkImage(c.profile?.avatar ?? '')),
          const SizedBox(width: 10),
          GestureDetector(
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
          padding: const EdgeInsets.only(top: 5),
          child: Text(c.message ?? '',
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
        ),
      ]),
    );
  }

  String _relative(int? ts) {
    if (ts == null) return '';
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
    if (d.inMinutes < 60) return '${d.inMinutes} мин назад';
    if (d.inHours < 24) return '${d.inHours} ч назад';
    return '${d.inDays} дн назад';
  }
}

/// Комментарии релиза: список + отправка + голоса.
class CommentsScreen extends StatefulWidget {
  final int releaseId;
  const CommentsScreen({super.key, required this.releaseId});

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
  final Set<int> _revealed = {};
  final Set<int> _showReplies = {};
  final Set<int> _repliesLoading = {};
  final Map<int, List<ReleaseComment>> _replies = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; });
    try {
      final resp = await Api.I.comments(widget.releaseId, _page);
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
      await Api.I.addComment(widget.releaseId, text,
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

  Widget _commentCell(ReleaseComment c, {bool isReply = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 15, backgroundImage: NetworkImage(c.profile?.avatar ?? '')),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(viewProfileId: c.profile!.id))),
            child: Text(c.profile?.login ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(_relative(c.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(isReply ? 60 : 40, 6, 0, 0),
          child: c.isSpoiler == true && !_revealed.contains(c.id)
              ? InkWell(
                  onTap: () => setState(() => _revealed.add(c.id)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('Спойлер — нажмите, чтобы показать',
                        style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ),
                )
              : Text(c.message ?? '',
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
            if ((c.replyCount ?? 0) > 0) ...[
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _toggleReplies(c),
                child: Text(_showReplies.contains(c.id) ? 'Скрыть ответы' : 'Показать ${c.replyCount} отв.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.badgeNew)),
              ),
            ],
          ]),
        ),
        if (_showReplies.contains(c.id))
          if (_repliesLoading.contains(c.id))
            const Padding(padding: EdgeInsets.fromLTRB(60, 8, 0, 0),
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)))
          else
            for (final r in (_replies[c.id] ?? const <ReleaseComment>[]))
              _commentCell(r, isReply: true),
      ]),
    );
  }

  Future<void> _toggleReplies(ReleaseComment c) async {
    if (_showReplies.contains(c.id)) {
      setState(() => _showReplies.remove(c.id));
      return;
    }
    setState(() { _showReplies.add(c.id); _repliesLoading.add(c.id); });
    try {
      final resp = await Api.I.commentReplies(c.id, 0);
      _replies[c.id] = resp.content;
    } catch (_) {
      _replies[c.id] = const [];
    } finally {
      if (mounted) setState(() => _repliesLoading.remove(c.id));
    }
  }

  String _relative(int? ts) {
    if (ts == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final hm = 'в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(that).inDays;
    if (diffDays == 0) return 'сегодня $hm';
    if (diffDays == 1) return 'вчера $hm';
    const months = ['янв.','февр.','марта','апр.','мая','июня','июля','авг.','сент.','окт.','нояб.','дек.'];
    if (date.year == now.year) return '${date.day} ${months[date.month - 1]} $hm';
    return '${date.day} ${months[date.month - 1]} ${date.year} $hm';
  }
}
