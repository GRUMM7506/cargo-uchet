// Валюты, которые поддерживает приложение.

class Currency {
  final String code;
  final String symbolRu;
  final String symbolUz;
  final bool prefix; // символ перед числом ($100) или после (100 сум)
  final int decimals; // сколько знаков после запятой показывать
  final String nameRu;
  final String nameUz;
  final String flag;

  /// Примерный курс к доллару — используется, пока курсы ни разу не загружались.
  final double fallbackPerUsd;

  const Currency({
    required this.code,
    required this.symbolRu,
    required this.symbolUz,
    required this.prefix,
    required this.decimals,
    required this.nameRu,
    required this.nameUz,
    required this.flag,
    required this.fallbackPerUsd,
  });

  String symbol(String lang) => lang == 'uz' ? symbolUz : symbolRu;
  String name(String lang) => lang == 'uz' ? nameUz : nameRu;
}

const currencies = <Currency>[
  Currency(
    code: 'USD',
    symbolRu: '\$',
    symbolUz: '\$',
    prefix: true,
    decimals: 2,
    nameRu: 'Доллар США',
    nameUz: 'AQSh dollari',
    flag: '🇺🇸',
    fallbackPerUsd: 1,
  ),
  Currency(
    code: 'UZS',
    symbolRu: 'сум',
    symbolUz: 'soʻm',
    prefix: false,
    decimals: 0,
    nameRu: 'Узбекский сум',
    nameUz: 'Oʻzbek soʻmi',
    flag: '🇺🇿',
    fallbackPerUsd: 12800,
  ),
  Currency(
    code: 'TJS',
    symbolRu: 'смн',
    symbolUz: 'somoni',
    prefix: false,
    decimals: 2,
    nameRu: 'Таджикский сомони',
    nameUz: 'Tojik somoniysi',
    flag: '🇹🇯',
    fallbackPerUsd: 9.6,
  ),
  Currency(
    code: 'CNY',
    symbolRu: '¥',
    symbolUz: '¥',
    prefix: true,
    decimals: 2,
    nameRu: 'Китайский юань',
    nameUz: 'Xitoy yuani',
    flag: '🇨🇳',
    fallbackPerUsd: 7.15,
  ),
  Currency(
    code: 'KGS',
    symbolRu: 'сом',
    symbolUz: 'som',
    prefix: false,
    decimals: 0,
    nameRu: 'Киргизский сом',
    nameUz: 'Qirgʻiz somi',
    flag: '🇰🇬',
    fallbackPerUsd: 87.4,
  ),
  Currency(
    code: 'RUB',
    symbolRu: '₽',
    symbolUz: '₽',
    prefix: false,
    decimals: 0,
    nameRu: 'Российский рубль',
    nameUz: 'Rossiya rubli',
    flag: '🇷🇺',
    fallbackPerUsd: 80,
  ),
  Currency(
    code: 'EUR',
    symbolRu: '€',
    symbolUz: '€',
    prefix: true,
    decimals: 2,
    nameRu: 'Евро',
    nameUz: 'Yevro',
    flag: '🇪🇺',
    fallbackPerUsd: 0.86,
  ),
];

const defaultEnabledCurrencies = ['USD', 'UZS', 'TJS', 'CNY'];

Currency currencyOf(String code) =>
    currencies.firstWhere((c) => c.code == code, orElse: () => currencies.first);

bool isKnownCurrency(String code) => currencies.any((c) => c.code == code);
