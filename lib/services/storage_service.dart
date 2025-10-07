import 'dart:convert';
import 'dart:developer';

import 'package:crypto_portfolio_tracker/models/coin.dart';
import 'package:crypto_portfolio_tracker/models/portfolio_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _coinsListKey = 'coins_list_v2';
  static const String _portfolioKey = 'portfolio_v2';
  static const String _lastFetchKey = 'last_fetch_coins';
  static const String _priceHistoryKey = 'price_history';

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveCoinsList(List<Coin> coins) async {
    try {
      await _ensureInitialized();
      final coinsJson = coins.map((coin) => coin.toJson()).toList();
      final jsonString = jsonEncode(coinsJson);

      await _prefs!.setString(_coinsListKey, jsonString);
      await _prefs!
          .setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);

      log('Saved ${coins.length} coins to local storage');
    } catch (e) {
      log('Error saving coins list: $e');
      throw StorageException('Failed to save coins data');
    }
  }

  Future<List<Coin>?> getCoinsList() async {
    try {
      await _ensureInitialized();
      final coinsString = _prefs!.getString(_coinsListKey);

      if (coinsString == null || coinsString.isEmpty) {
        log('No cached coins list found');
        return null;
      }

      final List<dynamic> coinsJson = jsonDecode(coinsString);
      final coins = coinsJson.map((json) => Coin.fromJson(json)).toList();

      log('Loaded ${coins.length} coins from local storage');
      return coins;
    } catch (e) {
      log('Error loading coins list: $e');
      return null;
    }
  }

  Future<bool> shouldRefreshCoinsList() async {
    try {
      await _ensureInitialized();
      final lastFetch = _prefs!.getInt(_lastFetchKey);

      if (lastFetch == null) {
        log('No previous fetch timestamp found');
        return true;
      }

      final lastFetchDate = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final daysSinceLastFetch =
          DateTime.now().difference(lastFetchDate).inDays;

      log('Days since last fetch: $daysSinceLastFetch');
      return daysSinceLastFetch >= 7;
    } catch (e) {
      log('Error checking refresh status: $e');
      return true;
    }
  }

  Future<void> savePortfolio(List<PortfolioItem> portfolio) async {
    try {
      await _ensureInitialized();
      final portfolioJson = portfolio.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(portfolioJson);

      await _prefs!.setString(_portfolioKey, jsonString);

      log('Saved portfolio with ${portfolio.length} items');
    } catch (e) {
      log('Error saving portfolio: $e');
      throw StorageException('Failed to save portfolio data');
    }
  }

  Future<List<PortfolioItem>> getPortfolio() async {
    try {
      await _ensureInitialized();
      final portfolioString = _prefs!.getString(_portfolioKey);

      if (portfolioString == null || portfolioString.isEmpty) {
        log('No cached portfolio found');
        return [];
      }

      final List<dynamic> portfolioJson = jsonDecode(portfolioString);
      final portfolio =
          portfolioJson.map((json) => PortfolioItem.fromJson(json)).toList();

      log('Loaded portfolio with ${portfolio.length} items');
      return portfolio;
    } catch (e) {
      log('Error loading portfolio: $e');
      return [];
    }
  }

  Future<void> savePriceHistory(String coinId, double price) async {
    try {
      await _ensureInitialized();
      final historyString = _prefs!.getString(_priceHistoryKey) ?? '{}';
      final Map<String, dynamic> history = jsonDecode(historyString);

      final coinHistory =
          List<Map<String, dynamic>>.from(history[coinId] ?? []);

      coinHistory.add({
        'price': price,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (coinHistory.length > 10) {
        coinHistory.removeAt(0);
      }

      history[coinId] = coinHistory;
      await _prefs!.setString(_priceHistoryKey, jsonEncode(history));
    } catch (e) {
      log('Error saving price history: $e');
    }
  }

  Future<List<PriceHistoryPoint>> getPriceHistory(String coinId) async {
    try {
      await _ensureInitialized();
      final historyString = _prefs!.getString(_priceHistoryKey) ?? '{}';
      final Map<String, dynamic> history = jsonDecode(historyString);

      final coinHistory =
          List<Map<String, dynamic>>.from(history[coinId] ?? []);

      return coinHistory
          .map((point) => PriceHistoryPoint(
                price: (point['price'] as num).toDouble(),
                timestamp:
                    DateTime.fromMillisecondsSinceEpoch(point['timestamp']),
              ))
          .toList();
    } catch (e) {
      log('Error loading price history: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _prefs!.clear();
      log('Cleared all stored data');
    } catch (e) {
      log('Error clearing storage: $e');
      throw StorageException('Failed to clear data');
    }
  }

  Future<void> removePortfolioItem(String coinId) async {
    try {
      final portfolio = await getPortfolio();
      portfolio.removeWhere((item) => item.coinId == coinId);
      await savePortfolio(portfolio);
      log('Removed portfolio item: $coinId');
    } catch (e) {
      log('Error removing portfolio item: $e');
      throw StorageException('Failed to remove portfolio item');
    }
  }
}

class PriceHistoryPoint {
  final double price;
  final DateTime timestamp;

  PriceHistoryPoint({
    required this.price,
    required this.timestamp,
  });
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
