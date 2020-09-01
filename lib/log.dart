import 'package:ansicolor/ansicolor.dart';
import 'package:intl/intl.dart';
import 'package:reDart/structs.dart';

enum Severity { Debug, Info, Warning, Error }

bool _isDebug = false;
final timeFormat = DateFormat.Hms();

void initLog(bool isDebug) async {
  _isDebug = isDebug;
}

void log(Severity severity, String message) async {
  AnsiPen pen;

  switch (severity) {
    case Severity.Debug:
      if (severity == Severity.Debug && !_isDebug) return;
      pen = AnsiPen()..gray();
      break;
    case Severity.Info:
      pen = AnsiPen()..white();
      break;
    case Severity.Warning:
      pen = AnsiPen()..yellow();
      break;
    case Severity.Error:
      pen = AnsiPen()
        ..red()
        ..yellow();
      break;
  }

  var time = timeFormat.format(DateTime.now());
  print('<$time> - ${pen(message)}');
}

void logOffer(Map<dynamic, dynamic> idToName, String index, Offer offer) {
  var sellItems = (offer.sellItems
      .map((value) => {'${value.quantity}x ${idToName[value.id]}'})).join(', ');
  var buyItems = (offer.buyItems
      .map((value) => {'${value.quantity}x ${idToName[value.id]}'})).join(', ');
  log(Severity.Info,
      '$index: ${offer.volume}x Selling $sellItems for $buyItems');
}

void throwError(String message) {
  log(Severity.Error, message);
}
