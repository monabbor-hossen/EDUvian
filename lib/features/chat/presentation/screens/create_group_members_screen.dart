import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/chat_providers.dart';

class CreateGroupMembersScreen extends ConsumerStatefulWidget {
  const CreateGroupMembersScreen({super.key});

  @override
  ConsumerState<CreateGroupMembersScreen> createState() =>
      _CreateGroupMembersScreenState();
}

class _CreateGroupMembersScreenState
    extends ConsumerState<CreateGroupMembersScreen> {
  final _searchCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selectedUsers = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _loading = true);
    try {
      final users = await ref.read(classmatesProvider.future);
      
      // Sort alphabetically (classmatesProvider is already sorted, but we ensure it here)
      users.sort((a, b) => (a['name'] as String? ?? '')
          .toLowerCase()
          .compareTo((b['name'] as String? ?? '').toLowerCase()));
          
      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(users);
          _searchResults = List<Map<String, dynamic>>.from(users);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim().toLowerCase();
      if (trimmed.isEmpty) {
        setState(() => _searchResults = List.from(_allUsers));
      } else {
        setState(() {
          _searchResults = _allUsers.where((user) {
            final name = (user['name'] as String? ?? '').toLowerCase();
            final email = (user['email'] as String? ?? '').toLowerCase();
            return name.contains(trimmed) || email.contains(trimmed);
          }).toList();
        });
      }
    });
  }

  void _toggleUser(Map<String, dynamic> user) {
    setState(() {
      final idx = _selectedUsers.indexWhere((u) => u['uid'] == user['uid']);
      if (idx >= 0) {
        _selectedUsers.removeAt(idx);
      } else {
        _selectedUsers.add(user);
      }
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

    // Group search results by first letter
    final Map<String, List<Map<String, dynamic>>> groupedUsers = {};
    for (final user in _searchResults) {
      final name = user['name'] as String? ?? '?';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      groupedUsers.putIfAbsent(initial, () => []).add(user);
    }
    final sortedKeys = groupedUsers.keys.toList()..sort();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Add Group Members',
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward,
                color: _selectedUsers.isNotEmpty
                    ? const Color(0xFF3B82F6) // Active blue
                    : Colors.grey),
            onPressed: _selectedUsers.isNotEmpty
                ? () {
                    // Navigate to Name Group screen with selected users
                    context.push('/messages/create-group-name', extra: _selectedUsers);
                  }
                : null,
          )
        ],
      ),
      body: Column(
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
                    color: dark ? Colors.white24 : Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.inter(color: subtitleColor),
                  prefixIcon: Icon(Icons.search, color: textColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Selected Members Horizontal List
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedUsers.length,
                itemBuilder: (context, i) {
                  final user = _selectedUsers[i];
                  final name = user['name'] as String? ?? 'Unknown';
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _avatarColor(user['uid'] as String),
                              child: Text(_initials(name),
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _toggleUser(user),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cancel,
                                      size: 20, color: Colors.black87),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            name.split(' ').first,
                            style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

          // Platform header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: headerColor,
            child: Text('On the platform',
                style: GoogleFonts.inter(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),

          // User List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, sectionIndex) {
                      final initial = sortedKeys[sectionIndex];
                      final users = groupedUsers[initial]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Letter Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            color: headerColor,
                            child: Text(initial,
                                style: GoogleFonts.inter(
                                    color: subtitleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                          // Users in this letter
                          ...users.map((user) {
                            final isSelected = _selectedUsers
                                .any((u) => u['uid'] == user['uid']);
                            final name = user['name'] as String? ?? 'Unknown';
                            final email = user['email'] as String? ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    _avatarColor(user['uid'] as String),
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
                              subtitle: Text(email,
                                  style: GoogleFonts.inter(
                                      color: subtitleColor, fontSize: 13)),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF3B82F6), size: 28)
                                  : null,
                              onTap: () => _toggleUser(user),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
