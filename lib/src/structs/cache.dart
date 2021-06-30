import 'package:puppeteer/puppeteer.dart';

class CachedPage {
  final Page page;

  /// Whether this page is already being controlled
  bool isLocked = false;

  CachedPage(this.page);

  /// Lock this page, indicating it is already in use
  void lock() => isLocked = true;

  /// Unlock this page, indicating it is free for use
  void unlock() => isLocked = false;
}
