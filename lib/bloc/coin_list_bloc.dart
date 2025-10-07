import 'dart:async';
import 'dart:developer';

import 'package:crypto_portfolio_tracker/models/coin.dart';
import 'package:crypto_portfolio_tracker/services/api_service.dart';
import 'package:crypto_portfolio_tracker/services/storage_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CoinListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCoinListEvent extends CoinListEvent {}

class RefreshCoinListEvent extends CoinListEvent {}

class SearchCoinsEvent extends CoinListEvent {
  final String query;

  SearchCoinsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends CoinListEvent {}

abstract class CoinListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CoinListInitial extends CoinListState {}

class CoinListLoading extends CoinListState {
  final bool isRefreshing;

  CoinListLoading({this.isRefreshing = false});

  @override
  List<Object?> get props => [isRefreshing];
}

class CoinListLoaded extends CoinListState {
  final List<Coin> allCoins;
  final List<Coin> filteredCoins;
  final Map<String, Coin> coinMap;
  final String searchQuery;
  final bool isSearching;

  CoinListLoaded({
    required this.allCoins,
    List<Coin>? filteredCoins,
    this.searchQuery = '',
    this.isSearching = false,
  })  : filteredCoins = filteredCoins ?? allCoins,
        coinMap = _createOptimizedMap(allCoins);

  static Map<String, Coin> _createOptimizedMap(List<Coin> coins) {
    final Map<String, Coin> map = {};

    for (Coin coin in coins) {
      map[coin.id] = coin;
      map[coin.symbol.toLowerCase()] = coin;
      map[coin.name.toLowerCase()] = coin;

      final words = coin.name.toLowerCase().split(' ');
      for (String word in words) {
        if (word.isNotEmpty) {
          map[word] = coin;
        }
      }
    }

    return map;
  }

  List<Coin> searchCoins(String query) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final Set<Coin> results = {};

    for (Coin coin in allCoins) {
      final score = _calculateSearchScore(coin, queryLower);
      if (score > 0) {
        results.add(coin);
      }

      if (results.length >= 50) break;
    }

    final resultList = results.toList();
    resultList.sort((a, b) => _calculateSearchScore(b, queryLower)
        .compareTo(_calculateSearchScore(a, queryLower)));

    return resultList;
  }

  int _calculateSearchScore(Coin coin, String query) {
    int score = 0;
    final nameLower = coin.name.toLowerCase();
    final symbolLower = coin.symbol.toLowerCase();
    final idLower = coin.id.toLowerCase();

    if (symbolLower == query) score += 100;
    if (idLower == query) score += 90;
    if (nameLower == query) score += 80;

    if (symbolLower.startsWith(query)) score += 70;
    if (idLower.startsWith(query)) score += 60;
    if (nameLower.startsWith(query)) score += 50;

    if (symbolLower.contains(query)) score += 30;
    if (idLower.contains(query)) score += 20;
    if (nameLower.contains(query)) score += 10;

    final words = nameLower.split(' ');
    for (String word in words) {
      if (word.startsWith(query)) score += 40;
      if (word.contains(query)) score += 15;
    }

    return score;
  }

  Coin? findCoinById(String id) => coinMap[id];

  Coin? findCoinBySymbol(String symbol) => coinMap[symbol.toLowerCase()];

  CoinListLoaded copyWith({
    List<Coin>? allCoins,
    List<Coin>? filteredCoins,
    String? searchQuery,
    bool? isSearching,
  }) {
    return CoinListLoaded(
      allCoins: allCoins ?? this.allCoins,
      filteredCoins: filteredCoins ?? this.filteredCoins,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props =>
      [allCoins, filteredCoins, searchQuery, isSearching];
}

class CoinListError extends CoinListState {
  final String message;
  final bool canRetry;

  CoinListError(this.message, {this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

class CoinListBloc extends Bloc<CoinListEvent, CoinListState> {
  final ApiService _apiService;
  final StorageService _storageService;
  Timer? _searchDebounceTimer;

  CoinListBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(CoinListInitial()) {
    on<LoadCoinListEvent>(_onLoadCoinList);
    on<RefreshCoinListEvent>(_onRefreshCoinList);
    on<SearchCoinsEvent>(_onSearchCoins,
        transformer: _debounce(const Duration(milliseconds: 300)));
    on<ClearSearchEvent>(_onClearSearch);
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }

  EventTransformer<T> _debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  Future<void> _onLoadCoinList(
    LoadCoinListEvent event,
    Emitter<CoinListState> emit,
  ) async {
    try {
      emit(CoinListLoading());

      final cachedCoins = await _storageService.getCoinsList();
      final shouldRefresh = await _storageService.shouldRefreshCoinsList();

      if (cachedCoins != null && cachedCoins.isNotEmpty && !shouldRefresh) {
        emit(CoinListLoaded(allCoins: cachedCoins));
        return;
      }

      if (cachedCoins != null && cachedCoins.isNotEmpty) {
        emit(CoinListLoaded(allCoins: cachedCoins));
      }

      final coinsData = await _apiService.fetchCoinsList();
      final coins = coinsData.map((data) => Coin.fromJson(data)).toList();

      await _storageService.saveCoinsList(coins);

      emit(CoinListLoaded(allCoins: coins));
    } catch (e) {

      final cachedCoins = await _storageService.getCoinsList();
      if (cachedCoins != null && cachedCoins.isNotEmpty) {
        emit(CoinListLoaded(allCoins: cachedCoins));
      } else {
        emit(CoinListError(
            'Failed to load cryptocurrency data: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRefreshCoinList(
    RefreshCoinListEvent event,
    Emitter<CoinListState> emit,
  ) async {
    final currentState = state;

    try {
      if (currentState is CoinListLoaded) {
        emit(CoinListLoading(isRefreshing: true));
      } else {
        emit(CoinListLoading());
      }

      final coinsData = await _apiService.fetchCoinsList();
      final coins = coinsData.map((data) => Coin.fromJson(data)).toList();

      await _storageService.saveCoinsList(coins);

      emit(CoinListLoaded(allCoins: coins));
    } catch (e) {

      if (currentState is CoinListLoaded) {
        emit(currentState);
      } else {
        emit(CoinListError(
            'Failed to refresh cryptocurrency data: ${e.toString()}'));
      }
    }
  }

  void _onSearchCoins(
    SearchCoinsEvent event,
    Emitter<CoinListState> emit,
  ) {
    final currentState = state;
    if (currentState is! CoinListLoaded) return;

    final query = event.query.trim();

    if (query.isEmpty) {
      emit(currentState.copyWith(
        filteredCoins: [],
        searchQuery: '',
        isSearching: false,
      ));
      return;
    }

    final searchResults = currentState.searchCoins(query);

    emit(currentState.copyWith(
      filteredCoins: searchResults,
      searchQuery: query,
      isSearching: false,
    ));
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<CoinListState> emit,
  ) {
    final currentState = state;
    if (currentState is! CoinListLoaded) return;

    emit(currentState.copyWith(
      filteredCoins: [],
      searchQuery: '',
      isSearching: false,
    ));
  }
}
