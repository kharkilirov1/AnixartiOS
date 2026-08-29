import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../profile/profile_screen.dart';
import '../widgets.dart';

/// Список друзей пользователя.
class FriendsScreen extends StatelessWidget {
  final int profileId;
  final String title;
  const FriendsScreen({super.key, required this.profileId, this.title = 'Друзья'});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      body: PagedScroll<Profile>(
        loader: (page) => Api.I.friends(profileId, page),
        itemBuilder: (context, p, __) => ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(p.avatar ?? ''),
            backgroundColor: AppColors.surface,
          ),
          title: Text(p.login ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(p.status ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5)),
          trailing: p.isOnline == true
              ? const Icon(Icons.circle, size: 9, color: AppColors.statWatching)
              : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProfileScreen(viewProfileId: p.id))),
        ),
      ),
    );
  }
}
