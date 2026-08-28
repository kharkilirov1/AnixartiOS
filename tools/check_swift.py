import re
import pathlib

files = list(pathlib.Path('Anixart').rglob('*.swift'))
defined = set()
for f in files:
    src = f.read_text(encoding='utf-8')
    for m in re.finditer(r'\b(?:struct|class|enum|protocol)\s+(\w+)', src):
        defined.add(m.group(1))
    for m in re.finditer(r'\b(?:func)\s+(\w+)', src):
        defined.add(m.group(1))

issues = []
for f in files:
    src = f.read_text(encoding='utf-8')
    s = re.sub(r'"(?:[^"\\]|\\.)*"', '""', src)
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    bal_brace = s.count('{') - s.count('}')
    bal_paren = s.count('(') - s.count(')')
    if bal_brace or bal_paren:
        issues.append(f"{f}: braces {bal_brace}, parens {bal_paren}")

print("BALANCE ISSUES:", issues if issues else "none")

symbols = [
    "ReleasePagedFeed", "Chip", "ReleaseGrid", "ReleaseRow", "ReleaseCard", "GradePill",
    "SkeletonCard", "ErrorView", "EmptyStateView", "FlowLayout", "PrimaryButton",
    "AuthTextField", "LogoView", "CollectionRow", "CollectionDetailView", "ProfileRow",
    "ProfileSubRoute", "HomeRoute", "DeepLinkDest", "PlayerContext", "PlayerView",
    "WebPlayerView", "NativePlayerView", "VoteRow", "CommentCell", "FriendsListView",
    "NotificationsView", "RandomRollView", "ScheduleView", "ReleaseFeedView",
    "profileListByProfile", "saveHistory", "markWatched", "parseVideo",
    "notificationEpisodes", "notificationComments", "markNotificationsRead",
    "friendRequestSend", "blocklistAdd", "friends", "deleteComment", "voteComment",
    "addComment", "releaseComments", "commentReplies", "collectionReleases",
    "favoriteCollectionAdd", "favoriteCollectionDelete", "collections", "collection",
    "profileList", "profileListAdd", "profileListDelete", "favoriteDelete", "favoriteAdd",
    "favorites", "history", "voteDelete", "voteRelease", "profile", "episodeTypes",
    "episodeSources", "episodes", "searchReleases", "searchCollections", "searchProfiles",
    "recommendations", "watchingFeed", "discussingFeed", "filter", "types", "schedule",
    "randomRelease", "release", "toggles", "restoreVerify", "restore", "resend",
    "verify", "signUp", "signIn", "notificationCount", "deleteHistory",
]
missing = [s for s in symbols if s not in defined]
print("MISSING:", missing if missing else "none")
print("total defined:", len(defined))
