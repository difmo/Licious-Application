import 'package:flutter/material.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';

class VariantSelectorSheet extends StatefulWidget {
  final Product product;
  final String shopId;
  final String shopName;

  const VariantSelectorSheet({
    super.key,
    required this.product,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<VariantSelectorSheet> {
  int? _selectedVariantIndex;

  @override
  void initState() {
    super.initState();
    // If only 1 variant exists, pre-select it automatically
    if (widget.product.variants.length == 1) {
      _selectedVariantIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final variants = widget.product.variants;
    final selectedVariant = _selectedVariantIndex != null ? variants[_selectedVariantIndex!] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.product.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.set_meal_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Choose a variant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          
          // Variant List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final v = variants[index];
                final isSelected = _selectedVariantIndex == index;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariantIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF68B92E).withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF68B92E) : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF68B92E) : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF68B92E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            v.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        Text(
                          '₹${v.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF68B92E) : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Bottom Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    selectedVariant != null 
                        ? '₹${selectedVariant.price.toStringAsFixed(0)}'
                        : '₹0',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedVariant == null
                    ? null
                    : () {
                        if (cart.isSameShop(widget.shopId)) {
                          cart.addToCart(CartItem(
                            id: widget.product.id,
                            title: widget.product.name,
                            unitPrice: selectedVariant.price,
                            subtitle: selectedVariant.label,
                            image: widget.product.image,
                            category: widget.product.category,
                            shopId: widget.shopId,
                            shopName: widget.shopName,
                            variantId: selectedVariant.id,
                            weightLabel: selectedVariant.label,
                          ));
                          Navigator.pop(context);
                        } else {
                          _showClearCartDialog(context, cart, selectedVariant);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF68B92E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(160, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart, ProductVariant selectedVariant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Cart?'),
        content: Text(
            'Your cart contains items from ${cart.items.first.shopName ?? 'another shop'}. Do you want to discard them and add items from ${widget.shopName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              cart.addToCart(CartItem(
                id: widget.product.id,
                title: widget.product.name,
                unitPrice: selectedVariant.price,
                subtitle: selectedVariant.label,
                image: widget.product.image,
                category: widget.product.category,
                shopId: widget.shopId,
                shopName: widget.shopName,
                variantId: selectedVariant.id,
                weightLabel: selectedVariant.label,
              ));
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // BottomSheet
            },
            child: const Text('REPLACE', style: TextStyle(color: Color(0xFF68B92E))),
          ),
        ],
      ),
    );
  }
}
