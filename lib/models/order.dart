import 'item.dart';

/// A customer order on the orders board, e.g. "2 bread + 1 popcorn".
class Order {
  Order({
    required this.items,
    required this.coins,
    required this.xp,
    this.gems = 0,
    this.customer = 0,
    this.readyAtMs = 0,
  });

  final Map<Item, int> items;
  final int coins;
  final int xp;
  final int gems;

  /// Which customer face/name to show.
  final int customer;

  /// After skipping, a new order only shows up at this time.
  final int readyAtMs;

  bool isWaiting(int nowMs) => readyAtMs > nowMs;

  Map<String, dynamic> toJson() => {
    'items': {for (final e in items.entries) e.key.name: e.value},
    'coins': coins,
    'xp': xp,
    'gems': gems,
    'customer': customer,
    'readyAt': readyAtMs,
  };

  static Order? fromJson(Object? json) {
    if (json is! Map) return null;
    final raw = json['items'];
    if (raw is! Map) return null;
    final items = <Item, int>{};
    for (final e in raw.entries) {
      final item = Item.values.asNameMap()[e.key];
      final n = e.value;
      if (item != null && n is int && n > 0) items[item] = n;
    }
    final coins = json['coins'];
    final xp = json['xp'];
    if (items.isEmpty || coins is! int || xp is! int) return null;
    final gems = json['gems'];
    final customer = json['customer'];
    final readyAt = json['readyAt'];
    return Order(
      items: items,
      coins: coins,
      xp: xp,
      gems: gems is int ? gems : 0,
      customer: customer is int ? customer : 0,
      readyAtMs: readyAt is int ? readyAt : 0,
    );
  }
}

/// A daily goal with its progress.
class Goal {
  Goal(this.defIndex, {this.progress = 0, this.claimed = false});

  /// Index into GameConfig.goals.
  final int defIndex;
  int progress;
  bool claimed;

  Map<String, dynamic> toJson() => {'d': defIndex, 'p': progress, 'c': claimed};
}
