class Utils {
  static bool isInteger(dynamic target) =>
      int.tryParse(target.toString()) != null;

  /// Takes a raw route and supplants parameters into it to obtain a complete URL
  static String parseRoute(
    String route, {
    Map<String, dynamic> parameters = const {},
  }) {
    parameters.forEach((key, value) {
      route = route.replaceAll('%$key%', value);
    });
    return route;
  }
}
