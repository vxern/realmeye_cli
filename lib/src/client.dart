import 'dart:async';

import 'package:puppeteer/puppeteer.dart';
import 'package:realmeye_cli/src/constants/routes.dart';
import 'package:realmeye_cli/src/constants/selectors.dart';
import 'package:sprint/sprint.dart';

import 'package:realmeye_cli/src/structs/cache.dart';

class Client {
  final log = Sprint('Client');

  late final Browser browser;
  final cachedPages = <CachedPage>[];

  late final String username;

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

  /// Authenticates this client instance using the provided credentials
  Future login({required String username, required String password}) async {
    final cachedPage = await summonPage(Routes.login);
    final page = cachedPage.page;

    // Input credentials
    await page.type(Selectors.loginUsernameTextField, username);
    await page.type(Selectors.loginPasswordTextField, password);
    // Log in
    await page.click(Selectors.loginSubmitButton);

    try {
      await page.waitForNavigation(
        timeout: Duration(seconds: 1, milliseconds: 500),
        wait: Until.domContentLoaded,
      );
      this.username = username;
      log.success('Logged in successfully');
    } catch (_) {
      log.error('Failed to log in using the provided credentials');
      return;
    }

    cachedPage.unlock();
  }
}
