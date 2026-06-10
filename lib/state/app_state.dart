import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/constants.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/recurring.dart';
import '../models/portfolio.dart';
import '../models/budget.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/market_api.dart';

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  final FirestoreService _fs = FirestoreService();

  User? user;
  bool authLoading = true;

  List<String> accounts = List.of(defaultAccounts);
  List<String> expenseCats = List.of(defaultExpenseCats);
  List<Tx> transactions = [];
  List<Debt> debts = [];
  List<Recurring> recurring = [];
  List<PortfolioItem> portfolio = [];
  List<CustomBudget> customBudgets = [];

  /// API key Anthropic untuk fitur Scan AI (tersimpan di Firestore user,
  /// fallback ke --dart-define=ANTHROPIC_API_KEY saat build).
  String aiApiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');

  bool hideIncome = false, hideExpense = false, hideLiquid = false;
  bool hidePeriod = false, hideInvest = false, hideNetWorth = false;

  final Map<int, ({num? value, int fetchedAt, String? error})> marketPrices = {};
  bool marketLoading = false;
  int? marketLastSync;

  ({String message, String type})? popup;
  Timer? _popupTimer;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _stateSub;

  void init() {
    _authSub = auth.authStateChanges.listen((u) {
      user = u;
      authLoading = false;
      _stateSub?.cancel();
      if (u == null) {
        accounts = List.of(defaultAccounts);
        expenseCats = List.of(defaultExpenseCats);
        transactions = [];
        debts = [];
        recurring = [];
        portfolio = [];
        customBudgets = [];
        aiApiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
      } else {
        _stateSub = _fs.watchStateFor(u.uid).listen(_onSnapshot);
      }
      notifyListeners();
    });
  }

  void _onSnapshot(Map<String, dynamic>? data) {
    if (data == null) return;
    if (data['accounts'] is List) accounts = List<String>.from(data['accounts']);
    if (data['expenseCats'] is List) expenseCats = List<String>.from(data['expenseCats']);
    if (data['transactions'] is List) {
      transactions = (data['transactions'] as List)
          .whereType<Map>()
          .map((m) => Tx.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (data['debts'] is List) {
      debts = (data['debts'] as List)
          .whereType<Map>()
          .map((m) => Debt.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (data['recurring'] is List) {
      recurring = (data['recurring'] as List)
          .whereType<Map>()
          .map((m) => Recurring.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (data['portfolio'] is List) {
      portfolio = (data['portfolio'] as List)
          .whereType<Map>()
          .map((m) => PortfolioItem.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (data['customBudgets'] is List) {
      customBudgets = (data['customBudgets'] as List)
          .whereType<Map>()
          .map((m) => CustomBudget.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (data['aiApiKey'] is String && (data['aiApiKey'] as String).isNotEmpty) {
      aiApiKey = data['aiApiKey'] as String;
    }
    notifyListeners();
  }

  Future<void> setAiApiKey(String key) async {
    aiApiKey = key.trim();
    notifyListeners();
    await _fs.saveField('aiApiKey', aiApiKey);
  }

  Future<void> _saveTransactions() async =>
      _fs.saveField('transactions', transactions.map((t) => t.toMap()).toList());
  Future<void> _saveDebts() async =>
      _fs.saveField('debts', debts.map((d) => d.toMap()).toList());
  Future<void> _saveRecurring() async =>
      _fs.saveField('recurring', recurring.map((r) => r.toMap()).toList());
  Future<void> _savePortfolio() async =>
      _fs.saveField('portfolio', portfolio.map((p) => p.toMap()).toList());
  Future<void> _saveBudgets() async =>
      _fs.saveField('customBudgets', customBudgets.map((b) => b.toMap()).toList());
  Future<void> _saveAccounts() async => _fs.saveField('accounts', accounts);
  Future<void> _saveExpenseCats() async => _fs.saveField('expenseCats', expenseCats);

  void showPopup(String message, {String type = 'success'}) {
    popup = (message: message, type: type);
    notifyListeners();
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 3), () {
      popup = null;
      notifyListeners();
    });
  }

  Future<void> addTransaction(Tx tx) async {
    transactions = [...transactions, tx];
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> addTransactions(List<Tx> txs) async {
    transactions = [...transactions, ...txs];
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> updateTransaction(Tx tx) async {
    transactions = transactions.map((t) => t.id == tx.id ? tx : t).toList();
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    transactions = transactions.where((t) => t.id != id).toList();
    notifyListeners();
    await _saveTransactions();
    showPopup('Transaksi Dihapus', type: 'error');
  }

  Future<void> addDebt(Debt d) async {
    debts = [...debts, d];
    notifyListeners();
    await _saveDebts();
  }

  Future<void> updateDebt(Debt d) async {
    debts = debts.map((x) => x.id == d.id ? d : x).toList();
    notifyListeners();
    await _saveDebts();
  }

  Future<void> deleteDebt(int id) async {
    debts = debts.where((d) => d.id != id).toList();
    notifyListeners();
    await _saveDebts();
    showPopup('Catatan Utang/Piutang Dihapus', type: 'error');
  }

  Future<void> addRecurring(Recurring r) async {
    recurring = [...recurring, r];
    notifyListeners();
    await _saveRecurring();
  }

  Future<void> updateRecurring(Recurring r) async {
    recurring = recurring.map((x) => x.id == r.id ? r : x).toList();
    notifyListeners();
    await _saveRecurring();
  }

  Future<void> deleteRecurring(int id) async {
    recurring = recurring.where((r) => r.id != id).toList();
    notifyListeners();
    await _saveRecurring();
    showPopup('Tagihan Rutin Dihapus', type: 'error');
  }

  Future<void> addPortfolio(PortfolioItem p) async {
    portfolio = [...portfolio, p];
    notifyListeners();
    await _savePortfolio();
  }

  Future<void> updatePortfolio(PortfolioItem p) async {
    portfolio = portfolio.map((x) => x.id == p.id ? p : x).toList();
    notifyListeners();
    await _savePortfolio();
  }

  Future<void> setPortfolioList(List<PortfolioItem> list) async {
    portfolio = list;
    notifyListeners();
    await _savePortfolio();
  }

  Future<void> deletePortfolio(int id) async {
    portfolio = portfolio.where((p) => p.id != id).toList();
    notifyListeners();
    await _savePortfolio();
  }

  Future<void> upsertBudget(CustomBudget b) async {
    final exists = customBudgets.any((x) => x.id == b.id);
    customBudgets = exists
        ? customBudgets.map((x) => x.id == b.id ? b : x).toList()
        : [...customBudgets, b];
    notifyListeners();
    await _saveBudgets();
  }

  Future<void> deleteBudget(int id) async {
    customBudgets = customBudgets.where((b) => b.id != id).toList();
    notifyListeners();
    await _saveBudgets();
  }

  Future<bool> addAccount(String name) async {
    final n = name.trim();
    if (n.isEmpty || accounts.contains(n)) return false;
    accounts = [...accounts, n];
    notifyListeners();
    await _saveAccounts();
    return true;
  }

  Future<bool> addExpenseCat(String name) async {
    final n = name.trim();
    if (n.isEmpty || expenseCats.contains(n)) return false;
    expenseCats = [...expenseCats, n];
    notifyListeners();
    await _saveExpenseCats();
    return true;
  }

  Future<void> mergeImported({
    required List<Tx> newTxs,
    required Set<String> newCats,
    required Set<String> newAccs,
  }) async {
    transactions = [...transactions, ...newTxs];
    bool catsChanged = false;
    final mergedCats = List<String>.from(expenseCats);
    for (final c in newCats) {
      if (!mergedCats.contains(c) && !incomeCategories.contains(c)) {
        mergedCats.add(c);
        catsChanged = true;
      }
    }
    if (catsChanged) expenseCats = mergedCats;

    bool accsChanged = false;
    final mergedAccs = List<String>.from(accounts);
    for (final a in newAccs) {
      if (!mergedAccs.contains(a)) {
        mergedAccs.add(a);
        accsChanged = true;
      }
    }
    if (accsChanged) accounts = mergedAccs;

    notifyListeners();
    await _saveTransactions();
    if (catsChanged) await _saveExpenseCats();
    if (accsChanged) await _saveAccounts();
  }

  Future<({int ok, int failed})> refreshMarketPrices() async {
    final targets = portfolio.where((p) => supportsAutoFetch(p.type)).toList();
    if (targets.isEmpty) {
      marketLastSync = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
      return (ok: 0, failed: 0);
    }
    marketLoading = true;
    notifyListeners();
    int ok = 0, failed = 0;
    final updated = List<PortfolioItem>.from(portfolio);
    for (final item in targets) {
      try {
        final v = await fetchPriceForAsset(
          type: item.type,
          name: item.name,
          marketSymbol: item.marketSymbol,
        );
        marketPrices[item.id] = (
          value: v,
          fetchedAt: DateTime.now().millisecondsSinceEpoch,
          error: null
        );
        final idx = updated.indexWhere((p) => p.id == item.id);
        if (idx >= 0) updated[idx] = updated[idx].copyWith(currentPrice: v);
        ok++;
      } catch (e) {
        marketPrices[item.id] = (
          value: null,
          fetchedAt: DateTime.now().millisecondsSinceEpoch,
          error: e.toString()
        );
        failed++;
      }
    }
    portfolio = updated;
    marketLoading = false;
    marketLastSync = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    await _savePortfolio();
    return (ok: ok, failed: failed);
  }

  void toggleHide(String key) {
    switch (key) {
      case 'income':   hideIncome   = !hideIncome;   break;
      case 'expense':  hideExpense  = !hideExpense;  break;
      case 'liquid':   hideLiquid   = !hideLiquid;   break;
      case 'period':   hidePeriod   = !hidePeriod;   break;
      case 'invest':   hideInvest   = !hideInvest;   break;
      case 'networth': hideNetWorth = !hideNetWorth; break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _stateSub?.cancel();
    _popupTimer?.cancel();
    super.dispose();
  }
}

extension AppDerived on AppState {
  List<Tx> filteredBy(String startIso, String endIso) {
    final start = DateTime.parse(startIso);
    final end = DateTime.parse(endIso);
    final list = transactions.where((t) {
      final d = DateTime.parse(t.date);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    list.sort((a, b) {
      final cmp = b.date.compareTo(a.date);
      if (cmp != 0) return cmp;
      return (b.time ?? '').compareTo(a.time ?? '');
    });
    return list;
  }

  ({num income, num expense, num balance}) summaryFor(List<Tx> list) {
    num inc = 0, exp = 0;
    for (final t in list) {
      if (t.type == 'income') inc += t.amount;
      if (t.type == 'expense') exp += t.amount;
    }
    return (income: inc, expense: exp, balance: inc - exp);
  }

  Map<String, num> get accountBalances {
    final balances = <String, num>{for (final a in accounts) a: 0};
    for (final t in transactions) {
      balances.putIfAbsent(t.account, () => 0);
      if (t.isInflow) {
        balances[t.account] = (balances[t.account] ?? 0) + t.amount;
      } else {
        balances[t.account] = (balances[t.account] ?? 0) - t.amount;
      }
    }
    return balances;
  }

  Map<String, num> get liquidBalances {
    final liq = Map<String, num>.from(accountBalances);
    for (final p in portfolio) {
      if (p.type == 'Tabungan Bank' && p.account.isNotEmpty && liq.containsKey(p.account)) {
        liq[p.account] = (liq[p.account] ?? 0) - p.buyPrice;
      }
    }
    return liq;
  }

  num get totalLiquidCash =>
      liquidBalances.values.fold<num>(0, (s, v) => s + v);

  ({num piutang, num utang}) get debtSummary {
    num pi = 0, ut = 0;
    for (final d in debts) {
      if (d.status == 'unpaid') {
        if (d.type == 'piutang') pi += d.amount;
        if (d.type == 'utang') ut += d.amount;
      }
    }
    return (piutang: pi, utang: ut);
  }

  ({num savings, num investments, num total}) get investSummary {
    num s = 0, i = 0;
    for (final p in portfolio) {
      final multiplier = p.type == 'Saham' ? 100 : 1;
      final priceNow = p.currentPrice ?? p.buyPrice;
      final val = p.type == 'Tabungan Bank'
          ? p.buyPrice
          : (p.amount * multiplier * priceNow);
      if (p.type == 'Tabungan Bank') {
        s += p.buyPrice;
      } else {
        i += val;
      }
    }
    return (savings: s, investments: i, total: s + i);
  }

  num get totalNetWorth {
    final s = investSummary;
    final d = debtSummary;
    return totalLiquidCash + s.total + d.piutang - d.utang;
  }
}
