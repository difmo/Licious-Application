import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../modules/home/provider/filter_provider.dart';
import '../data/services/shop_service.dart';
import '../modules/home/view/filtered_products_page.dart';

class ModernFilterBottomSheet extends ConsumerStatefulWidget {
  const ModernFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModernFilterBottomSheet(),
    );
  }

  @override
  ConsumerState<ModernFilterBottomSheet> createState() => _ModernFilterBottomSheetState();
}

class _ModernFilterBottomSheetState extends ConsumerState<ModernFilterBottomSheet> {
  // Local state for filters
  RangeValues _priceRange = const RangeValues(0, 1000);
  int? _selectedRating;
  bool _discount = false;
  bool _freeShipping = false;
  bool _sameDayDelivery = false;
  
  int _totalCount = 0;
  bool _isLoadingCount = false;
  Timer? _debounceTimer;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize from current global filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentFilter = ref.read(productFilterProvider);
      setState(() {
        _priceRange = RangeValues(
          currentFilter.minPrice ?? 0,
          currentFilter.maxPrice ?? 1000,
        );
        _selectedRating = currentFilter.minRating?.toInt();
        _discount = currentFilter.hasDiscount ?? false;
        _freeShipping = currentFilter.freeShipping ?? false;
        _sameDayDelivery = currentFilter.sameDayDelivery ?? false;
        
        _minController.text = _priceRange.start.round().toString();
        _maxController.text = _priceRange.end.round().toString();
      });
      _fetchCount();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchCount();
    });
  }

  void _onManualPriceChange() {
    final min = double.tryParse(_minController.text) ?? 0;
    final max = double.tryParse(_maxController.text) ?? 1000;
    
    if (min <= max && min >= 0 && max <= 1000) {
      setState(() {
        _priceRange = RangeValues(min, max);
      });
      _onFilterChanged();
    }
  }

  Future<void> _fetchCount() async {
    if (!mounted) return;
    setState(() => _isLoadingCount = true);
    
    try {
      final service = ref.read(shopServiceProvider);
      final result = await service.getFilteredProducts(
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        minRating: _selectedRating?.toDouble(),
        hasDiscount: _discount,
        freeShipping: _freeShipping,
        sameDayDelivery: _sameDayDelivery,
      );
      
      if (mounted) {
        setState(() {
          _totalCount = result['total'] as int;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCount = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000);
      _selectedRating = null;
      _discount = false;
      _freeShipping = false;
      _sameDayDelivery = false;
      _minController.text = '0';
      _maxController.text = '1000';
    });
    _fetchCount();
  }



  void _applyFilters() {
    ref.read(productFilterProvider.notifier).update(ProductFilter(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      minRating: _selectedRating?.toDouble(),
      hasDiscount: _discount,
      freeShipping: _freeShipping,
      sameDayDelivery: _sameDayDelivery,
    ));
    
    Navigator.pop(context);
    
    // If we're not already on the FilteredProductsPage, navigate to it
    // Check current route to avoid pushing a duplicate if already there
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != '/filtered_products') {
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/filtered_products'),
          builder: (_) => const FilteredProductsPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Price Range'),
                    const SizedBox(height: 16),
                    _buildPriceRangeSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Rating'),
                    const SizedBox(height: 16),
                    _buildRatingSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Delivery Options'),
                    const SizedBox(height: 16),
                    _buildDeliveryOptionsSection(),
                    const SizedBox(height: 120), // Padding for sticky bottom button
                  ],
                ),
              ),
            ),
          ),
          _buildStickyBottomAction(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceBox('Min', '', _minController),
              const Text(
                '-',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildPriceBox('Max', '', _maxController),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
                pressedElevation: 8,
              ),
            ),
            child: RangeSlider(
              min: 0,
              max: 1000,
              divisions: 100,
              values: _priceRange,
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
                _minController.text = values.start.round().toString();
                _maxController.text = values.end.round().toString();
                _onFilterChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBox(String label, String value, TextEditingController controller) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBgAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            TextField(
              controller: controller,
              onChanged: (_) => _onManualPriceChange(),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                prefixText: '₹',
                prefixStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRatingChip(4, '★ 4+'),
        _buildRatingChip(3, '★ 3+'),
        _buildRatingChip(2, '★ 2+'),
      ],
    );
  }

  Widget _buildRatingChip(int rating, String label) {
    final isSelected = _selectedRating == rating;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = isSelected ? null : rating;
        });
        _fetchCount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow('Discount', _discount, (val) {
             setState(() => _discount = val);
             _fetchCount();
          }),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
          _buildToggleRow('Free Shipping', _freeShipping, (val) {
             setState(() => _freeShipping = val);
             _fetchCount();
          }),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
          _buildToggleRow('Same Day Delivery', _sameDayDelivery, (val) {
             setState(() => _sameDayDelivery = val);
             _fetchCount();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
            inactiveThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomAction() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoadingCount
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              _totalCount > 0 ? 'Show $_totalCount Results' : 'Show Results',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
      ),
    );
  }
}

