class Actions {
  /// Fetch the ID of an item by accessing its 'data-item' attribute
  static const fetchItemId =
      'el => el.firstElementChild.getAttribute("data-item")';

  static const fetchSell =
      'el => Object.values(el.children[0].children).map(item => Object.values(item)[0])';
  static const fetchBuy =
      'el => Object.values(el.children[1].children).map(item => Object.values(item)[0])';

  /// Fetch the volume of an item listing by getting the text
  /// from inside the third box
  static const fetchVolume = 'el => el.children[2].innerText';
}
