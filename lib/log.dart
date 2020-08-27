import 'package:ansicolor/ansicolor.dart';
import 'package:intl/intl.dart';

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
