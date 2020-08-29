import 'package:reDart/utils.dart';
import 'package:reDart/structs.dart';
import 'package:reDart/log.dart';

class Parser {
  static Future<List<OfferToResolve>> parseListings(String arguments) async {
    // Constants for parsing
    const keyBracketOpen = '{';
    const keyBracketClosed = '}';
    const valueBracketOpen = '[';
    const valueBracketClosed = ']';
    const valueSplitter = ',';

    arguments = arguments + ' ';
    // Preliminary checks
    if (keyBracketOpen.allMatches(arguments).length !=
            keyBracketClosed.allMatches(arguments).length ||
        (keyBracketOpen.allMatches(arguments).isEmpty ||
            keyBracketClosed.allMatches(arguments).isEmpty)) {
      throwError("Your listing is missing one of the key brackets '\{\}'.\r\n"
          'Original string: $arguments');
      return null;
    } else if (!arguments.contains(RegExp('(buy.*sell|sell.*buy)'))) {
      throwError("Your listing is missing a 'buy' or 'sell' argument.\r\n"
          'Original string: $arguments');
      return null;
    } else if ('buy'.allMatches(arguments).length !=
        'sell'.allMatches(arguments).length) {
      throwError("Your listing is missing a 'buy' or 'sell' argument.\r\n"
          'Original string: $arguments');
      return null;
    } else if (valueBracketOpen.allMatches(arguments).length !=
            valueBracketClosed.allMatches(arguments).length ||
        (valueBracketOpen.allMatches(arguments).isEmpty ||
            valueBracketClosed.allMatches(arguments).isEmpty)) {
      throwError("Your listing is missing one of the value brackets '\[\]'.\r\n"
          'Original string: $arguments');
      return null;
    }

    // Final result
    var offersToResolve = <OfferToResolve>[];

    // Control of parsing
    var parsingListing = false;
    var parsingBuy = false;
    var parsingSell = false;
    var parsingArgs = false;

    // Checking
    var nextChar = '';
    var currChar = '';

    // Collection of arguments
    var buffer = '';

    // Collection of read arguments
    var listingCollector = OfferToResolve();
    var itemCollector = ItemToResolve();
    for (var i = 0; i < arguments.length - 1; i++) {
      nextChar = arguments[i + 1];
      currChar = arguments[i];

      if (currChar == ' ') {
        continue;
      }

      // Expect '{' to be the first character
      if (!parsingListing && currChar != keyBracketOpen) {
        throwError(
            'Expected $keyBracketOpen at position $i but found $buffer instead.\r\n'
            'Original string: $arguments');
        return null;
      }

      if (parsingBuy || parsingSell) {
        switch (buffer) {
          case valueBracketOpen:
            parsingArgs = true;
            buffer = '';
            break;
          case valueBracketClosed:
            buffer = '';
            if (itemCollector.keyword == '') {
              throwError('You must supply an item name.\r\n'
                  'Original string: $arguments');
              return null;
            }
            itemCollector.quantity ??= 1;
            parsingBuy == true
                ? listingCollector.buyItems.add(itemCollector)
                : listingCollector.sellItems.add(itemCollector);
            parsingArgs = false;
            parsingBuy == true ? parsingBuy = false : parsingSell = false;
            itemCollector = ItemToResolve();
            break;
          case valueSplitter:
            buffer = '';
            if (itemCollector.keyword == '') {
              throwError('You must supply an item name.\r\n'
                  'Original string: $arguments');
              return null;
            }
            itemCollector.quantity ??= 1;
            parsingBuy == true
                ? listingCollector.buyItems.add(itemCollector)
                : listingCollector.sellItems.add(itemCollector);
            itemCollector = ItemToResolve();
            break;
          default:
            if (buffer != ' ' && !parsingArgs) {
              buffer += currChar;
            }
            break;
        }
      }

      if (parsingArgs) {
        switch (nextChar) {
          case valueSplitter:
          case valueBracketClosed:
            buffer += currChar;
            if (Utils.isInteger(buffer)) {
              if (itemCollector.keyword.isEmpty) {
                throwError(
                    'A quantity was supplied but no item name in a buy section.\r\n'
                    'Original string: $arguments');
                return null;
              }
              itemCollector.quantity = int.parse(buffer);
              buffer = '';
            } else {
              itemCollector.keyword = buffer;
              buffer = '';
            }
            break;
          default:
            buffer += currChar;
            if (!Utils.isInteger(currChar) && Utils.isInteger(nextChar)) {
              itemCollector.keyword = buffer;
              buffer = '';
            }
            break;
        }
      }

      switch (currChar) {
        case keyBracketOpen:
          parsingListing = true;
          break;
        case keyBracketClosed:
          if (listingCollector.buyItems.isEmpty ||
              listingCollector.sellItems.isEmpty) {
            throwError(
                'No item names have been provided in one of the buy / sell sections.\r\n'
                'Original string: $arguments');
            return null;
          }
          listingCollector.volume ??= 1;
          offersToResolve.add(listingCollector);
          listingCollector = OfferToResolve();
          parsingListing = false;
          break;
        default:
          // If the parser is parsing the 'buy' or 'sell' section, do not collect to buffer here
          if (!parsingBuy && !parsingSell) {
            buffer += currChar;
            switch (buffer) {
              case 'buy:':
              case 'buy':
                parsingBuy = true;
                buffer = '';
                break;

              case 'sell:':
              case 'sell':
                parsingSell = true;
                buffer = '';
                break;
            }
          }
          break;
      }
    }

    return offersToResolve;
  }
}
