// Тексты интерфейса: русский и узбекский (латиница).
// Использование: t.save, t.clientsCount(3) …

import 'settings.dart';

S get t => AppSettings.I.lang == 'uz' ? const _Uz() : const _Ru();

abstract class S {
  const S();

  String get code;

  // --- общее ---
  String get appTitle;
  String get tabHome;
  String get tabClients;
  String get tabOrders;
  String get tabExpenses;
  String get tabReports;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get search;
  String error(Object e);

  // --- даты ---
  List<String> get monthNames;
  List<String> get monthShort;
  String get today;
  String get yesterday;
  String dayMonth(int day, int month);
  List<String> get weekdays;

  // --- деньги / баланс ---
  String get income;
  String get expense;
  String get profit;
  String get loss;
  String profitFor(String month);
  String lossFor(String month);
  String get debt;
  String get overpaid;
  String get settled;
  String debtPill(String x);
  String overpaidPill(String x);
  String get settledPill;
  String get paidPill;
  String get inWork;
  String get done;
  String get overdue;

  // --- главная ---
  String get clientsOwe;
  String get nobodyOwes;
  String clientsCount(int n);
  String overpaidTotal(String x);
  String get debtors;
  String get seeAll;
  String get moneyFlow;
  String get emptyTitle;
  String get emptyMoneyFlow;
  String get monthReport;
  String get settings;
  String get payment;
  String get expenseOne;
  String get order;
  String get client;
  String get deposit;
  String get deposits;
  String get ordersCountLabel;
  String get onSum;

  // --- клиенты ---
  String get clientsSearchHint;
  String get owe;
  String get overpayments;
  String get sortDebtors;
  String get sortAz;
  String get noClients;
  String get noClientsHint;
  String get nobodyFound;
  String get clientDeleted;
  String get ordersTotal;
  String get paymentsLabel;
  String ordersTab(int n);
  String paymentsTab(int n);
  String get noOrders;
  String get noPayments;
  String activeOrders(int n);

  // --- заказы ---
  String get ordersSearchHint;
  String filterActive(int n);
  String get filterDebt;
  String get noOrdersYet;
  String get noOrdersHint;
  String get nothingFound;
  String get longPressHint;
  String pcs(int n);
  String get orderDone;
  String get orderBackInWork;
  String get fieldsTooltip;

  // --- карточка заказа ---
  String get price;
  String get paid;
  String get remaining;
  String get accepted;
  String get dueDate;
  String get doneDate;
  String get takePayment;
  String get markDone;
  String get markInWork;
  String get orderPayments;
  String get fullyPaid;
  String get addPhoto;
  String get orderDeleted;
  String daysLeft(int n);
  String daysOverdue(int n);
  String get dueToday;

  // --- фото ---
  String get takePhoto;
  String get fromGallery;
  String get removePhoto;
  String get changePhoto;

  // --- формы ---
  String get newClient;
  String newClientNamed(String n);
  String get chooseClient;
  String get name;
  String get enterName;
  String get phone;
  String get note;
  String deleteClientQ(String name);
  String deleteClientWithQ(String name, int n);
  String get newOrder;
  String get workDescription;
  String get workPrice;
  String get enterAmount;
  String get negativeAmount;
  String get depositHint;
  String get depositDate;
  String get depositTooBig;
  String get acceptDate;
  String get noDue;
  String get setDue;
  String get orderIsDone;
  String get inWorkCap;
  String doneOn(String date);
  String get doneDateLabel;
  String get willRemain;
  String get deleteOrderQ;
  String get paymentFromClient;
  String clientDebt(String x);
  String clientOverpaid(String x);
  String get clientSettled;
  String get wholeDebt;
  String get orderRemainder;
  String get howMuchGave;
  String get date;
  String get forWhichOrder;
  String get generalAccount;
  String get deletePaymentQ;
  String get newExpense;
  String get amount;
  String get spentOn;
  String get ownCategory;
  String get enterCategory;
  String get comment;
  String get deleteExpenseQ;
  List<String> get defaultCategories;
  String forOrder(String title);

  // --- расходы ---
  String spentIn(String month);
  String get noExpensesPrev;
  String get sameAsPrev;
  String moreThanPrev(String x, int pct);
  String lessThanPrev(String x, int pct);
  String get noExpenses;
  String get noExpensesHint;

  // --- отчёты ---
  String get last6;
  String get allTime;
  String get byMonths;
  String get current;
  String get excelAll;
  String get report;
  String get incomeFull;
  String get expenseFull;
  String get ordersAccepted;
  String get depositsReceived;
  String get debtNow;
  String exportError(Object e);
  String get byCategory;
  String get whoPaid;
  String get debtorsToday;

  // --- настройки ---
  String get language;
  String get appearance;
  String get theme;
  String get themeAuto;
  String get themeLight;
  String get themeDark;
  String get color;
  String get orderFields;
  String get orderFieldsHint;
  String get previewLabel;
  String get fieldPhoto;
  String get fieldDescription;
  String get fieldDeposit;
  String get fieldDue;
  String get fieldDone;
  String get fieldNote;
  String get data;
  String get backup;
  String get backupHint;
  String get restore;
  String get restoreHint;
  String get excelAllHint;
  String get restoreQ;
  String get chooseFile;
  String get restored;
  String get notBackup;
  String get versionLabel;
  String get sampleClient;
  String get sampleWork;

  // --- экспорт ---
  String get sheetSummary;
  String get sheetPayments;
  String get sheetExpenses;
  String get sheetOrders;
  String get sheetClients;
  String reportFor(String m);
  String get monthCol;
  String get total;
  String get category;
  String get work;
  String get due;
  String get balanceCol;
  String get typeCol;
  String get noRecords;
  String pageFooter(int p, int n, String date);
  String shareMonth(String m);
  String get shareAll;
  String get backupSubject;

  // --- валюты ---
  String get currencySection;
  String get mainCurrency;
  String get mainCurrencyHint;
  String get usedCurrencies;
  String get rates;
  String get ratesHint;
  String get ratesNever;
  String get updateRates;
  String get ratesOk;
  String get ratesError;
  String get manualMark;
  String get approxMark;
  String get ratesSource;
  String get converter;
  String get chooseCurrency;
  String get allCurrencies;
  String get currencyCol;
  String appliedAs(String x, String rate);
  String updatedAt(String when);
  String inCurrency(String code);
  String get totalApprox;
  String get byCurrencies;
  String rateFor(String code);

  // --- правка/удаление, масштаб ---
  String get uiSize;
  String get uiSizeHint;
  String get sizeAuto;
  String get sizeSmall;
  String get sizeNormal;
  String get sizeLarge;
  String get actions;
  String get swipeHint;
  String get editOrder;
  String get deleteOrder;
  String get editClient;
  String get deleteClient;
  String get deleted;
  String get open;

