import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../content/data/content_providers.dart';
import '../../content/data/content_source.dart';
import '../../content/domain/site_models.dart';
import '../../shell/app_shell.dart';
import '../data/shop_controllers.dart';

class _CartButton extends ConsumerWidget {
  const _CartButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(cartCountProvider);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _cat = 'All';
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(siteSettingsProvider);
    final t = Theme.of(context);
    if (!s.sectionEnabled('shop') || s.shopComingSoon) {
      return TabPage(
        title: 'Shop',
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
            sliver: SliverList.list(
              children: [
                SurfacePanel(
                  radius: HRadius.xl,
                  padding: const EdgeInsets.all(HSpace.xl),
                  child: Column(
                    children: [
                      const IconBadge(
                        icon: Icons.shopping_bag_rounded,
                        color: HColors.special,
                        size: 72,
                      ),
                      const Gap(HSpace.md),
                      Text(
                        'THE PHARMACY EDIT',
                        style: t.textTheme.labelSmall?.copyWith(
                          color: HColors.special,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'Good things.\nWorth the wait.',
                        style: t.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(HSpace.sm),
                      Text(
                        'Thoughtful essentials for your labs, classes and clinical days.',
                        style: t.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(HSpace.md),
                      const StatusPill(
                        label: 'Shop coming soon',
                        color: HColors.special,
                        icon: Icons.schedule_rounded,
                      ),
                      const Gap(HSpace.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          Chip(label: Text('Lab essentials')),
                          Chip(label: Text('Study companions')),
                          Chip(label: Text('Everyday care')),
                        ],
                      ),
                      const Gap(HSpace.lg),
                      HButton(
                        label: 'Explore notes',
                        onPressed: () => context.go('/study/notes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final catalog = asMap(
      ref.watch(contentProvider('pw_catalog_settings')).valueOrNull?.value,
    );
    final spacing = (num.tryParse('${catalog['gridSpacing']}') ?? 14)
        .clamp(8, 24)
        .toDouble();
    final async = ref.watch(productsProvider);
    final products = async.valueOrNull?.data ?? const <Product>[];
    final cats = [
      'All',
      ...{
        for (final p in products)
          if (p.category.isNotEmpty) p.category,
      },
    ];
    final list =
        products
            .where(
              (p) =>
                  (_cat == 'All' || p.category == _cat) &&
                  (_q.isEmpty ||
                      p.name.toLowerCase().contains(_q.toLowerCase())),
            )
            .toList()
          ..sort((a, b) => (b.featured ? 1 : 0) - (a.featured ? 1 : 0));
    return TabPage(
      title: 'Shop',
      subtitle: 'Cash on delivery',
      actions: const [_CartButton()],
      onRefresh: () => refreshContent(ref, ['pw_products', 'pw_delivery']),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HSearchField(
                  hint: 'Search products',
                  onChanged: (v) => setState(() => _q = v),
                ),
                const Gap(HSpace.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _cat == c,
                            onSelected: (_) => setState(() => _cat = c),
                          ),
                        ),
                    ],
                  ),
                ),
                const Gap(HSpace.md),
              ],
            ),
          ),
        ),
        if (async.isLoading && products.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(HSpace.screen),
              child: SkeletonList(count: 4, height: 160),
            ),
          )
        else if (async.hasError && products.isEmpty)
          SliverToBoxAdapter(
            child: ErrorState(
              message: 'Couldn\u2019t load products.',
              onRetry: () => refreshContent(ref, ['pw_products']),
            ),
          )
        else if (list.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 600
                    ? (int.tryParse('${catalog['mobileColumns']}') ?? 2).clamp(
                        1,
                        2,
                      )
                    : MediaQuery.sizeOf(context).width < 1000
                    ? (int.tryParse('${catalog['tabletColumns']}') ?? 3).clamp(
                        2,
                        3,
                      )
                    : (int.tryParse('${catalog['desktopColumns']}') ?? 4).clamp(
                        2,
                        4,
                      ),
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: .66,
              ),
              itemCount: list.length,
              itemBuilder: (c, i) => _ProductCard(p: list[i]),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.p});
  final Product p;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final out = p.availStock <= 0;
    final catalog = asMap(
      ref.watch(contentProvider('pw_catalog_settings')).valueOrNull?.value,
    );
    final radius = (num.tryParse('${catalog['cardRadius']}') ?? 16)
        .clamp(0, 40)
        .toDouble();
    final shadow = switch (catalog['cardShadow']) {
      'none' => 0.0,
      'medium' => 8.0,
      'elevated' => 16.0,
      _ => 4.0,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow == 0
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: shadow,
                  offset: Offset(0, shadow / 3),
                ),
              ],
      ),
      child: HCard(
        radius: radius,
        padding: const EdgeInsets.all(8),
        onTap: () => context.push('/shop/p/${p.id}'),
        semanticLabel: p.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NetImage(
                p.image,
                width: double.infinity,
                radius: (radius - 4).clamp(0, 40).toDouble(),
                icon: Icons.medication_rounded,
              ),
            ),
            const Gap(8),
            if (p.category.isNotEmpty)
              Text(
                p.category.toUpperCase(),
                style: t.textTheme.labelSmall,
                maxLines: 1,
              ),
            Text(
              p.name,
              style: t.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Row(
              children: [
                Text(
                  money(p.price),
                  style: t.textTheme.titleSmall?.copyWith(
                    color: t.colorScheme.primary,
                  ),
                ),
                if (p.compareAtPrice != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    money(p.compareAtPrice!),
                    style: t.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (out)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: StatusPill(label: 'Out of stock', color: HColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final _sel = <String, String>{};
  int _qty = 1;
  int _img = 0;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = ref
        .watch(productsProvider)
        .valueOrNull
        ?.data
        .where((x) => x.id == widget.id)
        .firstOrNull;
    if (p == null) {
      return const Scaffold(
        appBar: HTopBar(title: 'Product'),
        body: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Product not available',
        ),
      );
    }
    final avail = p.availStock;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HTopBar(title: p.name, actions: const [_CartButton()]),
      body: HBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            HSpace.screen,
            MediaQuery.paddingOf(context).top + 76,
            HSpace.screen,
            120,
          ),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: NetImage(
                p.images.isEmpty
                    ? null
                    : p.images[_img.clamp(0, p.images.length - 1)],
                radius: HRadius.xl,
              ),
            ),
            if (p.images.length > 1) ...[
              const Gap(8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: p.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _img = i),
                    child: Opacity(
                      opacity: i == _img ? 1 : 0.55,
                      child: NetImage(
                        p.images[i],
                        width: 60,
                        height: 60,
                        radius: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const Gap(HSpace.md),
            PanelBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.category.isNotEmpty)
                    Text(
                      p.category.toUpperCase(),
                      style: t.textTheme.labelSmall?.copyWith(
                        color: t.colorScheme.primary,
                      ),
                    ),
                  Text(p.name, style: t.textTheme.headlineSmall),
                  const Gap(6),
                  Row(
                    children: [
                      Text(
                        money(p.price),
                        style: t.textTheme.titleLarge?.copyWith(
                          color: t.colorScheme.primary,
                        ),
                      ),
                      if (p.compareAtPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          money(p.compareAtPrice!),
                          style: t.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      StatusPill(
                        label: avail <= 0
                            ? 'Out of stock'
                            : (avail < 9999 && avail <= 5
                                  ? 'Only $avail left'
                                  : 'In stock'),
                        color: avail <= 0
                            ? HColors.error
                            : (avail <= 5 ? HColors.warning : HColors.success),
                      ),
                    ],
                  ),
                  if (p.shortDesc.isNotEmpty) ...[
                    const Gap(HSpace.sm),
                    Text(p.shortDesc, style: t.textTheme.bodyMedium),
                  ],
                  for (final v in p.variants) ...[
                    const Gap(HSpace.md),
                    Text(v.name, style: t.textTheme.titleSmall),
                    const Gap(6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in v.options)
                          ChoiceChip(
                            label: Text(o),
                            selected: _sel[v.name] == o,
                            onSelected: (_) => setState(() => _sel[v.name] = o),
                          ),
                      ],
                    ),
                  ],
                  const Gap(HSpace.md),
                  Row(
                    children: [
                      Text('Quantity', style: t.textTheme.titleSmall),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _qty > 1
                            ? () => setState(() => _qty--)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_qty', style: t.textTheme.titleMedium),
                      ),
                      IconButton.filledTonal(
                        onPressed: _qty < avail
                            ? () => setState(() => _qty++)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (p.fullDescHtml.isNotEmpty) ...[
              const Gap(HSpace.md),
              PanelBlock(child: HtmlText(p.fullDescHtml)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HSpace.md),
          child: HButton(
            label: avail <= 0
                ? 'Out of stock'
                : 'Add to cart \u00b7 ${money(p.price * _qty)}',
            icon: Icons.add_shopping_cart_rounded,
            onPressed: avail <= 0
                ? null
                : () {
                    final missing = p.variants
                        .where(
                          (v) =>
                              v.options.isNotEmpty && !_sel.containsKey(v.name),
                        )
                        .toList();
                    if (missing.isNotEmpty) {
                      showHSnack(
                        context,
                        'Choose ${missing.first.name}',
                        error: true,
                      );
                      return;
                    }
                    final variant = p.variants
                        .where((v) => _sel.containsKey(v.name))
                        .map((v) => _sel[v.name])
                        .join(' / ');
                    final err = ref
                        .read(cartProvider.notifier)
                        .add(p, qty: _qty, variant: variant);
                    showHSnack(
                      context,
                      err ?? 'Added to cart',
                      error: err != null,
                    );
                  },
          ),
        ),
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final del = ref.watch(deliveryProvider);
    final sub = cart.fold<num>(0, (s, i) => s + i.price * i.qty);
    return TabPage(
      title: 'Cart',
      subtitle: '${cart.length} item${cart.length == 1 ? '' : 's'}',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              if (cart.isEmpty)
                EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  action: HButton(
                    label: 'Browse shop',
                    // /cart is a root route; go() returns to the existing shell instead
                    // of pushing a duplicate shell (GlobalKey crash).
                    onPressed: () => context.go('/shop'),
                  ),
                ),
              for (final i in cart)
                Padding(
                  padding: const EdgeInsets.only(bottom: HSpace.sm),
                  child: HCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: t.textTheme.titleSmall),
                              if (i.variant.isNotEmpty)
                                Text(i.variant, style: t.textTheme.bodySmall),
                              Text(
                                money(i.price),
                                style: t.textTheme.bodyMedium?.copyWith(
                                  color: t.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .setQty(i, i.qty - 1),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text('${i.qty}', style: t.textTheme.titleMedium),
                        IconButton(
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .setQty(i, i.qty + 1),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () =>
                              ref.read(cartProvider.notifier).remove(i),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              if (cart.isNotEmpty) ...[
                const Gap(HSpace.sm),
                PanelBlock(
                  child: Column(
                    children: [
                      _sumRow(t, 'Subtotal', money(sub)),
                      _sumRow(t, 'Delivery', 'Calculated at checkout'),
                      const Gap(6),
                      Text(
                        'Free delivery above ${money(del.freeDeliveryThreshold)} \u00b7 Cash on delivery',
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Gap(HSpace.md),
                HButton(
                  label: 'Checkout',
                  icon: Icons.lock_rounded,
                  onPressed: () => context.push('/checkout'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _sumRow(ThemeData t, String k, String v, {bool bold = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Text(k, style: bold ? t.textTheme.titleMedium : t.textTheme.bodyMedium),
      const Spacer(),
      Text(
        v,
        style: bold
            ? t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)
            : t.textTheme.titleSmall,
      ),
    ],
  ),
);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {
    for (final k in [
      'first',
      'last',
      'phone',
      'phone2',
      'line1',
      'city',
      'deliv',
      'notes',
    ])
      k: TextEditingController(),
  };
  String _province = 'Punjab';
  bool _busy = false;
  late final String _orderNo = newOrderNumber();

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull;
    if (p != null) {
      final parts = p.fullName.trim().split(RegExp(r'\s+'));
      _c['first']!.text = parts.first;
      _c['last']!.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _c['phone']!.text = p.mobile;
      _c['city']!.text = p.city;
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _place() async {
    if (_busy || !_form.currentState!.validate()) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    // CONFIRMED: re-validate stock right before committing.
    final products =
        ref.read(productsProvider).valueOrNull?.data ?? const <Product>[];
    final wanted = <String, int>{};
    for (final i in cart) {
      wanted[i.productId] = (wanted[i.productId] ?? 0) + i.qty;
    }
    for (final e in wanted.entries) {
      final p = products.where((x) => x.id == e.key).firstOrNull;
      if (p == null) {
        return showHSnack(
          context,
          'An item in your cart is no longer available',
          error: true,
        );
      }
      if (p.availStock <= 0) {
        return showHSnack(
          context,
          '"${p.name}" just went out of stock',
          error: true,
        );
      }
      if (e.value > p.availStock) {
        return showHSnack(
          context,
          'Only ${p.availStock} of "${p.name}" left \u2014 please adjust your cart',
          error: true,
        );
      }
    }
    setState(() => _busy = true);
    final order = buildOrder(
      cart: cart,
      f: CheckoutForm(
        firstName: _c['first']!.text,
        lastName: _c['last']!.text,
        phone: _c['phone']!.text,
        phoneSecondary: _c['phone2']!.text,
        line1: _c['line1']!.text,
        city: _c['city']!.text,
        province: _province,
        deliveryAddress: _c['deliv']!.text,
        notes: _c['notes']!.text,
      ),
      email: ref.read(authStateProvider).valueOrNull?.email ?? '',
      delivery: ref.read(deliveryProvider),
      orderNumber: _orderNo,
    );
    try {
      await ref.read(ordersRepositoryProvider).submit(order);
      await ref.read(myOrdersProvider.notifier).add(order);
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.pushReplacement('/order-success', extra: order);
    } on FriendlyException catch (e) {
      if (mounted) showHSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final d = ref.watch(deliveryProvider);
    final sub = cart.fold<num>(0, (s, i) => s + i.price * i.qty);
    final del = d.chargeFor(sub, _province);
    InputDecoration dec(String l, {String? hint}) =>
        InputDecoration(labelText: l, hintText: hint);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HTopBar(title: 'Checkout', subtitle: 'Order $_orderNo'),
      body: HBackground(
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              HSpace.screen,
              MediaQuery.paddingOf(context).top + 76,
              HSpace.screen,
              HSpace.xxl,
            ),
            children: [
              PanelBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Contact', style: t.textTheme.titleMedium),
                    const Gap(HSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _c['first'],
                            decoration: dec('First name'),
                            validator: (v) =>
                                Validators.required(v, 'First name'),
                          ),
                        ),
                        const SizedBox(width: HSpace.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _c['last'],
                            decoration: dec('Last name'),
                            validator: (v) =>
                                Validators.required(v, 'Last name'),
                          ),
                        ),
                      ],
                    ),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['phone'],
                      keyboardType: TextInputType.phone,
                      decoration: dec('Phone', hint: '+923001234567'),
                      validator: Validators.phone,
                    ),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['phone2'],
                      keyboardType: TextInputType.phone,
                      decoration: dec('Secondary phone (optional)'),
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              PanelBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Delivery address', style: t.textTheme.titleMedium),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['line1'],
                      decoration: dec('Address'),
                      validator: (v) => Validators.required(v, 'Address'),
                    ),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['city'],
                      decoration: dec('City'),
                      validator: (v) => Validators.required(v, 'City'),
                    ),
                    const Gap(HSpace.md),
                    DropdownButtonFormField<String>(
                      initialValue: _province,
                      decoration: dec('Province'),
                      items: DeliverySettings.provinces
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _province = v ?? _province),
                    ),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['deliv'],
                      decoration: dec(
                        'Delivery instructions',
                        hint: 'Landmark, floor, gate\u2026',
                      ),
                    ),
                    const Gap(HSpace.md),
                    TextFormField(
                      controller: _c['notes'],
                      maxLines: 2,
                      decoration: dec('Order notes (optional)'),
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              PanelBlock(
                child: Column(
                  children: [
                    for (final i in cart)
                      _sumRow(
                        t,
                        '${i.name}${i.variant.isEmpty ? '' : ' (${i.variant})'} \u00d7 ${i.qty}',
                        money(i.price * i.qty),
                      ),
                    const Divider(),
                    _sumRow(t, 'Subtotal', money(sub)),
                    _sumRow(
                      t,
                      'Delivery ($_province)',
                      del == 0 ? 'Free' : money(del),
                    ),
                    _sumRow(t, 'Total', money(sub + del), bold: true),
                    const Gap(6),
                    Text(
                      'Payment: Cash on delivery',
                      style: t.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.lg),
              HButton(
                label: 'Place order \u00b7 ${money(sub + del)}',
                loading: _busy,
                onPressed: cart.isEmpty ? null : _place,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.order});
  final Map<String, dynamic>? order;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final o = order;
    return Scaffold(
      body: HBackground(
        intense: true,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(HSpace.screen),
              child: SurfacePanel(
                radius: HRadius.xl,
                padding: const EdgeInsets.all(HSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconBadge(
                      icon: Icons.check_rounded,
                      color: HColors.success,
                      size: 72,
                    ),
                    const Gap(HSpace.md),
                    Text('Order placed!', style: t.textTheme.headlineMedium),
                    const Gap(6),
                    Text(
                      o == null ? '' : 'Order ${o['orderNumber']}',
                      style: t.textTheme.titleMedium,
                    ),
                    const Gap(HSpace.sm),
                    Text(
                      'We\u2019ll contact you to confirm delivery. Payment: cash on delivery.',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium,
                    ),
                    if (o != null) ...[
                      const Gap(HSpace.md),
                      Text(
                        'Total ${money(((o['totals'] as Map)['grandTotal'] as num?) ?? 0)}',
                        style: t.textTheme.titleLarge?.copyWith(
                          color: t.colorScheme.primary,
                        ),
                      ),
                    ],
                    const Gap(HSpace.lg),
                    HButton(
                      label: 'My orders',
                      onPressed: () => context.pushReplacement('/orders'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    Future<void> sync() async {
      final repo = ref.read(ordersRepositoryProvider);
      for (final o in orders) {
        try {
          final v = await repo.verification('${o['verifyToken']}');
          if (v != null) {
            await ref
                .read(myOrdersProvider.notifier)
                .updateStatus('${o['id']}', v);
          }
        } catch (_) {}
      }
    }

    return TabPage(
      title: 'My orders',
      subtitle: 'Placed from this device',
      onRefresh: sync,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              if (orders.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Orders you place will appear here.',
                ),
              for (final o in orders)
                ResourceTile(
                  icon: Icons.receipt_long_rounded,
                  color: HColors.info,
                  eyebrow: '${o['status']} \u00b7 ${o['payment']}',
                  title: '${o['orderNumber']}',
                  subtitle:
                      '${(o['items'] as List?)?.length ?? 0} items \u00b7 ${money(((o['totals'] as Map?)?['grandTotal'] as num?) ?? 0)}'
                      '${(o['trackingId'] ?? '').toString().isNotEmpty ? ' \u00b7 Tracking ${o['trackingId']}' : ''}',
                  trailing: const SizedBox.shrink(),
                ),
              if (orders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: HSpace.sm),
                  child: Text(
                    'Pull down to refresh status.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
