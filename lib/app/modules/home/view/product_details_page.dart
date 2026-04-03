import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/subscription_service.dart';

import '../widgets/cart_summary_bar.dart';
import '../widgets/quantity_selector.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  int _selectedVariantIndex = 0;

  void _showSubscriptionDrawer(BuildContext context, ProductVariant? selectedVariant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionConfigDrawer(
        product: widget.product,
        selectedVariant: selectedVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    // Note: CartProviderScope.of(context) might need ref.watch(cartProvider) if refactored
    // Using context for legacy compatibility if CartProviderScope still exists
    final cart = CartProviderScope.of(context);
    final selectedVariant =
        product.variants.isNotEmpty ? product.variants[_selectedVariantIndex] : null;

    final cartItem = cart.items.firstWhere(
      (item) => item.id == product.id && item.variantId == selectedVariant?.id,
      orElse: () => CartItem(
        id: product.id,
        title: product.name,
        unitPrice: selectedVariant?.price ?? product.price,
        subtitle: selectedVariant?.weightLabel ?? product.weight,
        image: product.image,
        category: product.category,
        variantId: selectedVariant?.id,
        weightLabel: selectedVariant?.weightLabel,
        quantity: 0,
      ),
    );
    final isInCart = cartItem.quantity > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: const [],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product_${product.id}',
                    child: product.image.isEmpty
                        ? const Center(
                            child: Icon(Icons.set_meal_outlined,
                                size: 64, color: Colors.grey))
                        : product.image.startsWith('http')
                            ? Image.network(
                                product.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.set_meal_outlined,
                                        size: 64, color: Colors.grey)),
                              )
                            : Image.asset(
                                product.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.set_meal_outlined,
                                        size: 64, color: Colors.grey)),
                              ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.badgeText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(product.badgeText,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A))),
                          ),
                         Text('₹${(selectedVariant?.price ?? product.price).toStringAsFixed(0)}',
                             style: const TextStyle(
                                 fontSize: 24,
                                 fontWeight: FontWeight.w800,
                                 color: Color(0xFF68B92E))),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text(selectedVariant?.weightLabel ?? product.weight,
                         style: TextStyle(
                             fontSize: 16, color: Colors.grey.shade600)),
                     
                     // ── Variant Selection ──────────────────────────────────────
                     if (product.variants.isNotEmpty) ...[
                       const SizedBox(height: 20),
                       const Text('Select weight',
                           style: TextStyle(
                               fontSize: 14,
                               fontWeight: FontWeight.bold,
                               color: Colors.grey)),
                       const SizedBox(height: 12),
                       SizedBox(
                         height: 44,
                         child: ListView.separated(
                           scrollDirection: Axis.horizontal,
                           itemCount: product.variants.length,
                           separatorBuilder: (_, __) => const SizedBox(width: 12),
                           itemBuilder: (ctx, idx) {
                             final v = product.variants[idx];
                             final isSelected = _selectedVariantIndex == idx;
                             return GestureDetector(
                               onTap: () => setState(() => _selectedVariantIndex = idx),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 20),
                                 decoration: BoxDecoration(
                                   color: isSelected ? const Color(0xFF68B92E).withValues(alpha: 0.1) : Colors.white,
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(
                                     color: isSelected ? const Color(0xFF68B92E) : Colors.grey.shade300,
                                     width: isSelected ? 2 : 1,
                                   ),
                                 ),
                                 child: Center(
                                   child: Text(
                                     v.weightLabel,
                                     style: TextStyle(
                                       fontSize: 14,
                                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                       color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                     ),
                                   ),
                                 ),
                               ),
                             );
                           },
                         ),
                       ),
                     ],
                      const SizedBox(height: 24),
                      const Text('Product Description',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 12),
                      Text(product.description,
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 24),
                      if (product.whyChoose.isNotEmpty) ...[
                        const Text('Why Choose Our Shrimp',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 16),
                        ...product.whyChoose.map((point) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF68B92E), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(point,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade800))),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 48),

                    ],
                  ),
                ),
              ),
            ],
          ),
          // Cart Summary Overlay
          if (cart.itemCount > 0)
            Positioned(
              bottom: 154, // Positioned above the bottom action bar
              left: 0,
              right: 0,
              child: CartSummaryBar(
                cart: cart,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showSubscriptionDrawer(context, selectedVariant),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text('Subscribe & Save',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF68B92E),
                      side: const BorderSide(
                          color: Color(0xFF68B92E), width: 1.5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  !isInCart
                      ? ElevatedButton(
                          onPressed: () =>
                              cart.addToCart(CartItem(
                                id: product.id,
                                title: product.name,
                                unitPrice: selectedVariant?.price ?? product.price,
                                subtitle: selectedVariant?.weightLabel ?? product.weight,
                                image: product.image,
                                category: product.category,
                                variantId: selectedVariant?.id,
                                weightLabel: selectedVariant?.weightLabel,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF68B92E),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Add to Cart',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        )
                      : Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF68B92E)
                                      .withValues(alpha: 0.2))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Selected Quantity',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A))),
                              QuantitySelector(
                                quantity: cartItem.quantity,
                                onIncrement: () => cart.increment(product.id, variantId: selectedVariant?.id),
                                onDecrement: () => cart.decrement(product.id, variantId: selectedVariant?.id),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionConfigDrawer extends StatefulWidget {
  final Product product;
  final ProductVariant? selectedVariant;
  const SubscriptionConfigDrawer({super.key, required this.product, this.selectedVariant});

  @override
  State<SubscriptionConfigDrawer> createState() =>
      _SubscriptionConfigDrawerState();
}

class _SubscriptionConfigDrawerState extends State<SubscriptionConfigDrawer> {
  String _frequency = 'Daily';
  int _quantity = 1;
  List<String> _selectedDays = [];
  late DateTime _startDate;
  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF68B92E),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Subscription Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Configure recurring delivery for ${widget.product.name} ${widget.selectedVariant != null ? "(${widget.selectedVariant!.weightLabel})" : ""}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          const Text('Delivery Frequency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Daily', 'Alternate Days', 'Weekly']
                .map((freq) => ChoiceChip(
                      label: Text(freq),
                      selected: _frequency == freq,
                      onSelected: (_) => setState(() {
                        _frequency = freq;
                        if (freq != 'Weekly') _selectedDays = [];
                      }),
                      selectedColor:
                          const Color(0xFF68B92E).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                          color: _frequency == freq
                              ? const Color(0xFF2E7D32)
                              : Colors.black87,
                          fontWeight: _frequency == freq
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ))
                .toList(),
          ),
          if (_frequency == 'Weekly') ...[
            const SizedBox(height: 16),
            const Text('Select Days',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _weekDays.map((day) {
                final short = day.substring(0, 3);
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF68B92E) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF68B92E)
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(short,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.black87)),
                  ),
                );
              }).toList(),
            ),
            if (_selectedDays.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Please select at least one day',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(
                      onPressed: () => setState(() {
                            if (_quantity > 1) _quantity--;
                          }),
                      icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_quantity',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF68B92E))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Start Date Picker
          const Text('Start Date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF68B92E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF68B92E)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined,
                      color: Color(0xFF68B92E), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_startDate.day.toString().padLeft(2, '0')} / ${_startDate.month.toString().padLeft(2, '0')} / ${_startDate.year}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32)),
                  ),
                  const Spacer(),
                  const Text('Tap to change',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Consumer(builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () async {
                final subService = ref.read(subscriptionServiceProvider);
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final res = await subService.subscribeToProduct(
                  productId: widget.product.id,
                  frequency: _frequency,
                  quantity: _quantity,
                  variantId: widget.selectedVariant?.id,
                  weightLabel: widget.selectedVariant?.label ?? widget.product.weight,
                  customDays: _frequency == 'Weekly' ? _selectedDays : [],
                  startDate: _startDate,
                );
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    content: Text(res['message'] ?? 'Subscribed successfully!'),
                    backgroundColor:
                        res['success'] == true ? Colors.green : Colors.red,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm Subscription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            );
          }),
        ],
      ),
    );
  }
}

