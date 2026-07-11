import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/chat_providers.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _creatingChat = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  Future<void> _startDirectChat(Map<String, dynamic> classmate) async {
    if (_creatingChat) return;
    setState(() => _creatingChat = true);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final otherUid = classmate['uid'] as String? ?? '';
      final otherName = classmate['name'] as String? ?? 'Classmate';
      final otherEmail = classmate['email'] as String? ?? '';

      // Call the new getOrCreateDirectChat method to start or resume a 1-on-1 chat
      final chatId = await repository.getOrCreateDirectChat(
        otherUserUid: otherUid,
        otherUserName: otherName,
        otherUserEmail: otherEmail,
      );

      if (mounted) {
        context.pushReplacement('/messages/room/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final bgColor = dark ? const Color(0xFF0A020C) : Colors.white;
    final textColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.white54 : Colors.black54;
    final headerColor = dark ? Colors.white12 : const Color(0xFFF3F4F6);

    final classmatesAsync = ref.watch(classmatesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'New Chat',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: dark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: GoogleFonts.inter(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search Classmates',
                      hintStyle: GoogleFonts.inter(color: subtitleColor),
                      prefixIcon: Icon(Icons.search, color: textColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Action Options: Create Group
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.group_add_rounded, color: primaryColor),
                ),
                title: Text(
                  'Create New Group',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                onTap: () {
                  context.push('/messages/create-group-members');
                },
              ),
              const Divider(height: 1),

              // Classmates Contacts
              Expanded(
                child: classmatesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load classmates. Make sure you entered your academic info first!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ),
                  ),
                  data: (classmates) {
                    final filtered = classmates.where((c) {
                      final name = (c['name'] as String? ?? '').toLowerCase();
                      final email = (c['email'] as String? ?? '').toLowerCase();
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No classmates found.' : 'No matching classmates.',
                          style: GoogleFonts.inter(color: subtitleColor),
                        ),
                      );
                    }

                    // Group by first letter
                    final Map<String, List<Map<String, dynamic>>> grouped = {};
                    for (final classmate in filtered) {
                      final name = classmate['name'] as String? ?? '?';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      grouped.putIfAbsent(initial, () => []).add(classmate);
                    }
                    final sortedKeys = grouped.keys.toList()..sort();

                    return ListView.builder(
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, sectionIndex) {
                        final initial = sortedKeys[sectionIndex];
                        final list = grouped[initial]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              color: headerColor,
                              child: Text(
                                initial,
                                style: GoogleFonts.inter(
                                  color: subtitleColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...list.map((c) {
                              final name = c['name'] as String? ?? 'Unknown';
                              final email = c['email'] as String? ?? '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _avatarColor(c['uid'] as String? ?? ''),
                                  child: Text(
                                    _initials(name),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  email,
                                  style: GoogleFonts.inter(color: subtitleColor, fontSize: 12),
                                ),
                                onTap: () => _startDirectChat(c),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_creatingChat)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
