import 'dart:io';
import 'dart:convert';

class Utils {
  static Future<dynamic> parseJson(String fileName) async {
    var jsonData = await File(fileName).readAsString();
    return json.decode(jsonData);
  }

  static bool isInteger(dynamic target) {
    if (target == null) return false;
    return int.parse(target, radix: 10, onError: (e) => null) != null;
  }

  static bool listEqual(dynamic first, dynamic second) {
    if (!(first is List && second is List) ||
        (first.runtimeType != second.runtimeType) ||
        (first.length != second.length)) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }

    return true;
  }

  static String supplantArgsSelector(dynamic target, int index) {
    return target.toString().replaceFirst('%index%', (index + 1).toString());
  }

  static String supplantArgsJS(dynamic target, int index) {
    return target.toString().replaceFirst('%index%', index.toString());
  }
}
