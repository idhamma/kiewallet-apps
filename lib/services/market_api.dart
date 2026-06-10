import 'dart:convert';
import 'package:http/http.dart' as http;

const _corsProxy = 'https://corsproxy.io/?';

Future<Map<String, dynamic>> _safeFetch(String url) async {
  final res = await http.get(Uri.parse(url));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode} for $url');
  }
  return json.decode(res.body) as Map<String, dynamic>;
}

const Map<String, String> _cryptoAliases = {
  'btc': 'bitcoin', 'eth': 'ethereum', 'sol': 'solana', 'bnb': 'binancecoin',
  'ada': 'cardano', 'xrp': 'ripple', 'doge': 'dogecoin', 'matic': 'matic-network',
  'ton': 'the-open-network', 'dot': 'polkadot', 'trx': 'tron', 'usdt': 'tether',
  'usdc': 'usd-coin', 'link': 'chainlink', 'avax': 'avalanche-2',
};

String resolveCryptoId(String symbolOrName) {
  final k = symbolOrName.trim().toLowerCase();
  return _cryptoAliases[k] ?? k;
}

Future<num> fetchCryptoPrice(String symbol) async {
  final id = resolveCryptoId(symbol);
  final data = await _safeFetch(
    'https://api.coingecko.com/api/v3/simple/price?ids=${Uri.encodeComponent(id)}&vs_currencies=idr',
  );
  final price = (data[id] as Map?)?['idr'];
  if (price is! num) throw Exception('Crypto "$symbol" tidak ditemukan di CoinGecko');
  return price;
}

String _yahooUrl(String ticker, {String range = '1d', String interval = '1d'}) =>
    'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(ticker)}.JK?range=$range&interval=$interval';

Future<Map<String, dynamic>> _fetchYahoo(String url) async {
  try {
    return await _safeFetch(url);
  } catch (_) {
    return await _safeFetch('$_corsProxy${Uri.encodeComponent(url)}');
  }
}

Future<num> fetchStockPrice(String ticker) async {
  final symbol = ticker.trim().toUpperCase();
  if (symbol.isEmpty) throw Exception('Ticker saham kosong');
  final data = await _fetchYahoo(_yahooUrl(symbol));
  final result = ((data['chart'] as Map?)?['result'] as List?)?.first as Map?;
  final price = (result?['meta'] as Map?)?['regularMarketPrice'];
  if (price is! num) throw Exception('Saham $symbol tidak ditemukan di Yahoo Finance');
  return price;
}

Future<List<({int time, num price})>> fetchStockHistory(String ticker,
    {String range = '1mo', String interval = '1d'}) async {
  final symbol = ticker.trim().toUpperCase();
  if (symbol.isEmpty) return [];
  final data = await _fetchYahoo(_yahooUrl(symbol, range: range, interval: interval));
  final result = ((data['chart'] as Map?)?['result'] as List?)?.first as Map?;
  if (result == null) return [];
  final ts = (result['timestamp'] as List?) ?? const [];
  final closes = (((result['indicators'] as Map?)?['quote'] as List?)?.first as Map?)?['close']
          as List? ??
      const [];
  final out = <({int time, num price})>[];
  for (var i = 0; i < ts.length; i++) {
    final c = i < closes.length ? closes[i] : null;
    if (c is num) out.add((time: (ts[i] as num).toInt() * 1000, price: c));
  }
  return out;
}

Future<List<({int time, num price})>> fetchCryptoHistory(String symbol,
    {int days = 30}) async {
  final id = resolveCryptoId(symbol);
  final data = await _safeFetch(
    'https://api.coingecko.com/api/v3/coins/${Uri.encodeComponent(id)}/market_chart?vs_currency=idr&days=$days',
  );
  final prices = (data['prices'] as List?) ?? const [];
  return prices
      .map<({int time, num price})>(
          (p) => (time: (p[0] as num).toInt(), price: p[1] as num))
      .toList();
}

Future<num> fetchGoldPrice() async {
  final data = await _safeFetch('https://logam-mulia-api.vercel.app/prices/anekalogam');
  final items = (data['data'] as List?) ?? const [];
  Map? pick;
  for (final it in items) {
    if (it is Map && (it['weight'] as num?)?.toInt() == 1) {
      pick = it;
      break;
    }
  }
  pick ??= items.isNotEmpty ? items.first as Map : null;
  final price = (pick?['sell'] as num?) ?? (pick?['price'] as num?);
  if (price is! num) throw Exception('Gagal mengambil harga emas Antam');
  return price;
}

const Set<String> _supportedTypes = {'Crypto', 'Saham', 'Logam Mulia / Emas'};
bool supportsAutoFetch(String type) => _supportedTypes.contains(type);

Future<num> fetchPriceForAsset({
  required String type,
  required String name,
  String? marketSymbol,
}) async {
  final sym = ((marketSymbol ?? '').isNotEmpty ? marketSymbol! : name).trim();
  if (type == 'Crypto') return fetchCryptoPrice(sym);
  if (type == 'Saham') return fetchStockPrice(sym);
  if (type == 'Logam Mulia / Emas') return fetchGoldPrice();
  throw Exception('Tipe "$type" tidak didukung auto-fetch');
}

Future<List<({int time, num price})>> fetchHistoryForAsset({
  required String type,
  required String name,
  String? marketSymbol,
  int days = 30,
}) async {
  final sym = ((marketSymbol ?? '').isNotEmpty ? marketSymbol! : name).trim();
  if (type == 'Crypto') return fetchCryptoHistory(sym, days: days);
  if (type == 'Saham') {
    final range = days <= 7 ? '5d' : days <= 31 ? '1mo' : days <= 93 ? '3mo' : '6mo';
    return fetchStockHistory(sym, range: range, interval: '1d');
  }
  return [];
}
