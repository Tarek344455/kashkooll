import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI locale, switchable at runtime without restarting the app.
final currentLocaleProvider = StateProvider<String>((ref) => 'en');
