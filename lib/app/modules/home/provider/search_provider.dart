import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/search_model.dart';
import '../../../data/services/search_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Represents the current state of the search screen.
class SearchState {
  final String query;
  final bool isLoading;
  final SearchResult? result;
  final String? error;
  /// Filter: 'all' | 'shops' | 'products'
  final String activeFilter;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.result,
    this.error,
    this.activeFilter = 'all',
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    SearchResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
    String? activeFilter,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  bool get hasResults => result != null && !result!.isEmpty;
  bool get hasSearched => query.isNotEmpty;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return const SearchState();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final result = await ref.read(searchServiceProvider).search(query);
      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});
