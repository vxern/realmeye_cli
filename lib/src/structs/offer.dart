import 'package:realmeye_cli/src/structs/item.dart';

/// Data structure for an offer
class Offer {
  /// Items being sold
  final List<ItemListing> sell;

  /// Items being bought
  final List<ItemListing> buy;

  /// How many times this trade can be executed
  final int volume;

  /// Indicates whether this offer is active or on hold
  final OfferStatus offerStatus;

  const Offer(this.sell, this.buy, this.volume, this.offerStatus);
}

/// Represents an offer listing in a table of offers
class OfferListing {
  /// The offer represented by this listing
  final Offer offer;

  /// Index / position of the offer in table
  final int position;

  const OfferListing(this.offer, this.position);
}

/// Listing status of offer
enum OfferStatus { active, suspended }
