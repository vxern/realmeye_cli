import 'package:reDart/utils.dart';

class Item {
  final int id;
  final int quantity;

  const Item(this.id, this.quantity);

  @override
  bool operator ==(Object other) =>
      other is Item && other.id == id && other.quantity == quantity;
}

class Offer {
  List<Item> sellItems;
  List<Item> buyItems;
  int volume;

  Offer(this.sellItems, this.buyItems, this.volume);

  @override
  bool operator ==(Object other) =>
      other is Offer &&
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

enum Instruction { Buy, Sell }