  // --- обучение ---
  String get introSkip;
  String get introNext;
  String get introStart;
  String get intro1Title;
  String get intro1Text;
  String get intro2Title;
  String get intro2Text;
  String get intro3Title;
  String get intro3Text;
  String get intro4Title;
  String get intro4Text;
  String get intro5Title;
  String get intro5Text;
  String get gsTitle;
  String get gsDoneTitle;
  String get gsDoneText;
  String get gsHide;
  String get gsStep1;
  String get gsStep1Hint;
  String get gsStep2;
  String get gsStep2Hint;
  String get gsStep3;
  String get gsStep3Hint;
  String get gsStep4;
  String get gsStep4Hint;
  String get gsStep5;
  String get gsStep5Hint;
  String get help;
  String get helpHint;
  String get replayIntro;
  String get clearAll;
  String get clearAllHint;
  String get clearAllQ;
  String get clearAllQ2;
  String get cleared;
  String get yesDelete;
  List<(String, String)> get helpSections;

  // --- отчёт: заказы и долг, меню ---
  String get ordersAndDebt;
  String ordersSumCount(int n);
  String get receivedMoney;
  String get debtLeft;
  String get overpaidLine;
  String get moneySection;
  String get debtFormula;
  String get navHome;
  String get navClients;
  String get navOrders;
  String get navExpenses;
  String get navReports;
}

// ============================================================================
// Русский
// ============================================================================

class _Ru extends S {
  const _Ru();

  @override
  String get code => 'ru';

  @override
  String get appTitle => 'Учёт';
  @override
  String get tabHome => 'Главная';
  @override
  String get tabClients => 'Клиенты';
  @override
  String get tabOrders => 'Заказы';
  @override
  String get tabExpenses => 'Расходы';
  @override
  String get tabReports => 'Отчёты';
  @override
  String get save => 'Сохранить';
  @override
  String get cancel => 'Отмена';
  @override
  String get delete => 'Удалить';
  @override
  String get edit => 'Изменить';
  @override
  String get search => 'Поиск';
  @override
  String error(Object e) => 'Ошибка: $e';

  @override
  List<String> get monthNames => const [
        'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
        'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
      ];
  @override
  List<String> get monthShort => const ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  static const _gen = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  @override
  String get today => 'Сегодня';
  @override
  String get yesterday => 'Вчера';
  @override
  String dayMonth(int day, int month) => '$day ${_gen[month - 1]}';
  @override
  List<String> get weekdays => const ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  String get income => 'Пришло';
  @override
  String get expense => 'Потрачено';
  @override
  String get profit => 'Прибыль';
  @override
  String get loss => 'Убыток';
  @override
  String profitFor(String month) => 'Прибыль за ${month.toLowerCase()}';
  @override
  String lossFor(String month) => 'Убыток за ${month.toLowerCase()}';
  @override
  String get debt => 'Долг';
  @override
  String get overpaid => 'Переплата';
  @override
  String get settled => 'Рассчитан';
  @override
  String debtPill(String x) => 'долг $x';
  @override
  String overpaidPill(String x) => 'переплата $x';
  @override
  String get settledPill => 'рассчитан';
  @override
  String get paidPill => 'оплачен';
  @override
  String get inWork => 'в работе';
  @override
  String get done => 'выполнен';
  @override
  String get overdue => 'просрочен';

  @override
  String get clientsOwe => 'Клиенты должны';
  @override
  String get nobodyOwes => 'никто не должен';
  @override
  String clientsCount(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return '$n клиент';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return '$n клиента';
    return '$n клиентов';
  }

  @override
  String overpaidTotal(String x) => 'переплаты $x';
  @override
  String get debtors => 'Должники';
  @override
  String get seeAll => 'Все';
  @override
  String get moneyFlow => 'Движение денег';
  @override
  String get emptyTitle => 'Пока пусто';
  @override
  String get emptyMoneyFlow => 'Здесь появятся деньги, полученные и потраченные в этом месяце';
  @override
  String get monthReport => 'Отчёт за месяц';
  @override
  String get settings => 'Настройки';
  @override
  String get payment => 'Оплата';
  @override
  String get expenseOne => 'Расход';
  @override
  String get order => 'Заказ';
  @override
  String get client => 'Клиент';
  @override
  String get deposit => 'Залог';
  @override
  String get deposits => 'Залоги';
  @override
  String get ordersCountLabel => 'Заказов';
  @override
  String get onSum => 'На сумму';

  @override
  String get clientsSearchHint => 'Поиск по имени или телефону';
  @override
  String get owe => 'Должны';
  @override
  String get overpayments => 'Переплаты';
  @override
  String get sortDebtors => 'Должники';
  @override
  String get sortAz => 'А–Я';
  @override
  String get noClients => 'Клиентов пока нет';
  @override
  String get noClientsHint => 'Добавьте первого клиента кнопкой ниже';
  @override
  String get nobodyFound => 'Никого не найдено';
  @override
  String get clientDeleted => 'Клиент удалён';
  @override
  String get ordersTotal => 'Заказов на сумму';
  @override
  String get paymentsLabel => 'Оплаты';
  @override
  String ordersTab(int n) => 'Заказы · $n';
  @override
  String paymentsTab(int n) => 'Оплаты · $n';
  @override
  String get noOrders => 'Заказов нет';
  @override
  String get noPayments => 'Оплат нет';
  @override
  String activeOrders(int n) => 'в работе: $n';

  @override
  String get ordersSearchHint => 'Клиент или работа';
  @override
  String filterActive(int n) => 'В работе · $n';
  @override
  String get filterDebt => 'С долгом';
  @override
  String get noOrdersYet => 'Заказов пока нет';
  @override
  String get noOrdersHint => 'Нажмите «Заказ», чтобы добавить первый';
  @override
  String get nothingFound => 'Ничего не найдено';
  @override
  String get longPressHint => 'Удерживайте заказ — меню: выполнен, изменить, удалить. Смахните влево — удалить.';
  @override
  String pcs(int n) => '$n шт';
  @override
  String get orderDone => 'Заказ выполнен';
  @override
  String get orderBackInWork => 'Заказ снова в работе';
  @override
  String get fieldsTooltip => 'Настроить поля';

  @override
  String get price => 'Цена';
  @override
  String get paid => 'Оплачено';
  @override
  String get remaining => 'Осталось';
  @override
  String get accepted => 'Принят';
  @override
  String get dueDate => 'Срок сдачи';
  @override
  String get doneDate => 'Выполнен';
  @override
  String get takePayment => 'Принять оплату';
  @override
  String get markDone => 'Выполнен';
  @override
  String get markInWork => 'Вернуть в работу';
  @override
  String get orderPayments => 'Оплаты по заказу';
  @override
  String get fullyPaid => 'Полностью оплачен';
  @override
  String get addPhoto => 'Добавить фото';
  @override
  String get orderDeleted => 'Заказ удалён';
  @override
  String daysLeft(int n) => 'осталось $n дн.';
  @override
  String daysOverdue(int n) => 'просрочен на $n дн.';
  @override
  String get dueToday => 'сдать сегодня';

