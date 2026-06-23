class L10n {
  L10n._();

  static String _locale = 'ru';

  static void setLocale(String locale) => _locale = locale;

  static bool get _ru => _locale == 'ru';

  // Navigation
  static String get navJournal  => _ru ? 'Журнал'  : 'Journal';
  static String get navAccounts => _ru ? 'Счета'   : 'Accounts';
  static String get navBudget   => _ru ? 'Бюджет'  : 'Budget';
  static String get navReports  => _ru ? 'Отчёты'  : 'Reports';
  static String get navProfile  => _ru ? 'Профиль' : 'Profile';

  // Common
  static String get save        => _ru ? 'Сохранить'         : 'Save';
  static String get saveChanges => _ru ? 'Сохранить изменения' : 'Save changes';
  static String get saving      => _ru ? 'Сохраняем...'      : 'Saving...';
  static String get cancel      => _ru ? 'Отмена'            : 'Cancel';
  static String get add         => _ru ? 'Добавить'          : 'Add';
  static String get delete      => _ru ? 'Удалить'           : 'Delete';
  static String get edit        => _ru ? 'Редактировать'     : 'Edit';
  static String get ok          => 'OK';
  static String get currency    => _ru ? 'Валюта'            : 'Currency';
  static String get category    => _ru ? 'Категория'         : 'Category';
  static String get account     => _ru ? 'Счёт'              : 'Account';
  static String get date        => _ru ? 'Дата'              : 'Date';
  static String get note        => _ru ? 'Заметка (необязательно)' : 'Note (optional)';
  static String get type        => _ru ? 'Тип'               : 'Type';
  static String get name        => _ru ? 'Название'          : 'Name';
  static String get today       => _ru ? 'Сегодня' : 'Today';
  static String get yesterday   => _ru ? 'Вчера'   : 'Yesterday';

  // Journal
  static String get journal       => _ru ? 'Журнал'    : 'Journal';
  static String get income        => _ru ? 'Доходы'    : 'Income';
  static String get expenses      => _ru ? 'Расходы'   : 'Expenses';
  static String get expenseTab    => _ru ? 'Расход'    : 'Expense';
  static String get incomeTab     => _ru ? 'Доход'     : 'Income';
  static String get balance       => _ru ? 'Баланс'    : 'Balance';
  static String get noTransactions => _ru ? 'Нет операций за этот месяц' : 'No transactions this month';
  static String get newOperation  => _ru ? 'Новая операция' : 'New transaction';
  static String get noAccounts    => _ru ? 'Нет счетов. Создайте счёт в разделе «Счета».' : 'No accounts. Create one in Accounts.';

  // Accounts
  static String get accounts      => _ru ? 'Счета'           : 'Accounts';
  static String get totalBalance  => _ru ? 'Общий баланс'    : 'Total balance';
  static String get newAccount    => _ru ? 'Новый счёт'      : 'New account';
  static String get editAccount   => _ru ? 'Редактировать счёт' : 'Edit account';
  static String get initialBalance => _ru ? 'Начальный баланс' : 'Initial balance';
  static String get debitCard     => _ru ? 'Дебетовая карта' : 'Debit card';
  static String get cash          => _ru ? 'Наличные'        : 'Cash';
  static String get creditCard    => _ru ? 'Кредитная карта' : 'Credit card';
  static String get savings       => _ru ? 'Накопительный счёт' : 'Savings';

  // Budget
  static String get budget        => _ru ? 'Бюджет'          : 'Budget';
  static String get totalBudget   => _ru ? 'Общий бюджет'    : 'Total budget';
  static String get remaining     => _ru ? 'Осталось'        : 'Remaining';
  static String get overBudget    => _ru ? 'Перерасход'      : 'Over budget';
  static String get noBudgets     => _ru ? 'Бюджеты не настроены' : 'No budgets set';
  static String get tapToAdd      => _ru ? 'Нажмите + чтобы добавить' : 'Tap + to add';
  static String get newBudget     => _ru ? 'Новый бюджет'    : 'New budget';
  static String get limit         => _ru ? 'Лимит'           : 'Limit';
  static String get addBudget     => _ru ? 'Добавить бюджет' : 'Add budget';
  static String get allCatsHaveBudget => _ru
      ? 'Все категории уже имеют бюджет на этот месяц'
      : 'All categories already have a budget this month';
  static String get spent         => _ru ? 'Потрачено'       : 'Spent';
  static String get of            => _ru ? 'из'              : 'of';
  static String spentOf(String s, String l) => _ru ? 'Потрачено $s из $l' : 'Spent $s of $l';

  // Reports
  static String get reports        => _ru ? 'Отчёты'             : 'Reports';
  static String get trend6months   => _ru ? 'Динамика за 6 месяцев' : '6-month trend';
  static String get byCategory     => _ru ? 'По категориям'      : 'By category';
  static String get noExpenses     => _ru ? 'Нет расходов за этот месяц' : 'No expenses this month';
  static String get noData         => _ru ? 'Нет данных'         : 'No data';
  static String get total          => _ru ? 'Общий'              : 'Total';
  static String get byDay          => _ru ? 'По дням'            : 'By day';
  static String get byWeek         => _ru ? 'По неделям'         : 'By week';
  static String get byMonth        => _ru ? 'По месяцам'         : 'By month';
  static String get byYear         => _ru ? 'По годам'           : 'By year';

  // Profile
  static String get profile        => _ru ? 'Профиль'            : 'Profile';
  static String get guest          => _ru ? 'Гость'              : 'Guest';
  static String get loginOrRegister => _ru ? 'Войти или зарегистрироваться' : 'Sign in or register';
  static String get appSection     => _ru ? 'Приложение'         : 'Application';
  static String get language       => _ru ? 'Язык'               : 'Language';
  static String get syncSection    => _ru ? 'Синхронизация'      : 'Synchronization';
  static String get cloudSync      => _ru ? 'Синхронизация с облаком' : 'Cloud sync';
  static String get signInToEnable => _ru ? 'Войдите, чтобы включить' : 'Sign in to enable';
  static String get syncNow        => _ru ? 'Синхронизировать сейчас' : 'Sync now';
  static String get syncing        => _ru ? 'Синхронизация...'   : 'Syncing...';
  static String get lastSync       => _ru ? 'Последняя синхронизация' : 'Last sync';
  static String get never          => _ru ? 'Никогда'            : 'Never';
  static String get dataSection    => _ru ? 'Данные'             : 'Data';
  static String get exportData     => _ru ? 'Экспорт данных'     : 'Export data';
  static String get importData     => _ru ? 'Импорт данных'      : 'Import data';
  static String get clearData      => _ru ? 'Очистить данные'    : 'Clear data';
  static String get aboutSection   => _ru ? 'О приложении'       : 'About';
  static String get version        => _ru ? 'Версия'             : 'Version';
  static String get rateApp        => _ru ? 'Оценить приложение' : 'Rate the app';
  static String get contactUs      => _ru ? 'Написать нам'       : 'Contact us';
  static String get logout         => _ru ? 'Выйти'              : 'Sign out';
  static String get deleteAccount  => _ru ? 'Удалить аккаунт'   : 'Delete account';
}
