import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n.dart';
import 'screens/clients_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/reports_screen.dart';
import 'settings.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.I.init();
  runApp(const UchetApp());
}

class UchetApp extends StatefulWidget {
  const UchetApp({super.key});

  @override
  State<UchetApp> createState() => _UchetAppState();
}

class _UchetAppState extends State<UchetApp> {
  final _settings = AppSettings.I;
  late String _lang = _settings.lang;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    setState(() {});
    if (_settings.lang != _lang) {
      _lang = _settings.lang;
      // Тексты берутся из глобального t, поэтому после смены языка
      // перерисовываем всё дерево целиком (включая открытые экраны).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        void rebuild(Element e) {
          e.markNeedsBuild();
          e.visitChildren(rebuild);
        }

        (context as Element).visitChildren(rebuild);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return MaterialApp(
      title: t.appTitle,
      debugShowCheckedModeBanner: false,
      locale: Locale(s.lang),
      supportedLocales: const [Locale('ru'), Locale('uz'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: s.themeMode,
      theme: buildTheme(Brightness.light, s.accent),
      darkTheme: buildTheme(Brightness.dark, s.accent),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenClients: () => setState(() => _tab = 1)),
      const ClientsScreen(),
      const OrdersScreen(),
      const ExpensesScreen(),
      const ReportsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.space_dashboard_outlined),
            selectedIcon: const Icon(Icons.space_dashboard_rounded),
            label: t.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: t.tabClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handyman_outlined),
            selectedIcon: const Icon(Icons.handyman_rounded),
            label: t.tabOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: t.tabExpenses,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insert_chart_outlined_rounded),
            selectedIcon: const Icon(Icons.insert_chart_rounded),
            label: t.tabReports,
          ),
        ],
      ),
    );
  }
}