  @override
  String get takePhoto => 'Сделать фото';
  @override
  String get fromGallery => 'Выбрать из галереи';
  @override
  String get removePhoto => 'Удалить фото';
  @override
  String get changePhoto => 'Сменить фото';

  @override
  String get newClient => 'Новый клиент';
  @override
  String newClientNamed(String n) => 'Новый клиент «$n»';
  @override
  String get chooseClient => 'Выберите клиента';
  @override
  String get name => 'Имя';
  @override
  String get enterName => 'Введите имя';
  @override
  String get phone => 'Телефон';
  @override
  String get note => 'Заметка';
  @override
  String deleteClientQ(String name) => 'Удалить клиента «$name»?';
  @override
  String deleteClientWithQ(String name, int n) =>
      'Удалить клиента «$name» вместе со всеми его заказами и оплатами ($n записей)?';
  @override
  String get newOrder => 'Новый заказ';
  @override
  String get workDescription => 'Что за работа (например: шкаф, дверь)';
  @override
  String get workPrice => 'Цена работы';
  @override
  String get enterAmount => 'Введите сумму';
  @override
  String get negativeAmount => 'Сумма не может быть отрицательной';
  @override
  String get depositHint => 'Сколько денег дал сразу при заказе';
  @override
  String get depositDate => 'Дата залога';
  @override
  String get depositTooBig => 'Залог больше цены';
  @override
  String get acceptDate => 'Дата приёма';
  @override
  String get noDue => 'Без срока';
  @override
  String get setDue => 'Указать срок сдачи';
  @override
  String get orderIsDone => 'Заказ выполнен';
  @override
  String get inWorkCap => 'В работе';
  @override
  String doneOn(String date) => 'Выполнен $date';
  @override
  String get doneDateLabel => 'Дата выполнения';
  @override
  String get willRemain => 'Останется долг';
  @override
  String get deleteOrderQ => 'Удалить этот заказ?';
  @override
  String get paymentFromClient => 'Оплата от клиента';
  @override
  String clientDebt(String x) => 'Долг клиента: $x';
  @override
  String clientOverpaid(String x) => 'Переплата клиента: $x';
  @override
  String get clientSettled => 'Клиент полностью рассчитан';
  @override
  String get wholeDebt => 'Весь долг';
  @override
  String get orderRemainder => 'Остаток';
  @override
  String get howMuchGave => 'Сколько дал';
  @override
  String get date => 'Дата';
  @override
  String get forWhichOrder => 'За какой заказ (не обязательно)';
  @override
  String get generalAccount => 'В счёт общего долга';
  @override
  String get deletePaymentQ => 'Удалить эту оплату?';
  @override
  String get newExpense => 'Новый расход';
  @override
  String get amount => 'Сумма';
  @override
  String get spentOn => 'На что потратили';
  @override
  String get ownCategory => 'Или напишите свою';
  @override
  String get enterCategory => 'Укажите, на что потратили';
  @override
  String get comment => 'Комментарий';
  @override
  String get deleteExpenseQ => 'Удалить этот расход?';
  @override
  List<String> get defaultCategories => const ['Китай', 'Груз', 'Машина', 'Материалы', 'Аренда', 'Зарплата', 'Прочее'];
  @override
  String forOrder(String title) => 'за «$title»';

  @override
  String spentIn(String month) => 'Потрачено за ${month.toLowerCase()}';
  @override
  String get noExpensesPrev => 'В прошлом месяце расходов не было';
  @override
  String get sameAsPrev => 'Столько же, сколько в прошлом месяце';
  @override
  String moreThanPrev(String x, int pct) => 'На $x больше, чем в прошлом месяце (+$pct%)';
  @override
  String lessThanPrev(String x, int pct) => 'На $x меньше, чем в прошлом месяце (−$pct%)';
  @override
  String get noExpenses => 'Расходов нет';
  @override
  String get noExpensesHint => 'В этом месяце ещё ничего не потрачено';

  @override
  String get last6 => 'Последние 6 месяцев';
  @override
  String get allTime => 'За всё время';
  @override
  String get byMonths => 'По месяцам';
  @override
  String get current => 'текущий';
  @override
  String get excelAll => 'Excel за всё время';
  @override
  String get report => 'Отчёт';
  @override
  String get incomeFull => 'Пришло (залоги и оплаты)';
  @override
  String get expenseFull => 'Потрачено (расходы)';
  @override
  String get ordersAccepted => 'Принято заказов';
  @override
  String get depositsReceived => 'Получено залогов';
  @override
  String get debtNow => 'Клиенты должны сейчас';
  @override
  String exportError(Object e) => 'Ошибка экспорта: $e';
  @override
  String get byCategory => 'Расходы по категориям';
  @override
  String get whoPaid => 'Кто сколько заплатил';
  @override
  String get debtorsToday => 'Должники на сегодня';

  @override
  String get language => 'Язык';
  @override
  String get appearance => 'Оформление';
  @override
  String get theme => 'Тема';
  @override
  String get themeAuto => 'Авто';
  @override
  String get themeLight => 'Светлая';
  @override
  String get themeDark => 'Тёмная';
  @override
  String get color => 'Цвет';
  @override
  String get orderFields => 'Поля заказа';
  @override
  String get orderFieldsHint =>
      'Ненужные поля можно скрыть — они пропадут из формы и списка заказов. Уже введённые данные не удаляются.';
  @override
  String get previewLabel => 'Так выглядит заказ в списке:';
  @override
  String get fieldPhoto => 'Фото работы';
  @override
  String get fieldDescription => 'Описание работы';
  @override
  String get fieldDeposit => 'Залог';
  @override
  String get fieldDue => 'Срок сдачи';
  @override
  String get fieldDone => 'Статус «выполнен»';
  @override
  String get fieldNote => 'Заметка';
  @override
  String get data => 'Данные';
  @override
  String get backup => 'Резервная копия';
  @override
  String get backupHint => 'Отправьте файл себе в Telegram — так данные и фото не потеряются';
  @override
  String get restore => 'Восстановить из копии';
  @override
  String get restoreHint => 'Заменит все текущие данные данными из файла';
  @override
  String get excelAllHint => 'Все клиенты, заказы, оплаты и расходы';
  @override
  String get restoreQ => 'Восстановить данные из резервной копии?\n\nВСЕ текущие данные будут заменены данными из файла.';
  @override
  String get chooseFile => 'Выбрать файл';
  @override
  String get restored => 'Данные восстановлены';
  @override
  String get notBackup => 'Этот файл не является копией учёта';
  @override
  String get versionLabel => 'Версия';
  @override
  String get sampleClient => 'Али Валиев';
  @override
  String get sampleWork => 'Кухонный шкаф';

