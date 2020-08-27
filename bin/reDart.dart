import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:reDart/log.dart';
import 'package:reDart/structs.dart';
import 'package:reDart/utils.dart';

import 'package:puppeteer/puppeteer.dart';
import 'package:pedantic/pedantic.dart';

// JSON files
dynamic config;
dynamic sites;
dynamic shortcuts;
dynamic selectors;

// Puppeteer
Page page;
Browser browser;

// Working lists for item look-up and offers
var idToName = {};
var nameToId = {};
var tableIndexToName = {};
var nameToTableIndex = {};
List<Offer> offersActive = [];
List<Offer> offersSuspended = [];

var autoSaving = false;

void main() async {
  await init();
}

Future<void> init() async {
  config = await Utils.parseJson('assets/config.json');
  sites = await Utils.parseJson('assets/sites.json');
  shortcuts = await Utils.parseJson('assets/shortcuts.json');
  selectors = await Utils.parseJson('assets/selectors.json');

  browser = await puppeteer.launch(headless: config['headless']);
  page = await browser.newPage();
  await page.setViewport(DeviceViewport(width: 1920, height: 13000));

  await initLog(config['debug']);

  page.onConsole.listen((msg) => log(Severity.Debug, msg.text));

  readLine().listen(commandHandler);

  await logIn();
  await fetchItems();
  await fetchOffers();

  log(Severity.Warning, 'reDart initialised.');
}

Future<dynamic> goto(dynamic destination) async {
  destination = destination
      .toString()
      .replaceFirst('%username%', config['account']['username']);
  if (destination != page.url) {
    if (page.url != 'about:blank') {
      await page.waitForNavigation(wait: Until.load);
    }
    await page.goto(destination);
    return;
  }
}

Future<void> logIn() async {
  await goto(sites['login']);

  await page.type(selectors['loginUsernameBox'], config['account']['username']);
  await page.type(selectors['loginPasswordBox'], config['account']['password']);

  await page.click(selectors['loginSubmit']);
  log(Severity.Debug, 'Logged in as ' + config['account']['username'] + '.');
}

Future<void> suspend(String option) async {
  await goto(sites['editOffers']);

  if (offersActive.isEmpty) {
    log(Severity.Error, 'There are no active offers.');
    return;
  }

  if (option == 'all') {
    await page.click(selectors['offerSuspendAll']);
    log(Severity.Info, 'Offers suspended.');
    await fetchOffers();
    return;
  } else if (option.startsWith('s') && Utils.isInteger(option.substring(1))) {
    log(Severity.Error, 'You cannot suspend suspended offers.');
    return;
  } else if (Utils.isInteger(option)) {
    var index = int.parse(option);
    if (index < 0 || index + 1 > offersActive.length) {
      log(Severity.Error, 'Index out of bounds.');
      return;
    }
    var offersSection = await page.$$(selectors['offerActiveOffers']);
    await page.evaluate(selectors['offerSuspendAction'],
        args: [offersSection[index]]);
    await fetchOffers();
    log(Severity.Info, 'Suspended offer.');
    return;
  } else {
    log(Severity.Error, 'Invalid arguments.');
    return;
  }
}

Future<void> unsuspend(String option) async {
  await goto(sites['editOffers']);

  if (offersSuspended.isEmpty) {
    log(Severity.Error, 'There are no suspended offers.');
    return;
  }

  if (option == 'all') {
    await page.click(selectors['offerUnsuspendAll']);
    log(Severity.Info, 'Offers unsuspended.');
    await fetchOffers();
    return;
  } else if (Utils.isInteger(option)) {
    log(Severity.Error, 'You cannot unsuspend active offers.');
    return;
  } else if (option.startsWith('s') && Utils.isInteger(option.substring(1))) {
    var index = int.parse(option.substring(1));
    if (index < 0 || index + 1 > offersSuspended.length) {
      log(Severity.Error, 'Index out of bounds.');
      return;
    }
    var offersSection = await page.$$(selectors['offerSuspendedOffers']);
    await page.evaluate(selectors['offerUnsuspendAction'],
        args: [offersSection[index]]);
    await fetchOffers();
    return;
  } else {
    log(Severity.Error, 'Invalid arguments.');
    return;
  }
}

Future<void> addOffer(String command, List<String> options) async {
  await goto(sites['editOffers']);

  log(Severity.Info, 'Not implemented.');
}

Future<void> removeOffer(String option) async {
  await goto(sites['editOffers']);

  log(Severity.Info, 'Not implemented.');
}

Future<void> list(List<String> options) async {}

Future<void> info() async {
  log(Severity.Info,
      'You have ${offersActive.length + offersSuspended.length} offers: ${offersActive.length} active, ${offersSuspended.length} suspended');
}

