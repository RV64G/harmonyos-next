import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/auth/auth_controller.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_angle.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_batch_storage.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_opening.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_preferences.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_repository.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_service.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_storage.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_theme.dart';
import 'package:lichess_mobile/src/model/puzzle/storm.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/utils/riverpod.dart';

/// Fetches the next puzzle for the given [PuzzleAngle].
final nextPuzzleProvider = FutureProvider.autoDispose.family<PuzzleContext?, PuzzleAngle>((
  Ref ref,
  PuzzleAngle angle,
) async {
  final authUser = ref.watch(authControllerProvider);
  // useful for for preview puzzle list in puzzle tab (providers in a list can
  // be invalidated multiple times when the user scrolls the list)
  ref.cacheFor(const Duration(minutes: 1));

  try {
    final puzzleService = await ref
        .read(puzzleServiceFactoryProvider)(queueLength: kPuzzleLocalQueueLength)
        .timeout(const Duration(seconds: 3));
    return await puzzleService
        .nextPuzzle(userId: authUser?.user.id, angle: angle)
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // On platforms without a working SQLite implementation (for example the
    // current ohos port), local puzzle storage can hang during initialization.
    // Keep the puzzle tab usable by fetching a single preview puzzle directly.
    final difficulty = ref.read(puzzlePreferencesProvider).difficulty;
    final batch = await ref
        .read(puzzleRepositoryProvider)
        .selectBatch(nb: 1, angle: angle, difficulty: difficulty)
        .timeout(const Duration(seconds: 10));
    final puzzle = batch.puzzles.firstOrNull;
    if (puzzle == null) return null;
    return PuzzleContext(
      puzzle: puzzle,
      angle: angle,
      userId: authUser?.user.id,
      glicko: batch.glicko,
      rounds: batch.rounds,
    );
  }
}, name: 'NextPuzzleProvider');

/// Fetches the list of puzzles to replay for the given number of [days] and [theme].
final puzzleReplayProvider = FutureProvider.autoDispose
    .family<PuzzleContext?, ({int days, String theme})>((
      Ref ref,
      ({int days, String theme}) params,
    ) async {
      final authUser = ref.watch(authControllerProvider);
      if (authUser == null) return null;
      final repo = ref.read(puzzleRepositoryProvider);
      final remaining = await repo.puzzleReplay(params.days, params.theme);
      if (remaining.isEmpty) return null;
      final puzzle = await repo.fetch(remaining.first);
      return PuzzleContext(
        puzzle: puzzle,
        angle: const PuzzleTheme(PuzzleThemeKey.mix),
        userId: authUser.user.id,
        replayRemaining: remaining.removeAt(0),
      );
    }, name: 'PuzzleReplayProvider');

/// Fetches a storm of puzzles.
final stormProvider = FutureProvider.autoDispose<PuzzleStormResponse>((Ref ref) {
  return ref.read(puzzleRepositoryProvider).storm();
}, name: 'StormProvider');

/// Fetches a puzzle from the local storage if available, otherwise fetches it from the server.
final puzzleProvider = FutureProvider.autoDispose.family<Puzzle, PuzzleId>((
  Ref ref,
  PuzzleId id,
) async {
  try {
    final puzzleStorage = await ref
        .watch(puzzleStorageProvider.future)
        .timeout(const Duration(seconds: 3));
    final puzzle = await puzzleStorage.fetch(puzzleId: id);
    if (puzzle != null) return puzzle;
  } catch (_) {
    // Local storage unavailable, fall through to network
  }
  return ref.read(puzzleRepositoryProvider).fetch(id);
}, name: 'PuzzleProvider');

/// Fetches the daily puzzle.
final dailyPuzzleProvider = FutureProvider.autoDispose<Puzzle>((Ref ref) {
  return ref.withClientCacheFor(
    (client) => PuzzleRepository(client).daily(),
    const Duration(hours: 6),
  );
}, name: 'DailyPuzzleProvider');

