import 'package:reDart/utils.dart';

class Item {
  final int id;
  final int quantity;

  const Item(this.id, this.quantity);

  @override
  bool operator ==(Object other) =>
      other is Item && other.id == id && other.quantity == quantity;
}

// Identical to 'Item' except here the id hasn't been established and it can be cleared.
class ItemToResolve {
  String keyword;
  int quantity;

  ItemToResolve() {
    clear();
  }

  void clear() {
    keyword = '';
    quantity = null;
  }

  @override
  bool operator ==(Object other) =>
      other is ItemToResolve &&
      other.keyword == keyword &&
      other.quantity == quantity;
}

class Offer {
  final List<Item> sellItems;
  final List<Item> buyItems;
  final int volume;

  const Offer(this.sellItems, this.buyItems, this.volume);

  @override
  bool operator ==(Object other) =>
      other is Offer &&
      Utils.listEqual(sellItems, other.sellItems) &&
      Utils.listEqual(buyItems, other.buyItems) &&
      volume == other.volume;
}

class OfferToResolve {
  List<ItemToResolve> sellItems;
  List<ItemToResolve> buyItems;
  int volume;

  OfferToResolve() {
    sellItems = <ItemToResolve>[];
    buyItems = <ItemToResolve>[];
  }

  void clear() {
    sellItems.clear();
    buyItems.clear();
  }

  @override
  bool operator ==(Object other) =>
      other is OfferToResolve &&
      Utils.listEqual(sellItems, other.sellItems) &&
      Utils.listEqual(buyItems, other.buyItems) &&
      volume == other.volume;
}

class ActionSingle {
  final Instruction instruction;
  final Item item;

  const ActionSingle(this.instruction, this.item);

  @override
  bool operator ==(Object other) =>
      other is ActionSingle &&
      instruction == other.instruction &&
      item == other.item;
}

class ActionFull {
  final ActionSingle firstAction;
  final ActionSingle secondAction;

  const ActionFull(this.firstAction, this.secondAction);

  @override
  bool operator ==(Object other) =>
      other is ActionFull &&
      firstAction == other.firstAction &&
      secondAction == other.secondAction;
}

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple(this.item1, this.item2);

  @override
  bool operator ==(Object other) =>
      other is Tuple && other.item1 == item1 && other.item2 == item2;
}

class Tuple3<T1, T2, T3> {
  final T1 item1;
  final T2 item2;
  final T3 item3;

  const Tuple3(this.item1, this.item2, this.item3);

  @override
  bool operator ==(Object other) =>
      other is Tuple3 &&
      other.item1 == item1 &&
      other.item2 == item2 &&
      other.item3 == item3;
}

enum Instruction { Buy, Sell }
