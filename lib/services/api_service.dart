import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const Duration _timeout = Duration(seconds: 300);

  final http.Client _client = http.Client();

  Future<List<Map<String, dynamic>>> fetchCoinsList() async {
    try {
      final uri = Uri.parse('$_baseUrl/coins/list');
      log('GET Request -> URL: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'accept': 'application/json',
          'User-Agent': 'CryptoPortfolioTracker/1.0',
        },
      ).timeout(_timeout);

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log('Successfully fetched ${data.length} coins');
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 429) {
        throw ApiException('Rate limit exceeded. Please try again later.');
      } else {
        throw ApiException(
            'Failed to fetch coins list. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error fetching coins list: $e', stackTrace: stackTrace);
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to load cryptocurrency data. Please try again.');
    }
  }

  Future<Map<String, PriceData>> fetchPricesWithDetails(
      List<String> coinIds) async {
    if (coinIds.isEmpty) return {};

    try {
      final idsParam = coinIds.join(',');
      final uri = Uri.parse(
          '$_baseUrl/simple/price?ids=$idsParam&vs_currencies=usd&include_24hr_change=true&include_last_updated_at=true');
      log('GET Request -> URL: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'accept': 'application/json',
          'User-Agent': 'CryptoPortfolioTracker/1.0',
        },
      ).timeout(_timeout);

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, PriceData> prices = {};
        data.forEach((coinId, coinData) {
          if (coinData is Map<String, dynamic>) {
            prices[coinId] = PriceData.fromJson(coinData);
          }
        });
        log('Successfully fetched prices for ${prices.length} coins');
        return prices;
      } else if (response.statusCode == 429) {
        throw ApiException('Rate limit exceeded. Please try again later.');
      } else {
        throw ApiException(
            'Failed to fetch prices. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log('Error fetching prices: $e', stackTrace: stackTrace);
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load current prices. Please try again.');
    }
  }

  Future<Map<String, double>> fetchPrices(List<String> coinIds) async {
    final pricesWithDetails = await fetchPricesWithDetails(coinIds);
    return pricesWithDetails.map((key, value) => MapEntry(key, value.price));
  }

  void dispose() {
    _client.close();
  }
}

class PriceData {
  final double price;
  final double? change24h;
  final DateTime? lastUpdated;

  PriceData({
    required this.price,
    this.change24h,
    this.lastUpdated,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) {
    final usdValue = json['usd'];
    final usdChange = json['usd_24h_change'];
    final lastUpdatedUnix = json['last_updated_at'];

    return PriceData(
      price: usdValue != null ? (usdValue as num).toDouble() : 0.0,
      change24h: usdChange != null ? (usdChange as num).toDouble() : null,
      lastUpdated: (lastUpdatedUnix != null && lastUpdatedUnix > 0)
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdatedUnix * 1000)
          : null,
    );
  }

  bool get isPositiveChange => change24h != null && change24h! > 0;

  bool get isNegativeChange => change24h != null && change24h! < 0;
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
