import 'dart:async';
import 'dart:developer';

import 'package:crypto_portfolio_tracker/models/portfolio_item.dart';
import 'package:crypto_portfolio_tracker/services/api_service.dart';
import 'package:crypto_portfolio_tracker/services/storage_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PortfolioEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPortfolioEvent extends PortfolioEvent {}

class AddPortfolioItemEvent extends PortfolioEvent {
  final PortfolioItem item;

  AddPortfolioItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdatePortfolioItemEvent extends PortfolioEvent {
  final String coinId;
  final double quantity;

  UpdatePortfolioItemEvent({required this.coinId, required this.quantity});

  @override
  List<Object?> get props => [coinId, quantity];
}

class RemovePortfolioItemEvent extends PortfolioEvent {
  final String coinId;

  RemovePortfolioItemEvent(this.coinId);

  @override
  List<Object?> get props => [coinId];
}

class RefreshPricesEvent extends PortfolioEvent {}

class StartPeriodicUpdatesEvent extends PortfolioEvent {}

class StopPeriodicUpdatesEvent extends PortfolioEvent {}

class SortPortfolioEvent extends PortfolioEvent {
  final PortfolioSortType sortType;

  SortPortfolioEvent(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

enum PortfolioSortType {
  name,
  symbol,
  value,
  quantity,
  change24h,
  addedDate,
}

abstract class PortfolioState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioItem> items;
  final bool isRefreshing;
  final PortfolioSortType sortType;
  final DateTime lastUpdated;
  final String? errorMessage;

  PortfolioLoaded({
    required this.items,
    this.isRefreshing = false,
    this.sortType = PortfolioSortType.addedDate,
    DateTime? lastUpdated,
    this.errorMessage,
  }) : lastUpdated = lastUpdated ?? _DefaultDateTime();

  double get totalValue {
    return items.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  double get totalChange24h {
    return items.fold(0.0, (sum, item) {
      if (item.change24h != null && item.currentPrice != null) {
        final previousPrice =
            item.currentPrice! / (1 + (item.change24h! / 100));
        final changeValue =
            (item.currentPrice! - previousPrice) * item.quantity;
        return sum + changeValue;
      }
      return sum;
    });
  }

  double get totalChange24hPercentage {
    if (totalValue == 0) return 0.0;
    final previousValue = totalValue - totalChange24h;
    if (previousValue == 0) return 0.0;
    return (totalChange24h / previousValue) * 100;
  }

  bool get hasItems => items.isNotEmpty;

  bool get hasValidPrices => items.any((item) => item.hasValidPrice);

  List<PortfolioItem> get sortedItems {
    final sortedList = List<PortfolioItem>.from(items);

    switch (sortType) {
      case PortfolioSortType.name:
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PortfolioSortType.symbol:
        sortedList.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case PortfolioSortType.value:
        sortedList.sort((a, b) => b.totalValue.compareTo(a.totalValue));
        break;
      case PortfolioSortType.quantity:
        sortedList.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case PortfolioSortType.change24h:
        sortedList.sort((a, b) {
          final aChange = a.change24h ?? 0;
          final bChange = b.change24h ?? 0;
          return bChange.compareTo(aChange);
        });
        break;
      case PortfolioSortType.addedDate:
        sortedList.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }

    return sortedList;
  }

  PortfolioLoaded copyWith({
    List<PortfolioItem>? items,
    bool? isRefreshing,
    PortfolioSortType? sortType,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return PortfolioLoaded(
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sortType: sortType ?? this.sortType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [items, isRefreshing, sortType, lastUpdated, errorMessage];
}

class PortfolioError extends PortfolioState {
  final String message;
  final bool canRetry;

  PortfolioError(this.message, {this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final StorageService _storageService;
  final ApiService _apiService;
  Timer? _periodicTimer;

  PortfolioBloc({
    required StorageService storageService,
    required ApiService apiService,
  })  : _storageService = storageService,
        _apiService = apiService,
        super(PortfolioInitial()) {
    on<LoadPortfolioEvent>(_onLoadPortfolio);
    on<AddPortfolioItemEvent>(_onAddPortfolioItem);
    on<UpdatePortfolioItemEvent>(_onUpdatePortfolioItem);
    on<RemovePortfolioItemEvent>(_onRemovePortfolioItem);
    on<RefreshPricesEvent>(_onRefreshPrices);
    on<StartPeriodicUpdatesEvent>(_onStartPeriodicUpdates);
    on<StopPeriodicUpdatesEvent>(_onStopPeriodicUpdates);
    on<SortPortfolioEvent>(_onSortPortfolio);
  }

  @override
  Future<void> close() {
    _periodicTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolioEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      emit(PortfolioLoading());

      final items = await _storageService.getPortfolio();

      emit(PortfolioLoaded(
        items: items,
        lastUpdated: DateTime.now(),
      ));

      if (items.isNotEmpty) {
        add(RefreshPricesEvent());
      } else {
        log('Empty');
      }
    } catch (e) {
      emit(PortfolioError('Failed to load portfolio: ${e.toString()}'));
    }
  }

  Future<void> _onAddPortfolioItem(
    AddPortfolioItemEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    try {
      final items = List<PortfolioItem>.from(currentState.items);

      final existingIndex = items.indexWhere(
        (item) => item.coinId == event.item.coinId,
      );

      if (existingIndex != -1) {
        final existingItem = items[existingIndex];
        final updatedQuantity = existingItem.quantity + event.item.quantity;

        items[existingIndex] = existingItem.copyWith(quantity: updatedQuantity);
      } else {
        items.add(event.item);
      }

      await _storageService.savePortfolio(items);

      emit(currentState.copyWith(
        items: items,
        lastUpdated: DateTime.now(),
      ));

      add(RefreshPricesEvent());
    } catch (e) {
      emit(PortfolioError('Failed to add item: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePortfolioItem(
    UpdatePortfolioItemEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    try {
      log('Updating portfolio item: ${event.coinId} quantity to ${event.quantity}');
      final items = List<PortfolioItem>.from(currentState.items);
      final index = items.indexWhere((item) => item.coinId == event.coinId);

      if (index != -1) {
        if (event.quantity <= 0) {
          items.removeAt(index);
        } else {
          items[index] = items[index].copyWith(quantity: event.quantity);
        }

        await _storageService.savePortfolio(items);

        emit(currentState.copyWith(
          items: items,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      emit(PortfolioError('Failed to update item: ${e.toString()}'));
    }
  }

  Future<void> _onRemovePortfolioItem(
    RemovePortfolioItemEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    try {
      final items = List<PortfolioItem>.from(currentState.items);
      final initialLength = items.length;

      items.removeWhere((item) => item.coinId == event.coinId);

      if (items.length < initialLength) {
        await _storageService.savePortfolio(items);

        emit(currentState.copyWith(
          items: items,
          lastUpdated: DateTime.now(),
        ));

      }
    } catch (e) {
      emit(PortfolioError('Failed to remove item: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshPrices(
    RefreshPricesEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded || currentState.items.isEmpty) {
      return;
    }

    emit(currentState.copyWith(isRefreshing: true));

    try {
      final coinIds = currentState.items.map((item) => item.coinId).toList();

      final pricesWithDetails =
          await _apiService.fetchPricesWithDetails(coinIds);

      final updatedItems = currentState.items.map((item) {
        final priceData = pricesWithDetails[item.coinId];
        if (priceData != null) {
          _storageService.savePriceHistory(item.coinId, priceData.price);
          return item.updateWithPriceData(priceData);
        }
        return item;
      }).toList();

      await _storageService.savePortfolio(updatedItems);

      emit(PortfolioLoaded(
        items: updatedItems,
        isRefreshing: false,
        sortType: currentState.sortType,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      emit(currentState.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh prices: ${e.toString()}',
      ));
    }
  }

  void _onStartPeriodicUpdates(
    StartPeriodicUpdatesEvent event,
    Emitter<PortfolioState> emit,
  ) {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        add(RefreshPricesEvent());
      },
    );
  }

  void _onStopPeriodicUpdates(
    StopPeriodicUpdatesEvent event,
    Emitter<PortfolioState> emit,
  ) {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _onSortPortfolio(
    SortPortfolioEvent event,
    Emitter<PortfolioState> emit,
  ) {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;

    emit(currentState.copyWith(sortType: event.sortType));
  }
}

class _DefaultDateTime extends DateTime {
  _DefaultDateTime() : super.now();
}
