/// Data structure for a RealmEye representation of ingame items
class Item {
  /// Identifier of the item on RealmEye
  final int id;

  /// Name of the item
  final String name;

  const Item(this.id, this.name);
}

/// Item with a quantity included alongisde it
class ItemListing {
  /// The item included in the listing
  final Item item;

  /// How many pieces are involved in the listing
  final int quantity;

  const ItemListing(this.item, this.quantity);
}
