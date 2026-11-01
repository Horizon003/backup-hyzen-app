import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/storage/local_store.dart';
import '../../content/domain/site_models.dart';

/// CONFIRMED legacy cart item `{productId,name,qty,price,variant}` (device-local, pw_cart).
class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
    this.variant = '',
  });
  final String productId;
  final String name;
  final int qty;
  final num price;
  final String variant;
  String get key => '$productId|$variant';
  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'qty': qty,
    'price': price,
    'variant': variant,
  };
  static CartItem? fromMap(Map<String, dynamic> m) {
    final id = m['productId'];
    if (id is! String) return null;
    return CartItem(
      productId: id,
      name: (m['name'] as String?) ?? '',
      qty: (m['qty'] as num?)?.toInt() ?? 1,
      price: (m['price'] as num?) ?? 0,
      variant: (m['variant'] as String?) ?? '',
    );
  }

  CartItem withQty(int q) => CartItem(
    productId: productId,
    name: name,
    qty: q,
    price: price,
    variant: variant,
  );
}

class CartController extends Notifier<List<CartItem>> {
  String get _k =>
      'items_${ref.read(authStateProvider).valueOrNull?.uid ?? 'guest'}';
  JsonBox get _box => JsonBox(Boxes.cart);

  @override
  List<CartItem> build() {
    ref.watch(authStateProvider.select((v) => v.valueOrNull?.uid));
    final m = JsonBox(Boxes.cart).get(_k);
    final l = m?['items'];
    if (l is! List) return [];
    return l
        .whereType<Map>()
        .map((e) => CartItem.fromMap(e.cast<String, dynamic>()))
        .whereType<CartItem>()
        .toList();
  }

  void _save(List<CartItem> l) {
    state = l;
    _box.put(_k, {'items': l.map((e) => e.toMap()).toList()});
  }

  /// Returns an error message when stock would be exceeded (legacy availStock guard).
  String? add(Product p, {int qty = 1, String variant = ''}) {
    if (qty < 1) return 'Choose a quantity greater than zero';
    final inCart = state
        .where((i) => i.productId == p.id)
        .fold(0, (s, i) => s + i.qty);
    final avail = p.availStock;
    if (avail <= 0) return '"${p.name}" is out of stock';
    if (inCart + qty > avail) return 'Only $avail of "${p.name}" available';
    final l = [...state];
    final i = l.indexWhere((x) => x.productId == p.id && x.variant == variant);
    if (i >= 0) {
      l[i] = l[i].withQty(l[i].qty + qty);
    } else {
      l.add(
        CartItem(
          productId: p.id,
          name: p.name,
          qty: qty,
          price: p.price,
          variant: variant,
        ),
      );
    }
    _save(l);
    return null;
  }

  void setQty(CartItem it, int q) {
    _save(
      state.map((x) => x.key == it.key ? x.withQty(max(1, q)) : x).toList(),
    );
  }

  void remove(CartItem it) =>
      _save(state.where((x) => x.key != it.key).toList());
  void clear() => _save([]);

  num get subtotal => state.fold<num>(0, (s, i) => s + i.price * i.qty);
  int get count => state.fold(0, (s, i) => s + i.qty);
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(
  CartController.new,
);
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.qty),
);

// ---------------- Orders ----------------
final _rnd = Random.secure();

/// CONFIRMED `"PW-"+year+"-"+(100000..999999)`.
String newOrderNumber([DateTime? now]) =>
    'PW-${(now ?? DateTime.now()).year}-${_rnd.nextInt(900000) + 100000}';

/// CONFIRMED legacy `uid(p)` = p + "-" + 6 base36 chars.
String legacyUid(String prefix) {
  const a = '0123456789abcdefghijklmnopqrstuvwxyz';
  return '$prefix-${List.generate(6, (_) => a[_rnd.nextInt(36)]).join()}';
}

/// CONFIRMED `verifyToken()` = "v_" + 32 hex (128-bit).
String newVerifyToken() =>
    'v_${List.generate(16, (_) => _rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

class CheckoutForm {
  CheckoutForm({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.phoneSecondary,
    required this.line1,
    required this.city,
    required this.province,
    required this.deliveryAddress,
    required this.notes,
  });
  final String firstName,
      lastName,
      phone,
      phoneSecondary,
      line1,
      city,
      province,
      deliveryAddress,
      notes;
}

