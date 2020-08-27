class Item {
  int id;
  int quantity;

  Item(this.id, this.quantity);
}

class Offer {
  List<Item> sellItems;
  List<Item> buyItems;
  int volume;

  Offer(this.sellItems, this.buyItems, this.volume);
}