  @override
  String get sheetSummary => 'Итоги';
  @override
  String get sheetPayments => 'Оплаты';
  @override
  String get sheetExpenses => 'Расходы';
  @override
  String get sheetOrders => 'Заказы';
  @override
  String get sheetClients => 'Клиенты';
  @override
  String reportFor(String m) => 'Отчёт за $m';
  @override
  String get monthCol => 'Месяц';
  @override
  String get total => 'ИТОГО';
  @override
  String get category => 'Категория';
  @override
  String get work => 'Работа';
  @override
  String get due => 'Срок';
  @override
  String get balanceCol => 'Долг (+) / переплата (−)';
  @override
  String get typeCol => 'Тип';
  @override
  String get noRecords => 'Нет записей';
  @override
  String pageFooter(int p, int n, String date) => 'Стр. $p из $n · сформировано $date';
  @override
  String shareMonth(String m) => 'Учёт — $m';
  @override
  String get shareAll => 'Учёт — все данные';
  @override
  String get backupSubject => 'Резервная копия учёта';

  // --- валюты ---
  @override
  String get currencySection => 'Валюта';
  @override
  String get mainCurrency => 'Основная валюта';
  @override
  String get mainCurrencyHint => 'В ней показываются итоги, долги и отчёты. Её же предлагаем при вводе новых сумм.';
  @override
  String get usedCurrencies => 'Валюты в списке выбора';
  @override
  String get rates => 'Курсы валют';
  @override
  String get ratesHint => 'Обновляются из интернета раз в день. Нажмите на курс, чтобы ввести свой.';
  @override
  String get ratesNever => 'Курсы ещё не загружались — пока используются примерные';
  @override
  String get updateRates => 'Обновить курсы';
  @override
  String get ratesOk => 'Курсы обновлены';
  @override
  String get ratesError => 'Не удалось загрузить курсы. Проверьте интернет.';
  @override
  String get manualMark => 'вручную';
  @override
  String get approxMark => 'примерно';
  @override
  String get ratesSource => 'Источник курсов: ExchangeRate-API (exchangerate-api.com)';
  @override
  String get converter => 'Конвертер';
  @override
  String get chooseCurrency => 'Валюта';
  @override
  String get allCurrencies => 'Все валюты и курсы';
  @override
  String get currencyCol => 'Валюта';
  @override
  String appliedAs(String x, String rate) => '≈ $x в счёт долга · курс $rate';
  @override
  String updatedAt(String when) => 'Обновлено: $when';
  @override
  String inCurrency(String code) => 'в $code';
  @override
  String get totalApprox => 'Всего ≈';
  @override
  String get byCurrencies => 'По валютам';
  @override
  String rateFor(String code) => 'Курс: 1 $code =';

  // --- правка/удаление, масштаб ---
  @override
  String get uiSize => 'Размер интерфейса';
  @override
  String get uiSizeHint => 'Если надписи не помещаются или переносятся — выберите «Мельче».';
  @override
  String get sizeAuto => 'Авто';
  @override
  String get sizeSmall => 'Мельче';
  @override
  String get sizeNormal => 'Обычный';
  @override
  String get sizeLarge => 'Крупнее';
  @override
  String get actions => 'Действия';
  @override
  String get swipeHint => 'Удерживайте запись или смахните влево, чтобы изменить или удалить';
  @override
  String get editOrder => 'Изменить заказ';
  @override
  String get deleteOrder => 'Удалить заказ';
  @override
  String get editClient => 'Изменить клиента';
  @override
  String get deleteClient => 'Удалить клиента';
  @override
  String get deleted => 'Удалено';
  @override
  String get open => 'Открыть';

  // --- обучение ---
  @override
  String get introSkip => 'Пропустить';
  @override
  String get introNext => 'Далее';
  @override
  String get introStart => 'Начать';
  @override
  String get intro1Title => 'Тетрадь долгов клиентов';
  @override
  String get intro1Text => 'Записывайте заказы, залоги и оплаты — приложение само посчитает, кто сколько должен.';
  @override
  String get intro2Title => 'Клиент и заказ';
  @override
  String get intro2Text => 'Добавьте клиента, затем заказ: что за работа, цена и сколько дал залога. Работу можно сфотографировать.';
  @override
  String get intro3Title => 'Оплата закрывает долг';
  @override
  String get intro3Text => 'Клиент принёс деньги — нажмите «Оплата». Долг = цена − залог − оплаты. Должники всегда видны на главной.';
  @override
  String get intro4Title => 'Расходы и прибыль';
  @override
  String get intro4Text => 'Записывайте расходы: Китай, груз, машина… Каждый месяц приложение само считает приход, расход и прибыль.';
  @override
  String get intro5Title => 'Валюты и резервная копия';
  @override
  String get intro5Text => 'Суммы можно вводить в долларах, сумах, сомони и юанях — курс обновляется сам. Раз в неделю отправляйте резервную копию себе в Telegram.';
  @override
  String get gsTitle => 'С чего начать';
  @override
  String get gsDoneTitle => 'Всё готово! 🎉';
  @override
  String get gsDoneText => 'Вы попробовали всё основное. Эту карточку можно скрыть.';
  @override
  String get gsHide => 'Скрыть';
  @override
  String get gsStep1 => 'Добавьте клиента';
  @override
  String get gsStep1Hint => 'Имя и телефон, можно фото';
  @override
  String get gsStep2 => 'Запишите заказ';
  @override
  String get gsStep2Hint => 'Что за работа, цена и залог';
  @override
  String get gsStep3 => 'Примите оплату';
  @override
  String get gsStep3Hint => 'Когда клиент принесёт деньги';
  @override
  String get gsStep4 => 'Запишите расход';
  @override
  String get gsStep4Hint => 'Китай, груз, машина…';
  @override
  String get gsStep5 => 'Сделайте резервную копию';
  @override
  String get gsStep5Hint => 'Отправьте файл себе в Telegram';
  @override
  String get help => 'Как пользоваться';
  @override
  String get helpHint => 'Короткая инструкция по всем разделам';
  @override
  String get replayIntro => 'Показать вступление ещё раз';
  @override
  String get clearAll => 'Удалить все данные';
  @override
  String get clearAllHint => 'Например, после проверки на тестовых записях';
  @override
  String get clearAllQ => 'Удалить ВСЕХ клиентов, заказы, оплаты и расходы? Настройки и курсы останутся.';
  @override
  String get clearAllQ2 => 'Точно? Это нельзя отменить. Если данные нужны — сначала сделайте резервную копию.';
  @override
  String get cleared => 'Все данные удалены';
  @override
  String get yesDelete => 'Да, удалить';
  @override
  List<(String, String)> get helpSections => const [
        ('Клиенты', 'Список всех клиентов. Справа видно, сколько клиент должен (оранжевым) или переплатил (зелёным). Нажмите на клиента — откроется его карточка с заказами и оплатами.'),
        ('Заказ', 'Заказ — это работа для клиента. Укажите цену и залог (сколько денег дал сразу). Срок сдачи — не обязательно: просроченные заказы подсвечиваются красным. Когда работа готова, отметьте «Выполнен».'),
        ('Залог и оплата', 'Залог вводится в самом заказе. Остальные деньги — кнопкой «Оплата». Оплату можно привязать к конкретному заказу или внести в счёт общего долга клиента.'),
        ('Как считается долг', 'Долг = цены заказов − залоги − оплаты. Если клиент заплатил больше, это переплата: она уменьшит его следующий долг.'),
        ('Расходы', 'Все траты: Китай, груз, машина, материалы… Можно написать свою категорию.'),
        ('Главная и отчёты', 'На главной — прибыль месяца: приход (залоги + оплаты) минус расходы. Стрелками ‹ › можно листать месяцы. В «Отчётах» — график и выгрузка в Excel и PDF.'),
        ('Валюты', 'У каждой суммы есть кнопка валюты (USD ▾). Итоги показываются в основной валюте — её меняет кнопка вверху главного экрана. Курсы обновляются из интернета раз в день.'),
        ('Изменить или удалить', 'Нажмите на запись, чтобы изменить её. Удерживайте палец — появится меню «Изменить / Удалить». Смахните запись влево — удалить.'),
        ('Резервная копия', 'Настройки → Резервная копия: файл с данными и фото отправьте себе в Telegram. На новом телефоне: Настройки → Восстановить из копии.'),
      ];