/// Fetches all saved puzzle batches for the current user.
final savedBatchesProvider = FutureProvider.autoDispose<IList<(PuzzleAngle, int)>>((Ref ref) async {
  final authUser = ref.watch(authControllerProvider);
  try {
    final storage = await ref
        .watch(puzzleBatchStorageProvider.future)
        .timeout(const Duration(seconds: 3));
    return storage.fetchAll(userId: authUser?.user.id);
  } catch (_) {
    return const IList.empty();
  }
}, name: 'SavedBatchesProvider');

/// Fetches saved puzzle theme batches for the current user.
final savedThemeBatchesProvider = FutureProvider.autoDispose<IMap<PuzzleThemeKey, int>>((
  Ref ref,
) async {
  final authUser = ref.watch(authControllerProvider);
  try {
    final storage = await ref
        .watch(puzzleBatchStorageProvider.future)
        .timeout(const Duration(seconds: 3));
    return storage.fetchSavedThemes(userId: authUser?.user.id);
  } catch (_) {
    return IMap(const {});
  }
}, name: 'SavedThemeBatchesProvider');

/// Fetches saved puzzle opening batches for the current user.
final savedOpeningBatchesProvider = FutureProvider.autoDispose<IMap<String, int>>((Ref ref) async {
  final authUser = ref.watch(authControllerProvider);
  try {
    final storage = await ref
        .watch(puzzleBatchStorageProvider.future)
        .timeout(const Duration(seconds: 3));
    return storage.fetchSavedOpenings(userId: authUser?.user.id);
  } catch (_) {
    return IMap(const {});
  }
}, name: 'SavedOpeningBatchesProvider');

/// Fetches the puzzle dashboard for the current user for the given number of [days].
final puzzleDashboardProvider = FutureProvider.autoDispose.family<PuzzleDashboard?, int>((
  Ref ref,
  int days,
) async {
  final authUser = ref.watch(authControllerProvider);
  if (authUser == null) return null;
  try {
    return await ref.watch(puzzleRepositoryProvider).puzzleDashboard(days);
  } catch (_) {
    return null;
  }
}, name: 'PuzzleDashboardProvider');

/// Fetches recent puzzle activity for the current user.
final puzzleRecentActivityProvider = FutureProvider.autoDispose<IList<PuzzleHistoryEntry>?>((
  Ref ref,
) {
  final authUser = ref.watch(authControllerProvider);
  if (authUser == null) return null;
  return ref.watch(puzzleRepositoryProvider).puzzleActivity(20);
}, name: 'PuzzleRecentActivityProvider');

/// Fetches the storm dashboard for a given user [UserId].
final stormDashboardProvider = FutureProvider.autoDispose.family<StormDashboard?, UserId>((
  Ref ref,
  UserId id,
) {
  return ref.read(puzzleRepositoryProvider).stormDashboard(id);
}, name: 'StormDashboardProvider');

/// Fetches available puzzle themes.
final puzzleThemesProvider = FutureProvider.autoDispose<IMap<PuzzleThemeKey, PuzzleThemeData>>((
  Ref ref,
) {
  return ref.withClientCacheFor(
    (client) => PuzzleRepository(client).puzzleThemes(),
    const Duration(days: 1),
  );
}, name: 'PuzzleThemesProvider');

/// Fetches available puzzle openings.
final puzzleOpeningsProvider = FutureProvider.autoDispose
    .family<IList<PuzzleOpeningFamily>, PuzzleOpeningSort>((Ref ref, PuzzleOpeningSort sort) {
      return ref.withClientCacheFor(
        (client) => PuzzleRepository(
          client,
        ).puzzleOpenings(alphabetical: sort == PuzzleOpeningSort.alphabetical),
        const Duration(days: 1),
      );
    }, name: 'PuzzleOpeningsProvider');
