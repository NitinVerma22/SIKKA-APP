import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/level_repository.dart';

final progressRepositoryProvider = ChangeNotifierProvider<ProgressRepository>((ref) {
  throw UnimplementedError('Initialize progressRepositoryProvider in ArrowEscapeRootWidget');
});

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  throw UnimplementedError('Initialize levelRepositoryProvider in ArrowEscapeRootWidget');
});