  // --- отчёт: заказы и долг, меню ---
  @override
  String get ordersAndDebt => 'Заказы и долг';
  @override
  String ordersSumCount(int n) => 'Сумма заказов ($n шт)';
  @override
  String get receivedMoney => 'Получено (залоги + оплаты)';
  @override
  String get debtLeft => 'Клиенты ещё должны';
  @override
  String get overpaidLine => 'Переплаты клиентов';
  @override
  String get moneySection => 'Деньги';
  @override
  String get debtFormula => 'Долг = сумма заказов − полученные деньги';
  @override
  String get navHome => 'Главная';
  @override
  String get navClients => 'Клиенты';
  @override
  String get navOrders => 'Заказы';
  @override
  String get navExpenses => 'Расходы';
  @override
  String get navReports => 'Отчёты';
}

// ============================================================================
// Oʻzbekcha (lotin)
// ============================================================================

class _Uz extends S {
  const _Uz();

  @override
  String get code => 'uz';

  @override
  String get appTitle => 'Hisob-kitob';
  @override
  String get tabHome => 'Asosiy';
  @override
  String get tabClients => 'Mijozlar';
  @override
  String get tabOrders => 'Buyurtmalar';
  @override
  String get tabExpenses => 'Xarajatlar';
  @override
  String get tabReports => 'Hisobotlar';
  @override
  String get save => 'Saqlash';
  @override
  String get cancel => 'Bekor qilish';
  @override
  String get delete => 'Oʻchirish';
  @override
  String get edit => 'Tahrirlash';
  @override
  String get search => 'Qidirish';
  @override
  String error(Object e) => 'Xatolik: $e';

  @override
  List<String> get monthNames => const [
        'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
        'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
      ];
  @override
  List<String> get monthShort => const ['yan', 'fev', 'mar', 'apr', 'may', 'iyn', 'iyl', 'avg', 'sen', 'okt', 'noy', 'dek'];
  @override
  String get today => 'Bugun';
  @override
  String get yesterday => 'Kecha';
  @override
  String dayMonth(int day, int month) => '$day-${monthNames[month - 1].toLowerCase()}';
  @override
  List<String> get weekdays => const ['du', 'se', 'ch', 'pa', 'ju', 'sh', 'ya'];

  @override
  String get income => 'Kirim';
  @override
  String get expense => 'Chiqim';
  @override
  String get profit => 'Foyda';
  @override
  String get loss => 'Zarar';
  @override
  String profitFor(String month) => '$month oyi foydasi';
  @override
  String lossFor(String month) => '$month oyi zarari';
  @override
  String get debt => 'Qarz';
  @override
  String get overpaid => 'Ortiqcha toʻlov';
  @override
  String get settled => 'Qarzi yoʻq';
  @override
  String debtPill(String x) => 'qarz $x';
  @override
  String overpaidPill(String x) => 'ortiqcha $x';
  @override
  String get settledPill => 'qarzi yoʻq';
  @override
  String get paidPill => 'toʻliq toʻlangan';
  @override
  String get inWork => 'jarayonda';
  @override
  String get done => 'bajarildi';
  @override
  String get overdue => 'muddati oʻtgan';

  @override
  String get clientsOwe => 'Mijozlar menga qarz';
  @override
  String get nobodyOwes => 'hech kim qarzdor emas';
  @override
  String clientsCount(int n) => '$n ta mijoz';
  @override
  String overpaidTotal(String x) => 'ortiqcha toʻlovlar $x';
  @override
  String get debtors => 'Qarzdorlar';
  @override
  String get seeAll => 'Barchasi';
  @override
  String get moneyFlow => 'Pul harakati';
  @override
  String get emptyTitle => 'Hozircha boʻsh';
  @override
  String get emptyMoneyFlow => 'Bu oyda olingan va sarflangan pullar shu yerda chiqadi';
  @override
  String get monthReport => 'Oylik hisobot';
  @override
  String get settings => 'Sozlamalar';
  @override
  String get payment => 'Toʻlov';
  @override
  String get expenseOne => 'Xarajat';
  @override
  String get order => 'Buyurtma';
  @override
  String get client => 'Mijoz';
  @override
  String get deposit => 'Zaklad';
  @override
  String get deposits => 'Zakladlar';
  @override
  String get ordersCountLabel => 'Buyurtmalar';
  @override
  String get onSum => 'Summasi';

  @override
  String get clientsSearchHint => 'Ism yoki telefon boʻyicha qidirish';
  @override
  String get owe => 'Menga qarz';
  @override
  String get overpayments => 'Ortiqcha toʻlovlar';
  @override
  String get sortDebtors => 'Qarzdorlar';
  @override
  String get sortAz => 'A–Z';
  @override
  String get noClients => 'Hozircha mijozlar yoʻq';
  @override
  String get noClientsHint => 'Birinchi mijozni pastdagi tugma bilan qoʻshing';
  @override
  String get nobodyFound => 'Hech kim topilmadi';
  @override
  String get clientDeleted => 'Mijoz oʻchirilgan';
  @override
  String get ordersTotal => 'Buyurtmalar summasi';
  @override
  String get paymentsLabel => 'Toʻlovlar';
  @override
  String ordersTab(int n) => 'Buyurtmalar · $n';
  @override
  String paymentsTab(int n) => 'Toʻlovlar · $n';
  @override
  String get noOrders => 'Buyurtmalar yoʻq';
  @override
  String get noPayments => 'Toʻlovlar yoʻq';
  @override
  String activeOrders(int n) => 'jarayonda: $n';