Future<void> find(String option) async {
  log(Severity.Info, 'Not implemented.');
}

Future<void> autoSave({int interval = 3}) async {
  if (autoSaving) {
    autoSaving = false;
    return;
  }

  await goto(sites['editOffers']);

  if (interval < 3) interval = 3;
  autoSaving = true;
  log(Severity.Info, 'Automatic saving activated.');
  Timer.periodic(Duration(seconds: interval), (timer) {
    if (autoSaving) {
      page.click(selectors['offerSave']);
    } else {
      log(Severity.Info, 'Automatic saving deactivated.');
      timer.cancel();
    }
  });
}

Future<void> save() async {
  await goto(sites['editOffers']);

  await page.click(selectors['offerSave']);
  log(Severity.Info, 'Offers saved.');
}

Future<void> help(String additionalInfo) async {
  if (additionalInfo.isEmpty) {
    log(Severity.Info, "Here\'s a list of the functionalities of the script:");
    log(Severity.Warning,
        '''\r\n<suspend/unsuspend> ≡ Suspend or unsuspend offers
<save> ≡ Save offers
<autosave> ≡ Enables/disables autosaving with an interval (default interval: 3s)
<buy/sell> ≡ Adds an offer
<remove> ≡ Removes offer
<list> ≡ Lists offers
<info> ≡ Displays info about your offers
<help> ≡ This menu
<exit> ≡ Exits the program
i - For more help, use 'help' and write the command you need more info about.''');
    return;
  }

  switch (additionalInfo) {
    case 'suspend':
      log(Severity.Info,
          '<suspend> [all/<index>] ≡ Suspend offer at index or suspend all active offers');
      break;
    case 'unsuspend':
      log(Severity.Info,
          '<unsuspend> [all/<index>] ≡ Unsuspend offer at index or unsuspend all inactive offers');
      break;
    case 'save':
      log(Severity.Info, '<save> ≡ Save offers once, immediately.');
      break;
    case 'autosave':
      log(
          Severity.Info,
          '<autosave> [<interval > 3>] ≡ Enable autosaving with an interval.'
          '\r\n! - Minimum interval is set to 3 seconds to prevent unnecessary flooding.');
      break;
    case 'buy':
      log(
          Severity.Info,
          '<buy> [<item> <quantity = 1> sell <item> <quantity = 1>] ≡ Lists an item that you want to buy'
          "\r\n! - You must specify the item you're selling too."
          '\r\n! - You may swap the arguments around as long as the items are specified.'
          '\r\n! - You may not specify the quantity and it will be set to 1 by default.');
      break;
    case 'sell':
      log(
          Severity.Info,
          '<sell> [<item> <quantity = 1> buy <item> <quantity = 1>] ≡ Lists an item that you want to sell'
          "\r\n! - You must specify the item you're buying too."
          '\r\n! - You may swap the arguments around as long as the items are specified.'
          '\r\n! - You may not specify the quantity and it will be set to 1 by default.');
      break;
    case 'remove':
      log(Severity.Info,
          '<remove> [<index>] ≡ Removes the offer at the index provided.');
      break;
    case 'list':
      log(Severity.Info,
          '''\r\n<list> ≡ Lists offers according to the arguments you provide
<list> [<item>]
       [<buy> <item>]
       [<sell> <item>]
       [<buy> <item> <sell> <item>]
       [<sell> <item> <buy> <item>]''');
      break;
    case 'info':
      log(Severity.Info, '<info> ≡ Displays info about your offers');
      break;
    case 'help':
      log(Severity.Info, 'Help with help? Sounds reasonable.');
      break;
    case 'exit':
      log(Severity.Info,
          '<exit> ≡ Disposes of the browser and exits the program');
      break;

    default:
      log(Severity.Warning, "Command '$additionalInfo' unknown!");
      break;
  }
}

Future<void> fetchItems() async {
  await goto(sites['editOffers']);

  var items = await page.$$(selectors['realmeyeItems']);

  var id;
  var name;
  for (var i = 0; i < items.length; i++) {
    id = int.parse(await page
        .evaluate(selectors['itemsFetchItemIdAction'], args: [items[i]]));
    name = await items[i].propertyValue('title');
    idToName[id] = name;
    nameToId[name] = id;
    tableIndexToName[i] = name;
    nameToTableIndex[name] = i;
  }
  log(Severity.Debug, 'Parsed ${items.length} items.');
}

