import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/chat_providers.dart';

class CreateGroupNameScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;

  const CreateGroupNameScreen({super.key, required this.selectedUsers});

  @override
  ConsumerState<CreateGroupNameScreen> createState() =>
      _CreateGroupNameScreenState();
}

class _CreateGroupNameScreenState extends ConsumerState<CreateGroupNameScreen> {
  final _nameCtrl = TextEditingController();
  late List<Map<String, dynamic>> _members;
  bool _isCreating = false;

  ChatRepository get _chatService => ref.read(chatServiceProvider);

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.selectedUsers);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _members.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final groupId = await _chatService.createCustomGroup(name, _members);
      if (mounted) {
        // Go to the chat room
        context.go('/messages/room/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Color _avatarColor(String seed) {
    final colors = [
      const Color(0xFF6B0032), const Color(0xFF3B1F8F),
      const Color(0xFFD13D59), const Color(0xFF1E8F6B),
      const Color(0xFF8F1E6B), const Color(0xFF1E6B8F),
      const Color(0xFF8F6B1E), const Color(0xFF3D59D1),
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

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final bgColor = dark ? const Color(0xFF0A020C) : Colors.white;
    final textColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.white54 : Colors.black54;
    final headerColor = dark ? Colors.white12 : const Color(0xFFF3F4F6);

    final canCreate = _nameCtrl.text.trim().isNotEmpty && _members.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Name of Group Chat',
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          _isCreating
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: canCreate ? const Color(0xFF3B82F6) : Colors.grey.shade300, width: 2),
                    ),
                    child: Icon(Icons.check,
                        size: 20,
                        color: canCreate ? const Color(0xFF3B82F6) : Colors.grey),
                  ),
                  onPressed: canCreate ? _createGroup : null,
                )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text('NAME', style: GoogleFonts.inter(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (val) => setState(() {}), // Trigger re-build for checkmark
                    style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Choose a group chat name',
                      hintStyle: GoogleFonts.inter(color: subtitleColor, fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Member Count Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: headerColor,
            child: Text('${_members.length} Members',
                style: GoogleFonts.inter(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),

          // Members List
          Expanded(
            child: ListView.separated(
              itemCount: _members.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: dark ? Colors.white12 : Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = _members[index];
                final name = user['name'] as String? ?? 'Unknown';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: _avatarColor(user['uid'] as String),
                    child: Text(_initials(name),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name,
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => _removeMember(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