  @override
  String get ordersSearchHint => 'Mijoz yoki ish';
  @override
  String filterActive(int n) => 'Jarayonda · $n';
  @override
  String get filterDebt => 'Qarzli';
  @override
  String get noOrdersYet => 'Hozircha buyurtmalar yoʻq';
  @override
  String get noOrdersHint => 'Birinchisini qoʻshish uchun «Buyurtma»ni bosing';
  @override
  String get nothingFound => 'Hech narsa topilmadi';
  @override
  String get longPressHint => 'Buyurtmani bosib turing — menyu: bajarildi, tahrirlash, oʻchirish. Chapga suring — oʻchirish.';
  @override
  String pcs(int n) => '$n ta';
  @override
  String get orderDone => 'Buyurtma bajarildi';
  @override
  String get orderBackInWork => 'Buyurtma yana jarayonda';
  @override
  String get fieldsTooltip => 'Maydonlarni sozlash';

  @override
  String get price => 'Narx';
  @override
  String get paid => 'Toʻlangan';
  @override
  String get remaining => 'Qoldiq';
  @override
  String get accepted => 'Qabul qilindi';
  @override
  String get dueDate => 'Topshirish muddati';
  @override
  String get doneDate => 'Bajarildi';
  @override
  String get takePayment => 'Toʻlov olish';
  @override
  String get markDone => 'Bajarildi';
  @override
  String get markInWork => 'Jarayonga qaytarish';
  @override
  String get orderPayments => 'Buyurtma boʻyicha toʻlovlar';
  @override
  String get fullyPaid => 'Toʻliq toʻlangan';
  @override
  String get addPhoto => 'Rasm qoʻshish';
  @override
  String get orderDeleted => 'Buyurtma oʻchirilgan';
  @override
  String daysLeft(int n) => '$n kun qoldi';
  @override
  String daysOverdue(int n) => '$n kun kechikdi';
  @override
  String get dueToday => 'bugun topshirish';

  @override
  String get takePhoto => 'Suratga olish';
  @override
  String get fromGallery => 'Galereyadan tanlash';
  @override
  String get removePhoto => 'Rasmni oʻchirish';
  @override
  String get changePhoto => 'Rasmni almashtirish';

  @override
  String get newClient => 'Yangi mijoz';
  @override
  String newClientNamed(String n) => 'Yangi mijoz «$n»';
  @override
  String get chooseClient => 'Mijozni tanlang';
  @override
  String get name => 'Ism';
  @override
  String get enterName => 'Ismni kiriting';
  @override
  String get phone => 'Telefon';
  @override
  String get note => 'Izoh';
  @override
  String deleteClientQ(String name) => '«$name» mijozini oʻchirasizmi?';
  @override
  String deleteClientWithQ(String name, int n) =>
      '«$name» mijozini barcha buyurtma va toʻlovlari bilan birga ($n ta yozuv) oʻchirasizmi?';
  @override
  String get newOrder => 'Yangi buyurtma';
  @override
  String get workDescription => 'Qanday ish (masalan: shkaf, eshik)';
  @override
  String get workPrice => 'Ish narxi';
  @override
  String get enterAmount => 'Summani kiriting';
  @override
  String get negativeAmount => 'Summa manfiy boʻlishi mumkin emas';
  @override
  String get depositHint => 'Buyurtma berganda darhol qancha pul berdi';
  @override
  String get depositDate => 'Zaklad sanasi';
  @override
  String get depositTooBig => 'Zaklad narxdan katta';
  @override
  String get acceptDate => 'Qabul qilingan sana';
  @override
  String get noDue => 'Muddatsiz';
  @override
  String get setDue => 'Topshirish muddatini belgilash';
  @override
  String get orderIsDone => 'Buyurtma bajarildi';
  @override
  String get inWorkCap => 'Jarayonda';
  @override
  String doneOn(String date) => 'Bajarildi: $date';
  @override
  String get doneDateLabel => 'Bajarilgan sana';
  @override
  String get willRemain => 'Qoladigan qarz';
  @override
  String get deleteOrderQ => 'Bu buyurtmani oʻchirasizmi?';
  @override
  String get paymentFromClient => 'Mijozdan toʻlov';
  @override
  String clientDebt(String x) => 'Mijoz qarzi: $x';
  @override
  String clientOverpaid(String x) => 'Ortiqcha toʻlagan: $x';
  @override
  String get clientSettled => 'Mijozning qarzi yoʻq';
  @override
  String get wholeDebt => 'Butun qarz';
  @override
  String get orderRemainder => 'Qoldiq';
  @override
  String get howMuchGave => 'Qancha pul berdi';
  @override
  String get date => 'Sana';
  @override
  String get forWhichOrder => 'Qaysi buyurtma uchun (shart emas)';
  @override
  String get generalAccount => 'Umumiy qarz hisobiga';
  @override
  String get deletePaymentQ => 'Bu toʻlovni oʻchirasizmi?';
  @override
  String get newExpense => 'Yangi xarajat';
  @override
  String get amount => 'Summa';
  @override
  String get spentOn => 'Nimaga sarflandi';
  @override
  String get ownCategory => 'Yoki oʻzingiz yozing';
  @override
  String get enterCategory => 'Nimaga sarflanganini yozing';
  @override
  String get comment => 'Izoh';
  @override
  String get deleteExpenseQ => 'Bu xarajatni oʻchirasizmi?';
  @override
  List<String> get defaultCategories =>
      const ['Xitoy', 'Yuk', 'Mashina', 'Materiallar', 'Ijara', 'Ish haqi', 'Boshqa'];
  @override
  String forOrder(String title) => '«$title» uchun';

  @override
  String spentIn(String month) => '$month oyidagi xarajat';
  @override
  String get noExpensesPrev => 'Oʻtgan oyda xarajat boʻlmagan';
  @override
  String get sameAsPrev => 'Oʻtgan oydagidek';
  @override
  String moreThanPrev(String x, int pct) => 'Oʻtgan oydan $x koʻp (+$pct%)';
  @override
  String lessThanPrev(String x, int pct) => 'Oʻtgan oydan $x kam (−$pct%)';
  @override
  String get noExpenses => 'Xarajatlar yoʻq';
  @override
  String get noExpensesHint => 'Bu oyda hali hech narsa sarflanmagan';

  @override
  String get last6 => 'Soʻnggi 6 oy';
  @override
  String get allTime => 'Butun davr';
  @override
  String get byMonths => 'Oylar boʻyicha';
  @override
  String get current => 'joriy';
  @override
  String get excelAll => 'Butun davr uchun Excel';
  @override
  String get report => 'Hisobot';
  @override
  String get incomeFull => 'Kirim (zaklad va toʻlovlar)';
  @override
  String get expenseFull => 'Chiqim (xarajatlar)';
  @override
  String get ordersAccepted => 'Qabul qilingan buyurtmalar';
  @override
  String get depositsReceived => 'Olingan zakladlar';
  @override
  String get debtNow => 'Mijozlarning hozirgi qarzi';
  @override
  String exportError(Object e) => 'Eksport xatosi: $e';
  @override
  String get byCategory => 'Toifalar boʻyicha xarajatlar';
  @override
  String get whoPaid => 'Kim qancha toʻladi';
  @override
  String get debtorsToday => 'Bugungi qarzdorlar';

