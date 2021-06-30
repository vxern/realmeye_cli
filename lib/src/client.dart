import 'dart:async';

import 'package:puppeteer/puppeteer.dart';
import 'package:sprint/sprint.dart';

import 'package:realmeye_cli/src/structs/cache.dart';

class Client {
  final log = Sprint('Client');

  late final Browser browser;
  final cachedPages = <CachedPage>[];

  Client({bool quietMode = false}) {
    log.quietMode = quietMode;
  }

  Future initialise({bool headless = true}) async {
    browser = await puppeteer.launch(
      headless: headless,
      defaultViewport: null,
    );

    log.success('Client initialised');
  }

  /// Fetches the next available page with the given URL from cache
  /// or creates a new one if needed
  Future<CachedPage> summonPage(String url) async {
    final pageIsAvailable = (CachedPage cachedPage) =>
        cachedPage.page.url == url && !cachedPage.isLocked;

    final CachedPage cachedPage = cachedPages.any(pageIsAvailable)
        ? cachedPages.firstWhere(pageIsAvailable)
        : await spawnPage(url);
    cachedPage.lock();

    return cachedPage;
  }

  /// Spawns a new page with the given URL, adds it to cache and returns it
  Future<CachedPage> spawnPage(String url) async {
    final cachedPage = CachedPage(await browser.newPage());
    await cachedPage.page.goto(url);
    cachedPages.add(cachedPage);
    return cachedPage;
  }
}
