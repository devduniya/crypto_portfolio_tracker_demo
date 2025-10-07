import 'package:equatable/equatable.dart';

class Coin extends Equatable {
  final String id;
  final String symbol;
  final String name;

  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
    };
  }

  String get displayName => '$name (${symbol.toUpperCase()})';

  String get initials {
    if (symbol.length >= 2) {
      return symbol.substring(0, 2).toUpperCase();
    }
    return symbol.toUpperCase();
  }

  @override
  List<Object?> get props => [id, symbol, name];

  @override
  String toString() => 'Coin(id: $id, symbol: $symbol, name: $name)';
}
