import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/providers/layout_providers.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_group.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/chat_providers.dart';

// ─── Helpers ────────────────------------------------------------------------───

/// Returns a deterministic vibrant color from a string (uid / name).
Color _avatarColor(String seed) {
  final colors = [
    const Color(0xFF6B0032),
    const Color(0xFF3B1F8F),
    const Color(0xFFD13D59),
    const Color(0xFF1E8F6B),
    const Color(0xFF8F1E6B),
    const Color(0xFF1E6B8F),
    const Color(0xFF8F6B1E),
    const Color(0xFF3D59D1),
  ];
  final idx = seed.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length;
  return colors[idx];
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGES SCREEN  (chat list / entry point)
// ═══════════════════════════════════════════════════════════════════════════════

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.asData?.value != null;

    if (!isLoggedIn) {
      return _LoginRequired(dark: dark);
    }

    return _ChatListView(dark: dark);
  }
}

// ─── Login Required ────────────────────────────────────────────────────────────

class _LoginRequired extends StatelessWidget {
  final bool dark;
  const _LoginRequired({required this.dark});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _chatAppBar(context, 'Messages', dark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: GlassContainer(
              padding:
                  const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded,
                          size: 64,
                          color: primaryColor.withValues(alpha: 0.5))
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 24),
                  Text('Login Required',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87,
                      )),
                  const SizedBox(height: 12),
                  Text(
                    'Please log in to chat with your section peers.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: dark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chat List ─────────────────────────────────────────────────────────────────

class _ChatListView extends ConsumerStatefulWidget {
  final bool dark;
  const _ChatListView({required this.dark});

  @override
  ConsumerState<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<_ChatListView> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(sectionIdProvider);
    final userChatsAsync = ref.watch(userChatsProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: sectionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _NoSectionView(dark: widget.dark),
          data: (sectionId) {
            return userChatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _NoSectionView(dark: widget.dark),
              data: (userChats) {
                // Ensure sectionId chat is always visible even if not yet fully registered
                List<ChatGroup> allChats = List.from(userChats);
                if (sectionId != null && sectionId.isNotEmpty) {
                  final hasSection = allChats.any((c) => c.id == sectionId);
                  if (!hasSection) {
                    allChats.insert(0, ChatGroup(
                      id: sectionId,
                      name: sectionId,
                      type: 'section',
                      memberIds: [],
                      lastMessage: 'Tap to join section chat',
                      lastSenderName: '',
                    ));
                  }
                }
                
                if (allChats.isEmpty) {
                  return _NoSectionView(dark: widget.dark);
                }
                
                return _AllChatsList(
                  chats: allChats,
                  dark: widget.dark,
                  query: _query,
                  onSearchChanged: (v) => setState(() => _query = v.toLowerCase()),
                  searchCtrl: _searchCtrl,
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final dark = widget.dark;
    final textColor = dark ? Colors.white : primaryColor;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Messages',
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              color: dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3)),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => context.push('/messages/create-group-members'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.15)
                      : primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(Icons.edit_rounded, size: 18, color: textColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── All Chats List ────────────────────────────────----------------------------

class _AllChatsList extends StatefulWidget {
  final List<ChatGroup> chats;
  final bool dark;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchCtrl;

  const _AllChatsList({
    required this.chats,
    required this.dark,
    required this.query,
    required this.onSearchChanged,
    required this.searchCtrl,
  });

  @override
  State<_AllChatsList> createState() => _AllChatsListState();
}

class _AllChatsListState extends State<_AllChatsList> {
  final Set<String> _removedChats = {};

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;

    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.07),
              ),
            ),
            child: TextField(
              controller: widget.searchCtrl,
              onChanged: widget.onSearchChanged,
              style: GoogleFonts.inter(
                color: dark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.inter(
                  color: dark ? Colors.white38 : Colors.black38,
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: dark ? Colors.white38 : Colors.black38, size: 22),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
        ),

        // ── Chat list ─────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: widget.chats.length,
            itemBuilder: (context, index) {
              final chat = widget.chats[index];
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final isOwnLast = false; // Add logic if needed: data['lastSenderId'] == currentUid;

              final matchesQuery = widget.query.isEmpty || chat.name.toLowerCase().contains(widget.query);

              if (!matchesQuery || _removedChats.contains(chat.id)) {
                return const SizedBox.shrink();
              }

              return _ChatTile(
                key: ValueKey(chat.id),
                chatName: chat.name,
                lastMessage: isOwnLast
                    ? 'You: ${chat.lastMessage}'
                    : (chat.lastSenderName.isNotEmpty && chat.lastSenderName != 'System'
                        ? '${chat.lastSenderName}: ${chat.lastMessage}'
                        : chat.lastMessage),
                timestamp: chat.lastTimestamp,
                dark: dark,
                isMuted: currentUid != null && chat.mutedBy.contains(currentUid),
                onTap: () {
                  context.push('/messages/room/${chat.id}');
                },
                onDelete: () => setState(() => _removedChats.add(chat.id)),
                onInfo: () => _showOptionsSheet(context, chat, currentUid ?? '', dark),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context, ChatGroup chat, String currentUid, bool dark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChatOptionsSheet(
        chat: chat,
        currentUid: currentUid,
        dark: dark,
      ),
    );
  }
}

// ─── Chat Tile ────────────────────────────────---------------------------------

class _ChatTile extends StatefulWidget {
  final String chatName;
  final String lastMessage;
  final DateTime? timestamp;
  final bool dark;
  final bool isMuted;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onInfo;

  const _ChatTile({
    super.key,
    required this.chatName,
    required this.lastMessage,
    required this.timestamp,
    required this.dark,
    required this.isMuted,
    required this.onTap,
    required this.onDelete,
    required this.onInfo,
  });

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  double _swipeOffset = 0;
  bool _swiping = false;
  static const _revealThreshold = 80.0;

  @override
  void didUpdateWidget(covariant _ChatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Close any open swipe when the list refreshes (e.g. Firestore update / hot reload)
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final initials = widget.chatName.length >= 2
        ? widget.chatName.substring(0, 2)
        : widget.chatName;
    final avatarColor = _avatarColor(widget.chatName);

    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _swiping = true),
      onHorizontalDragUpdate: (details) {
        if (!_swiping) return;
        setState(() {
          _swipeOffset =
              (_swipeOffset + details.delta.dx).clamp(-_revealThreshold, 0.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_swipeOffset < -_revealThreshold * 0.5) {
          setState(() {
            _swipeOffset = -_revealThreshold;
            _swiping = false;
          });
        } else {
          setState(() {
            _swipeOffset = 0;
            _swiping = false;
          });
        }
      },
      onLongPress: widget.onInfo,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Swipe background actions — only visible when swiped open
          if (_swipeOffset < 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RevealButton(
                  icon: Icons.more_horiz_rounded,
                  color: Colors.grey.withValues(alpha: 0.15),
                  iconColor: Colors.black,
                  onTap: () {
                    setState(() => _swipeOffset = 0);
                    widget.onInfo();
                  },
                ),
                _RevealButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.withValues(alpha: 0.85),
                  iconColor: Colors.white,
                  onTap: () {
                    setState(() => _swipeOffset = 0);
                    widget.onDelete();
                  },
                ),
              ],
            ),

          // Main tile slides over the buttons
          AnimatedSlide(
            offset: Offset(_swipeOffset / MediaQuery.of(context).size.width, 0),
            duration: _swiping ? Duration.zero : 200.ms,
            curve: Curves.easeOut,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: primaryColor.withValues(alpha: 0.06),
              highlightColor: primaryColor.withValues(alpha: 0.04),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.0)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                avatarColor,
                                avatarColor.withValues(alpha: 0.65),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: avatarColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        // Online dot
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.greenAccent.shade400,
                              border: Border.all(
                                color: dark
                                    ? const Color(0xFF0A020C)
                                    : const Color(0xFFFAF5F8),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Name + last message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.lastMessage,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: dark ? Colors.white54 : Colors.black45,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Time + unread + mute icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.timestamp != null)
                          Text(
                            formatListTime(widget.timestamp!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: dark ? Colors.white30 : Colors.black38,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isMuted) ...[
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 14,
                                color: dark ? Colors.white30 : Colors.black38,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Swipe Reveal Button ──────────────────────────────────────────────────────

class _RevealButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _RevealButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 78,
        color: color,
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}

// ─── Members Bottom Sheet ──────────────────────────────────────────────────────

class _ChatOptionsSheet extends ConsumerStatefulWidget {
  final ChatGroup chat;
  final String currentUid;
  final bool dark;

  const _ChatOptionsSheet({
    required this.chat,
    required this.currentUid,
    required this.dark,
  });

  @override
  ConsumerState<_ChatOptionsSheet> createState() => _ChatOptionsSheetState();
}

class _ChatOptionsSheetState extends ConsumerState<_ChatOptionsSheet> {
  bool _isProcessing = false;

  void _mute(bool mute) async {
    setState(() => _isProcessing = true);
    await ref.read(chatRepositoryProvider).muteGroup(widget.chat.id, mute);
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
    }
  }

  void _leave() async {
    setState(() => _isProcessing = true);
    await ref.read(chatRepositoryProvider).leaveGroup(widget.chat.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
    }
  }

  void _delete() async {
    setState(() => _isProcessing = true);
    await ref.read(chatRepositoryProvider).deleteGroup(widget.chat.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final membersAsync = ref.watch(chatMembersProvider(widget.chat.id));
    final isMuted = widget.chat.mutedBy.contains(widget.currentUid);

    return GlassContainer(
      blur: 24,
      alpha: 0.8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      borderColor: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: dark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.chat.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          membersAsync.when(
            loading: () => const Center(child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (_) => Text(
              '${widget.chat.memberIds.length} Members',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: dark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal members list
          SizedBox(
            height: 80,
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error', style: GoogleFonts.inter(color: Colors.red))),
              data: (members) {
                // Filter against the authoritative memberIds to exclude stale subcollection docs
                final validMembers = members
                    .where((m) => widget.chat.memberIds.contains(m['uid'] as String? ?? ''))
                    .toList();
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: validMembers.length,
                  itemBuilder: (context, index) {
                    final m = validMembers[index];
                    final name = m['name'] as String? ?? 'Unknown';
                    final uid = m['uid'] as String? ?? '';
                    final parts = name.split(' ');
                    final shortName = parts.isNotEmpty ? parts[0] : name;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _avatarColor(uid),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shortName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: dark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action: Mute
          ListTile(
            onTap: _isProcessing ? null : () => _mute(!isMuted),
            leading: Icon(
              isMuted ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
              color: dark ? Colors.white70 : Colors.black87,
            ),
            title: Text(
              isMuted ? 'Unmute Group' : 'Mute Group',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Only allow leave/delete for custom groups OR just leave for everyone
          if (widget.chat.type == 'custom') ...[
            ListTile(
              onTap: _isProcessing ? null : _leave,
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.orange),
              title: Text(
                'Leave Group',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
            ListTile(
              onTap: _isProcessing ? null : _delete,
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(
                'Delete Group',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── No Section Placeholder ────────────────────────────────────────────────────

class _NoSectionView extends StatelessWidget {
  final bool dark;
  const _NoSectionView({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: primaryColor.withValues(alpha: 0.6))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 20),
              Text(
                'No Chats Yet',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add academic info in Settings to join your section chat, or tap the button below to start a custom group.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: dark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT ROOM SCREEN (specific room conversations)
// ═══════════════════════════════════════════════════════════════════════════════

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String sectionId;

  const ChatRoomScreen({super.key, required this.sectionId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _hasText = false;

  ChatRepository get _chatService => ref.read(chatServiceProvider);

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    // Hide bottom nav bar smoothly when chat room opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarVisibleProvider.notifier).state = false;
      _chatService.registerMember(widget.sectionId);
    });
  }

  @override
  void dispose() {
    // Restore bottom nav bar when leaving the chat room
    Future.microtask(() {
      try {
        ref.read(navBarVisibleProvider.notifier).state = true;
      } catch (_) {}
    });
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _msgCtrl.text.trim().isEmpty) return;
    final text = _msgCtrl.text;
    _msgCtrl.clear();
    setState(() => _sending = true);
    await _chatService.sendMessage(widget.sectionId, text);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.sectionId));
    final currentUid = _chatService.currentUid;

    return WillPopScope(
      onWillPop: () async {
        ref.read(navBarVisibleProvider.notifier).state = true;
        return true;
      },
      child: AppBackground(
        bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').doc(widget.sectionId).snapshots(),
            builder: (context, snap) {
              final data = snap.hasData && snap.data!.exists ? snap.data!.data() as Map<String, dynamic> : <String, dynamic>{};
              final chatName = data['name'] as String? ?? data['sectionId'] as String? ?? widget.sectionId;
              final memberIds = List<String>.from(data['memberIds'] ?? []);
              final numMembers = memberIds.isNotEmpty ? memberIds.length : 1;
              
              final textColor = dark ? Colors.white : primaryColor;
              final avatarColor = _avatarColor(chatName);
              final initials = chatName.length >= 2 ? chatName.substring(0, 2) : chatName;

              return AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                  onPressed: () {
                    ref.read(navBarVisibleProvider.notifier).state = true;
                    Navigator.of(context).pop();
                  },
                ),
                title: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [avatarColor, avatarColor.withValues(alpha: 0.6)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.greenAccent.shade400,
                              border: Border.all(
                                color: dark
                                    ? const Color(0xFF0A020C)
                                    : const Color(0xFFFAF5F8),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatName,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$numMembers Members · Active now',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.greenAccent.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.info_outline_rounded, color: textColor),
                    onPressed: () => _showMembersSheet(context, widget.sectionId, dark),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            }
          ),
        ),
        // Input pinned flush to the screen bottom — Scaffold handles
        // safe-area insets and keyboard offset automatically.
        bottomNavigationBar: _MessageInput(
          controller: _msgCtrl,
          dark: dark,
          hasText: _hasText,
          sending: _sending,
          onSend: _send,
        ),
        body: messagesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.inter(color: Colors.red)),
          ),
          data: (messages) {
            if (messages.isEmpty) {
              return _EmptyChat(dark: dark);
            }
            // Auto-scroll only when the user is already near the bottom
            // so we don't hijack their scroll while they're reading history
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollCtrl.hasClients) {
                final pos = _scrollCtrl.position;
                final nearBottom = pos.maxScrollExtent - pos.pixels < 200;
                if (nearBottom) _scrollToBottom();
              }
            });

            return ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isMe = msg.senderId == currentUid;
                final showAvatar = !isMe &&
                    (i == 0 ||
                        messages[i - 1].senderId != msg.senderId);
                final showName = !isMe &&
                    (i == 0 ||
                        messages[i - 1].senderId != msg.senderId);

                return _MessageBubble(
                  message: msg,
                  isMe: isMe,
                  showAvatar: showAvatar,
                  showName: showName,
                  dark: dark,
                  animIndex: i,
                );
              },
            );
          },
        ),
      ),
    ));
  }

  void _showMembersSheet(
      BuildContext context, String sectionId, bool dark) async {
    // Fetch live data to build a ChatGroup for the options sheet
    final doc = await FirebaseFirestore.instance.collection('chats').doc(sectionId).get();
    final data = doc.exists ? doc.data() as Map<String, dynamic> : <String, dynamic>{};
    final chatGroup = ChatGroup(
      id: sectionId,
      name: data['name'] as String? ?? data['sectionId'] as String? ?? sectionId,
      type: data['type'] as String? ?? 'section',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      lastMessage: '',
      lastSenderName: '',
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
    );
    final currentUid = _chatService.currentUid ?? '';
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChatOptionsSheet(
        chat: chatGroup,
        currentUid: currentUid,
        dark: dark,
      ),
    );
  }
}

// ─── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;
  final bool dark;
  final int animIndex;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
    required this.dark,
    required this.animIndex,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor(message.senderId);

    return Padding(
      padding: EdgeInsets.only(
        top: showName ? 10 : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Friend Avatar
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarColor,
                child: Text(
                  message.initials,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          // Bubble Content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white38 : Colors.black45),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe
                        ? null
                        : (dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isMe ? 18 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : (dark
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.05))
                            : Border.all(
                                color: Colors.black.withValues(alpha: 0.08))),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? primaryColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isMe ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: isMe
                          ? Colors.white
                          : (dark ? Colors.white : Colors.black87),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Message timestamp
          Text(
            formatBubbleTime(message.timestamp),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: dark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ).animate().fadeIn(duration: 250.ms).slideY(
          begin: 0.15,
          duration: 350.ms,
          curve: Curves.easeOutBack,
          delay: math.min(animIndex * 30, 200).ms),
    );
  }
}

// ─── Message Input Box ─────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool dark;
  final bool hasText;
  final bool sending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.dark,
    required this.hasText,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padded container that handles system bottom safe-area insets
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.paddingOf(context).bottom + 10),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF0A020C).withValues(alpha: 0.85)
            : const Color(0xFFFAF5F8).withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            children: [
              // Attach button
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: dark ? Colors.white54 : Colors.black45, size: 24),
                onPressed: () {},
              ),

              // Text Field Container
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: dark ? Colors.white : Colors.black87),
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: dark ? Colors.white38 : Colors.black38),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              IconButton(
                icon: AnimatedScale(
                  scale: hasText ? 1.0 : 0.85,
                  duration: 150.ms,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasText
                          ? const LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            )
                          : null,
                      color: hasText
                          ? null
                          : (dark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.04)),
                      boxShadow: hasText
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: hasText
                                  ? Colors.white
                                  : (dark ? Colors.white38 : Colors.black38),
                            ),
                    ),
                  ),
                ),
                onPressed: hasText ? onSend : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty Chat State ──────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final bool dark;
  const _EmptyChat({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: dark ? 0.15 : 0.07),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: primaryColor,
                size: 32,
              ),
            ).animate().scale(
                duration: 400.ms,
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack),
            const SizedBox(height: 18),
            Text(
              'Start the Conversation',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message to start chatting with your peers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: dark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legacy Helper ────────────────────────────────────────────────────────────

AppBar _chatAppBar(BuildContext context, String title, bool dark) {
  final textColor = dark ? Colors.white : primaryColor;

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    title: Text(
      title,
      style: GoogleFonts.poppins(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    ),
    centerTitle: true,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            color: dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3)),
      ),
    ),
  );
}