  @override
  String get language => 'Til';
  @override
  String get appearance => 'Koʻrinish';
  @override
  String get theme => 'Mavzu';
  @override
  String get themeAuto => 'Avto';
  @override
  String get themeLight => 'Yorugʻ';
  @override
  String get themeDark => 'Qorongʻi';
  @override
  String get color => 'Rang';
  @override
  String get orderFields => 'Buyurtma maydonlari';
  @override
  String get orderFieldsHint =>
      'Keraksiz maydonlarni yashirish mumkin — ular forma va roʻyxatdan yoʻqoladi. Kiritilgan maʼlumotlar oʻchmaydi.';
  @override
  String get previewLabel => 'Roʻyxatda buyurtma shunday koʻrinadi:';
  @override
  String get fieldPhoto => 'Ish rasmi';
  @override
  String get fieldDescription => 'Ish tavsifi';
  @override
  String get fieldDeposit => 'Zaklad';
  @override
  String get fieldDue => 'Topshirish muddati';
  @override
  String get fieldDone => '«Bajarildi» holati';
  @override
  String get fieldNote => 'Izoh';
  @override
  String get data => 'Maʼlumotlar';
  @override
  String get backup => 'Zaxira nusxa';
  @override
  String get backupHint => 'Faylni oʻzingizga Telegramga yuboring — maʼlumotlar va rasmlar yoʻqolmaydi';
  @override
  String get restore => 'Nusxadan tiklash';
  @override
  String get restoreHint => 'Barcha joriy maʼlumotlar fayldagi bilan almashtiriladi';
  @override
  String get excelAllHint => 'Barcha mijozlar, buyurtmalar, toʻlovlar va xarajatlar';
  @override
  String get restoreQ =>
      'Maʼlumotlarni zaxira nusxadan tiklaysizmi?\n\nBARCHA joriy maʼlumotlar fayldagi bilan almashtiriladi.';
  @override
  String get chooseFile => 'Faylni tanlash';
  @override
  String get restored => 'Maʼlumotlar tiklandi';
  @override
  String get notBackup => 'Bu fayl zaxira nusxa emas';
  @override
  String get versionLabel => 'Versiya';
  @override
  String get sampleClient => 'Ali Valiyev';
  @override
  String get sampleWork => 'Oshxona shkafi';

  @override
  String get sheetSummary => 'Yakun';
  @override
  String get sheetPayments => 'Toʻlovlar';
  @override
  String get sheetExpenses => 'Xarajatlar';
  @override
  String get sheetOrders => 'Buyurtmalar';
  @override
  String get sheetClients => 'Mijozlar';
  @override
  String reportFor(String m) => '$m hisoboti';
  @override
  String get monthCol => 'Oy';
  @override
  String get total => 'JAMI';
  @override
  String get category => 'Toifa';
  @override
  String get work => 'Ish';
  @override
  String get due => 'Muddat';
  @override
  String get balanceCol => 'Qarz (+) / ortiqcha (−)';
  @override
  String get typeCol => 'Turi';
  @override
  String get noRecords => 'Yozuvlar yoʻq';
  @override
  String pageFooter(int p, int n, String date) => '$p/$n-sahifa · $date';
  @override
  String shareMonth(String m) => 'Hisob-kitob — $m';
  @override
  String get shareAll => 'Hisob-kitob — barcha maʼlumotlar';
  @override
  String get backupSubject => 'Hisob-kitob zaxira nusxasi';

  // --- валюты ---
  @override
  String get currencySection => 'Valyuta';
  @override
  String get mainCurrency => 'Asosiy valyuta';
  @override
  String get mainCurrencyHint => 'Yakunlar, qarzlar va hisobotlar shu valyutada koʻrsatiladi. Yangi summalar ham shu valyutada taklif qilinadi.';
  @override
  String get usedCurrencies => 'Tanlash roʻyxatidagi valyutalar';
  @override
  String get rates => 'Valyuta kurslari';
  @override
  String get ratesHint => 'Kunda bir marta internetdan yangilanadi. Oʻz kursingizni kiritish uchun kursni bosing.';
  @override
  String get ratesNever => 'Kurslar hali yuklanmagan — hozircha taxminiy kurslar';
  @override
  String get updateRates => 'Kurslarni yangilash';
  @override
  String get ratesOk => 'Kurslar yangilandi';
  @override
  String get ratesError => 'Kurslarni yuklab boʻlmadi. Internetni tekshiring.';
  @override
  String get manualMark => 'qoʻlda';
  @override
  String get approxMark => 'taxminiy';
  @override
  String get ratesSource => 'Kurslar manbai: ExchangeRate-API (exchangerate-api.com)';
  @override
  String get converter => 'Konvertor';
  @override
  String get chooseCurrency => 'Valyuta';
  @override
  String get allCurrencies => 'Barcha valyuta va kurslar';
  @override
  String get currencyCol => 'Valyuta';
  @override
  String appliedAs(String x, String rate) => '≈ $x qarz hisobiga · kurs $rate';
  @override
  String updatedAt(String when) => 'Yangilangan: $when';
  @override
  String inCurrency(String code) => '$code da';
  @override
  String get totalApprox => 'Jami ≈';
  @override
  String get byCurrencies => 'Valyutalar boʻyicha';
  @override
  String rateFor(String code) => 'Kurs: 1 $code =';

  // --- правка/удаление, масштаб ---
  @override
  String get uiSize => 'Interfeys oʻlchami';
  @override
  String get uiSizeHint => 'Yozuvlar sigʻmasa yoki keyingi qatorga oʻtsa — «Kichik»ni tanlang.';
  @override
  String get sizeAuto => 'Avto';
  @override
  String get sizeSmall => 'Kichik';
  @override
  String get sizeNormal => 'Oddiy';
  @override
  String get sizeLarge => 'Katta';
  @override
  String get actions => 'Amallar';
  @override
  String get swipeHint => 'Tahrirlash yoki oʻchirish uchun yozuvni bosib turing yoki chapga suring';
  @override
  String get editOrder => 'Buyurtmani tahrirlash';
  @override
  String get deleteOrder => 'Buyurtmani oʻchirish';
  @override
  String get editClient => 'Mijozni tahrirlash';
  @override
  String get deleteClient => 'Mijozni oʻchirish';
  @override
  String get deleted => 'Oʻchirildi';
  @override
  String get open => 'Ochish';

