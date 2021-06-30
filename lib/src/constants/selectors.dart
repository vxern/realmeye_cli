class Selectors {
  static const loginUsernameTextField = 'input[name=username]';
  static const loginPasswordTextField = 'input[name=password]';
  static const loginSubmitButton = '#e > div.panel-footer > button';
  static const wrongPasswordDialog = '#wrong-password';

  static const offersInvisibleDialog =
      'body > div.container > div:nth-child(3) > div > h4';
  static const activeOffersList = '#g > table:nth-child(2) > tbody > tr';
  static const suspendedOffersList = '#g > table:nth-child(6) > tbody > tr';

  static const itemList =
      '#item-selector > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > span';
}
