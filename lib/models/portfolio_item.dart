import 'package:crypto_portfolio_tracker/services/api_service.dart';
import 'package:equatable/equatable.dart';

class PortfolioItem extends Equatable {
  final String coinId;
  final String symbol;
  final String name;
  final double quantity;
  final double? currentPrice;
  final double? change24h;
  final DateTime? lastUpdated;
  final DateTime addedDate;

  PortfolioItem({
    required this.coinId,
    required this.symbol,
    required this.name,
    required this.quantity,
    this.currentPrice,
    this.change24h,
    this.lastUpdated,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? _DefaultDateTime();

  double get totalValue {
    if (currentPrice == null) return 0.0;
    return quantity * currentPrice!;
  }

  bool get hasValidPrice => currentPrice != null && currentPrice! > 0;

  bool get isPositiveChange => change24h != null && change24h! > 0;

  bool get isNegativeChange => change24h != null && change24h! < 0;

  String get displaySymbol => symbol.toUpperCase();

  String get initials {
    if (symbol.length >= 2) {
      return symbol.substring(0, 2).toUpperCase();
    }
    return symbol.toUpperCase();
  }

  PortfolioItem copyWith({
    String? coinId,
    String? symbol,
    String? name,
    double? quantity,
    double? currentPrice,
    double? change24h,
    DateTime? lastUpdated,
    DateTime? addedDate,
  }) {
    return PortfolioItem(
      coinId: coinId ?? this.coinId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  PortfolioItem updateWithPriceData(PriceData priceData) {
    return copyWith(
      currentPrice: priceData.price,
      change24h: priceData.change24h,
      lastUpdated: priceData.lastUpdated ?? DateTime.now(),
    );
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      coinId: json['coinId'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
      change24h: json['change24h'] != null
          ? (json['change24h'] as num).toDouble()
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
      addedDate: json['addedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['addedDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coinId': coinId,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'currentPrice': currentPrice,
      'change24h': change24h,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'addedDate': addedDate.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        coinId,
        symbol,
        name,
        quantity,
        currentPrice,
        change24h,
        lastUpdated,
        addedDate,
      ];

  @override
  String toString() =>
      'PortfolioItem(coinId: $coinId, quantity: $quantity, value: $totalValue)';
}

class _DefaultDateTime extends DateTime {
  _DefaultDateTime() : super.now();
}