  // --- обучение ---
  @override
  String get introSkip => 'Oʻtkazib yuborish';
  @override
  String get introNext => 'Keyingi';
  @override
  String get introStart => 'Boshlash';
  @override
  String get intro1Title => 'Mijozlar qarz daftari';
  @override
  String get intro1Text => 'Buyurtma, zaklad va toʻlovlarni yozib boring — kim qancha qarzligini ilova oʻzi hisoblaydi.';
  @override
  String get intro2Title => 'Mijoz va buyurtma';
  @override
  String get intro2Text => 'Avval mijozni qoʻshing, keyin buyurtmani: qanday ish, narxi va qancha zaklad berdi. Ishni suratga olib qoʻyish ham mumkin.';
  @override
  String get intro3Title => 'Toʻlov qarzni yopadi';
  @override
  String get intro3Text => 'Mijoz pul olib keldi — «Toʻlov»ni bosing. Qarz = narx − zaklad − toʻlovlar. Qarzdorlar doim asosiy ekranda koʻrinib turadi.';
  @override
  String get intro4Title => 'Xarajat va foyda';
  @override
  String get intro4Text => 'Xarajatlarni yozing: Xitoy, yuk, mashina… Har oy kirim, chiqim va foydani ilova oʻzi hisoblaydi.';
  @override
  String get intro5Title => 'Valyuta va zaxira nusxa';
  @override
  String get intro5Text => 'Summalarni dollar, soʻm, somoni va yuanda kiritish mumkin — kurs oʻzi yangilanadi. Haftada bir marta zaxira nusxani oʻzingizga Telegramga yuboring.';
  @override
  String get gsTitle => 'Nimadan boshlash kerak';
  @override
  String get gsDoneTitle => 'Hammasi tayyor! 🎉';
  @override
  String get gsDoneText => 'Asosiy narsalarning hammasini sinab koʻrdingiz. Bu kartani yashirish mumkin.';
  @override
  String get gsHide => 'Yashirish';
  @override
  String get gsStep1 => 'Mijoz qoʻshing';
  @override
  String get gsStep1Hint => 'Ismi va telefoni, rasm ham mumkin';
  @override
  String get gsStep2 => 'Buyurtma yozing';
  @override
  String get gsStep2Hint => 'Qanday ish, narxi va zaklad';
  @override
  String get gsStep3 => 'Toʻlov qabul qiling';
  @override
  String get gsStep3Hint => 'Mijoz pul olib kelganda';
  @override
  String get gsStep4 => 'Xarajat yozing';
  @override
  String get gsStep4Hint => 'Xitoy, yuk, mashina…';
  @override
  String get gsStep5 => 'Zaxira nusxa oling';
  @override
  String get gsStep5Hint => 'Faylni oʻzingizga Telegramga yuboring';
  @override
  String get help => 'Qanday foydalanish';
  @override
  String get helpHint => 'Barcha boʻlimlar boʻyicha qisqa yoʻriqnoma';
  @override
  String get replayIntro => 'Kirish qismini qayta koʻrish';
  @override
  String get clearAll => 'Barcha maʼlumotlarni oʻchirish';
  @override
  String get clearAllHint => 'Masalan, sinov yozuvlaridan keyin';
  @override
  String get clearAllQ => 'BARCHA mijozlar, buyurtmalar, toʻlovlar va xarajatlar oʻchirilsinmi? Sozlamalar va kurslar qoladi.';
  @override
  String get clearAllQ2 => 'Aniqmi? Buni qaytarib boʻlmaydi. Maʼlumotlar kerak boʻlsa — avval zaxira nusxa oling.';
  @override
  String get cleared => 'Barcha maʼlumotlar oʻchirildi';
  @override
  String get yesDelete => 'Ha, oʻchirish';
  @override
  List<(String, String)> get helpSections => const [
        ('Mijozlar', 'Barcha mijozlar roʻyxati. Oʻng tomonda mijoz qancha qarzligi (toʻq sariq) yoki ortiqcha toʻlagani (yashil) koʻrinadi. Mijozni bossangiz, uning buyurtma va toʻlovlari ochiladi.'),
        ('Buyurtma', 'Buyurtma — mijoz uchun qilinadigan ish. Narxini va zakladni (darhol bergan pulini) kiriting. Topshirish muddati shart emas: muddati oʻtgan buyurtmalar qizil boʻlib turadi. Ish tayyor boʻlsa, «Bajarildi» deb belgilang.'),
        ('Zaklad va toʻlov', 'Zaklad buyurtmaning ichida kiritiladi. Qolgan pullar «Toʻlov» tugmasi orqali yoziladi. Toʻlovni aniq bir buyurtmaga bogʻlash yoki mijozning umumiy qarziga yozish mumkin.'),
        ('Qarz qanday hisoblanadi', 'Qarz = buyurtmalar narxi − zakladlar − toʻlovlar. Mijoz koʻproq toʻlagan boʻlsa, bu ortiqcha toʻlov: keyingi qarzidan ayiriladi.'),
        ('Xarajatlar', 'Sarflangan hamma pul: Xitoy, yuk, mashina, materiallar… Oʻzingiz ham nom yozishingiz mumkin.'),
        ('Asosiy ekran va hisobotlar', 'Asosiy ekranda — oy foydasi: kirim (zaklad + toʻlovlar) minus chiqim. ‹ › strelkalari bilan oylarni almashtirasiz. «Hisobotlar»da — grafik hamda Excel va PDF.'),
        ('Valyutalar', 'Har bir summa yonida valyuta tugmasi bor (USD ▾). Yakunlar asosiy valyutada koʻrsatiladi — uni asosiy ekranning yuqorisidagi tugma almashtiradi. Kurslar kunda bir marta internetdan yangilanadi.'),
        ('Tahrirlash va oʻchirish', 'Yozuvni oʻzgartirish uchun ustiga bosing. Barmogʻingizni bosib tursangiz, «Tahrirlash / Oʻchirish» menyusi chiqadi. Yozuvni chapga sursangiz — oʻchiriladi.'),
        ('Zaxira nusxa', 'Sozlamalar → Zaxira nusxa: maʼlumot va rasmlar faylini oʻzingizga Telegramga yuboring. Yangi telefonda: Sozlamalar → Nusxadan tiklash.'),
      ];

  // --- отчёт: заказы и долг, меню ---
  @override
  String get ordersAndDebt => 'Buyurtmalar va qarz';
  @override
  String ordersSumCount(int n) => 'Buyurtmalar summasi ($n ta)';
  @override
  String get receivedMoney => 'Olingan pul (zaklad + toʻlov)';
  @override
  String get debtLeft => 'Mijozlarda qolgan qarz';
  @override
  String get overpaidLine => 'Mijozlarning ortiqcha toʻlovi';
  @override
  String get moneySection => 'Pul';
  @override
  String get debtFormula => 'Qarz = buyurtmalar summasi − olingan pul';
  @override
  String get navHome => 'Asosiy';
  @override
  String get navClients => 'Mijozlar';
  @override
  String get navOrders => 'Buyurtma';
  @override
  String get navExpenses => 'Xarajat';
  @override
  String get navReports => 'Hisobot';
}