/// Builds the exact legacy order object (placeOrder in v2).
Map<String, dynamic> buildOrder({
  required List<CartItem> cart,
  required CheckoutForm f,
  required String email,
  required DeliverySettings delivery,
  required String orderNumber,
  DateTime? now,
}) {
  final sub = cart.fold<num>(0, (s, i) => s + i.price * i.qty);
  final del = delivery.chargeFor(sub, f.province);
  return {
    'id': legacyUid('ord'),
    'orderNumber': orderNumber,
    'verifyToken': newVerifyToken(),
    'items': cart
        .map(
          (i) => {
            'productId': i.productId,
            'name': i.name + (i.variant.isNotEmpty ? ' (${i.variant})' : ''),
            'qty': i.qty,
            'price': i.price,
          },
        )
        .toList(),
    'customer': {
      'firstName': f.firstName.trim(),
      'lastName': f.lastName.trim(),
      'phone': f.phone.trim(),
      'phoneSecondary': f.phoneSecondary.trim(),
      'email': email,
    },
    'address': {
      'line1': f.line1.trim(),
      'city': f.city.trim(),
      'province': f.province,
      'deliveryAddress': f.deliveryAddress.trim(),
      'notes': f.notes.trim(),
    },
    'totals': {'subtotal': sub, 'delivery': del, 'grandTotal': sub + del},
    'status': 'Pending',
    'payment': 'Unpaid',
    'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

/// CONFIRMED masked public snapshot for verifications/{token}.
Map<String, dynamic> verificationSnapshot(Map<String, dynamic> o) {
  final c = (o['customer'] as Map?) ?? {};
  final a = (o['address'] as Map?) ?? {};
  return {
    'orderNumber': o['orderNumber'],
    'status': o['status'],
    'payment': o['payment'],
    'createdAt': o['createdAt'],
    'trackingId': o['trackingId'] ?? '',
    'totals': {'grandTotal': ((o['totals'] as Map?) ?? {})['grandTotal'] ?? 0},
    'items': ((o['items'] as List?) ?? [])
        .map((i) => {'name': i['name'], 'qty': i['qty'], 'price': i['price']})
        .toList(),
    'customer': {
      'firstName': c['firstName'] ?? '',
      'lastName': c['lastName'] ?? '',
      'phone': c['phone'] ?? '',
    },
    'address': {'city': a['city'] ?? '', 'province': a['province'] ?? ''},
  };
}

class OrdersRepository {
  OrdersRepository(this._db);
  final FirebaseFirestore _db;

  /// CONFIRMED Cloud.submitOrder: orders_inbox/{id} {value, createdAt:ms} + verifications/{token}.
  Future<void> submit(Map<String, dynamic> o) async {
    try {
      await _db
          .collection('orders_inbox')
          .doc(o['id'] as String)
          .set({'value': o, 'createdAt': DateTime.now().millisecondsSinceEpoch})
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw FriendlyException(
        'We couldn\u2019t place your order. Check your connection and try again.',
      );
    }
    try {
      await _db
          .collection('verifications')
          .doc(o['verifyToken'] as String)
          .set(verificationSnapshot(o));
    } catch (_) {
      // Non-fatal (legacy also tolerates this); admin re-syncs verifications on drain.
    }
  }

  /// Public masked status lookup (CONFIRMED: verifications are public get).
  Future<Map<String, dynamic>?> verification(String token) async {
    final s = await _db.collection('verifications').doc(token).get();
    return s.data();
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(firestoreProvider)),
);

/// Orders placed on this device (legacy also kept a local copy).
class MyOrdersController extends Notifier<List<Map<String, dynamic>>> {
  JsonBox get _box => JsonBox(Boxes.myOrders);
  @override
  List<Map<String, dynamic>> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    final l =
        JsonBox(Boxes.myOrders)
            .values()
            .where(
              (o) =>
                  o['ownerUid'] == user?.uid ||
                  (o['ownerUid'] == null &&
                      (o['customer'] as Map?)?['email'] == user?.email),
            )
            .toList()
          ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    return l;
  }

  Future<void> add(Map<String, dynamic> o) async {
    final local = {
      ...o,
      'ownerUid': ref.read(authStateProvider).valueOrNull?.uid,
    };
    await _box.put(o['id'] as String, local);
    state = [local, ...state.where((v) => v['id'] != o['id'])];
  }

  Future<void> updateStatus(String id, Map<String, dynamic> v) async {
    final i = state.indexWhere((o) => o['id'] == id);
    if (i < 0) return;
    final o = {
      ...state[i],
      'status': v['status'] ?? state[i]['status'],
      'payment': v['payment'] ?? state[i]['payment'],
      'trackingId': v['trackingId'] ?? state[i]['trackingId'],
    };
    await _box.put(id, o);
    state = [...state]..[i] = o;
  }
}

final myOrdersProvider =
    NotifierProvider<MyOrdersController, List<Map<String, dynamic>>>(
      MyOrdersController.new,
    );

// ---------------- Contact ----------------
/// CONFIRMED sendMessage: `{id:"msg-xxxxxx",name,email,whatsapp,subject,body,read:false,createdAt}`
/// → messages_inbox/{id} `{value, createdAt:ms}` (create-only).
Future<void> submitContactMessage(
  FirebaseFirestore db, {
  required String name,
  required String email,
  required String whatsapp,
  required String subject,
  required String body,
}) async {
  final m = {
    'id': legacyUid('msg'),
    'name': name.trim(),
    'email': email.trim(),
    'whatsapp': whatsapp.trim(),
    'subject': subject.trim(),
    'body': body.trim(),
    'read': false,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };
  try {
    await db
        .collection('messages_inbox')
        .doc(m['id'] as String)
        .set({'value': m, 'createdAt': DateTime.now().millisecondsSinceEpoch})
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    throw FriendlyException(
      'Message not sent. Check your connection and try again.',
    );
  }
}
