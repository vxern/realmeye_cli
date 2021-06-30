import 'dart:async';

import 'package:puppeteer/puppeteer.dart';
import 'package:realmeye_cli/src/constants/actions.dart';
import 'package:realmeye_cli/src/constants/routes.dart';
import 'package:realmeye_cli/src/constants/selectors.dart';
import 'package:realmeye_cli/src/structs/item.dart';
import 'package:realmeye_cli/src/structs/offer.dart';
import 'package:realmeye_cli/src/utils.dart';
import 'package:sprint/sprint.dart';

import 'package:realmeye_cli/src/structs/cache.dart';

class Client {
  final log = Sprint('Client');

  late final Browser browser;
  final cachedPages = <CachedPage>[];

  late final String username;

  final List<Item> itemList = [];
  final List<OfferListing> offers = [];

  bool isAutosaving = false;
  final autosaveDelay = const Duration(seconds: 30);

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

    try {
      // Attempt to log in
      await page.clickAndWaitForNavigation(
        Selectors.loginSubmitButton,
        timeout: Duration(seconds: 1, milliseconds: 500),
        wait: Until.domContentLoaded,
      );
      this.username = username;
      log.success('Logged in successfully');
    } catch (_) {
      log.error('Failed to log in using the provided credentials');
      return;
    }

    await fetchItemList();
    await fetchOfferList();

    cachedPage.unlock();
  }

  /// Fetches the list of all available items on RealmEye
  Future fetchItemList() async {
    final cachedPage = await summonPage(
      Utils.parseRoute(Routes.editOffers, parameters: {
        'username': username,
      }),
    );
    final page = cachedPage.page;

    final itemList = await page.$$(Selectors.itemList);

    for (final item in itemList) {
      final itemId = int.parse(await item.evaluate(Actions.fetchItemId));
      final itemName = await item.propertyValue('title');
      final resolvedItem = Item(itemId, itemName);
      this.itemList.add(resolvedItem);
    }

    log.debug('Fetched list of tradeable items: ${itemList.length} items');

    cachedPage.unlock();
  }

  /// Fetches the list of offers listed on the account
  Future fetchOfferList() async {
    final cachedPage = await summonPage(
      Utils.parseRoute(Routes.editOffers, parameters: {
        'username': username,
      }),
    );
    final page = cachedPage.page;

    offers.clear();

    final offersActive = await page.$$(Selectors.activeOffersList);
    final offersSuspended = await page.$$(Selectors.suspendedOffersList);

    offers.addAll(await parseOfferListings(offersActive, OfferStatus.active));
    offers.addAll(
        await parseOfferListings(offersSuspended, OfferStatus.suspended));

    log.debug('Fetched list of offers: ${offers.length} offer listings');

    cachedPage.unlock();
  }

  /// Parses a list of offer elements and adds them to [offers]
  Future<List<OfferListing>> parseOfferListings(
    List<ElementHandle> offers,
    OfferStatus offerStatus,
  ) async {
    final List<OfferListing> result = [];

    for (int i = 0; i < offers.length; i++) {
      final sellListing = (await offers[i].evaluate(Actions.fetchSell))
          .map<ItemListing>(
            (itemToSell) => ItemListing(
              resolveIdToItem(itemToSell[0])!,
              itemToSell[1],
            ),
          )
          .toList();

      final buyListing = (await offers[i].evaluate(Actions.fetchBuy))
          .map<ItemListing>(
            (itemToBuy) => ItemListing(
              resolveIdToItem(itemToBuy[0])!,
              itemToBuy[1],
            ),
          )
          .toList();

      final volume = int.parse(await offers[i].evaluate(Actions.fetchVolume));

      result.add(
        OfferListing(Offer(sellListing, buyListing, volume, offerStatus), i),
      );
    }

    return result;
  }

  Future saveOffers({bool autosave = false}) async {
    if (isAutosaving) {
      log.warning('Attempted to save offers whilst auto-saving is enabled');
      return;
    }

    final cachedPage = await summonPage(
      Utils.parseRoute(Routes.editOffers, parameters: {
        'username': username,
      }),
    );
    final page = cachedPage.page;

    if (!autosave) {
      await page.click(Selectors.offersSaveButton);
      cachedPage.unlock();
      return;
    }

    isAutosaving = true;

    log.success('Enabled auto-saving of offers');

    Timer.periodic(autosaveDelay, (timer) {
      if (!isAutosaving) {
        timer.cancel();
        return;
      }

      page.click(Selectors.offersSaveButton);
    });
  }

  void stopAutosave() => this.isAutosaving = false;

  /// Fetches an item by its ID
  Item? resolveIdToItem(int itemId) =>
      itemList.singleWhere((item) => item.id == itemId, orElse: null);
}