Future<void> fetchOffers() async {
  await goto(sites['editOffers']);

  await offersActive.clear();
  await offersSuspended.clear();

  var _offersActive = await page.$$(selectors['offerActiveOffers']);
  var _offersSuspended = await page.$$(selectors['offerSuspendedOffers']);

  for (var i = 0; i < _offersActive.length; i++) {
    var sellItems = <Item>[];
    var buyItems = <Item>[];
    var volume;

    var _sellItemsSection = await page
        .$$(Utils.supplantArgsSelector(selectors['offerSellItems'], i));

    for (var itemIndex = 0; itemIndex < _sellItemsSection.length; itemIndex++) {
      var id = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerFetchSellItemIdAction'], itemIndex),
          args: [_sellItemsSection[itemIndex]]));
      var quantity = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerFetchSellItemQuantityAction'], itemIndex),
          args: [_sellItemsSection[itemIndex]]));

      sellItems.add(Item(id, quantity));
    }

    var _buyItemsSection = await page
        .$$(Utils.supplantArgsSelector(selectors['offerBuyItems'], i));

    for (var itemIndex = 0; itemIndex < _buyItemsSection.length; itemIndex++) {
      var id = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerFetchBuyItemIdAction'], itemIndex),
          args: [_buyItemsSection[itemIndex]]));
      var quantity = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerFetchBuyItemQuantityAction'], itemIndex),
          args: [_buyItemsSection[itemIndex]]));

      buyItems.add(Item(id, quantity));
    }

    volume = int.parse(await page.evaluate(selectors['offerFetchVolumeAction'],
        args: [_offersActive[i]]));

    offersActive.add(Offer(sellItems, buyItems, volume));
  }

  for (var i = 0; i < _offersSuspended.length; i++) {
    var sellItems = <Item>[];
    var buyItems = <Item>[];
    var volume;

    var _sellItemsSection = await page.$$(
        Utils.supplantArgsSelector(selectors['offerSuspendedSellItems'], i));

    for (var itemIndex = 0; itemIndex < _sellItemsSection.length; itemIndex++) {
      var id = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerSuspendedFetchSellItemIdAction'], itemIndex),
          args: [_sellItemsSection[itemIndex]]));
      var quantity = int.parse((await page.evaluate(
              Utils.supplantArgsJS(
                  selectors['offerSuspendedFetchSellItemQuantityAction'],
                  itemIndex),
              args: [_sellItemsSection[itemIndex]]))
          .toString()
          .substring(1));

      sellItems.add(Item(id, quantity));
    }

    var _buyItemsSection = await page
        .$$(Utils.supplantArgsSelector(selectors['offerSuspendedBuyItems'], i));

    for (var itemIndex = 0; itemIndex < _buyItemsSection.length; itemIndex++) {
      var id = int.parse(await page.evaluate(
          Utils.supplantArgsJS(
              selectors['offerSuspendedFetchBuyItemIdAction'], itemIndex),
          args: [_buyItemsSection[itemIndex]]));
      var quantity = int.parse((await page.evaluate(
              Utils.supplantArgsJS(
                  selectors['offerSuspendedFetchBuyItemQuantityAction'],
                  itemIndex),
              args: [_buyItemsSection[itemIndex]]))
          .toString()
          .substring(1));

      buyItems.add(Item(id, quantity));
    }

    volume = int.parse(await page.evaluate(
        selectors['offerSuspendedFetchVolumeAction'],
        args: [_offersSuspended[i]]));

    offersSuspended.add(Offer(sellItems, buyItems, volume));
  }

  log(Severity.Debug,
      'Fetched ${offersActive.length + offersSuspended.length} offers: ${offersActive.length} active, ${offersSuspended.length} suspended');
}

Future<void> dispose() async {
  if (autoSaving) await autoSave(interval: 1);
  await browser.close();
  exit(0);
}

//Future<List<Offer>> parseArgsToListing(List<String> options) async {}

Future<void> commandHandler(String line) async {
  if (line.isEmpty) {
    log(Severity.Warning,
        "Please specify a command. 'help' for a list of commands.");
    return;
  }

  line = line.toLowerCase();
  var args = line.split(' ');
  var command = args[0];
  args.removeAt(0);
  if (args.isEmpty) args.add('');

  switch (command) {
    case 'save':
      await save();
      break;
    case 'autosave':
      unawaited(autoSave(interval: int.tryParse(args[0]) ?? 3));
      break;

    case 'suspend':
      await suspend(args[0]);
      break;

    case 'unsuspend':
      await unsuspend(args[0]);
      break;

    case 'buy':
    case 'sell':
      await addOffer(command, args);
      break;

    case 'remove':
      await removeOffer(args[0]);
      break;

    case 'list':
      await list(args);
      break;
    case 'info':
      await info();
      break;
    case 'find':
      await find(args[0]);
      break;

    case 'commands':
    case 'help':
      await help(args[0]);
      break;

    case 'exit':
      await dispose();
      break;

    default:
      log(Severity.Warning, "Command '$command' unknown!");
      break;
  }
}

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());
