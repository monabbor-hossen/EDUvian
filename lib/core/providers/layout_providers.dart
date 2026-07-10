import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls bottom nav bar visibility. Set to false to smoothly hide the bar
/// (e.g. when entering the chat room), true to restore it.
final navBarVisibleProvider = StateProvider<bool>((ref) => true);
