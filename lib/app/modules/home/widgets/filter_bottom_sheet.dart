import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // State variables for filters
  RangeValues _priceRange = const RangeValues(10, 500);
  String _selectedRating = '';
  
  // Delivery Options
  bool _discount = false;
  bool _freeShipping = false;
  bool _sameDayDelivery = false;

  final Color _primaryColor = const Color(0xFF68B92E);
  final Color _bgColor = const Color(0xFFF8F9FA);

  // Active filters list
  List<String> get _activeFilters {
    List<String> filters = [];
    if (_selectedRating.isNotEmpty) filters.add(_selectedRating);
    if (_discount) filters.add('Discount');
    if (_freeShipping) filters.add('Free Shipping');
    if (_sameDayDelivery) filters.add('Same Day');
    return filters;
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(10, 500);
      _selectedRating = '';
      _discount = false;
      _freeShipping = false;
      _sameDayDelivery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
                const Expanded(
                  child: Text(
                    'Filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Active Filters
                if (_activeFilters.isNotEmpty) ...[
                  _buildSectionTitle('Active Filters'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activeFilters.map((filter) {
                      return Chip(
                        label: Text(
                          filter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: _primaryColor,
                        deleteIconColor: Colors.white,
                        onDeleted: () {
                          setState(() {
                            if (filter == _selectedRating) _selectedRating = '';
                            if (filter == 'Discount') _discount = false;
                            if (filter == 'Free Shipping') _freeShipping = false;
                            if (filter == 'Same Day') _sameDayDelivery = false;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.transparent),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Price Range
                _buildCard([
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_priceRange.start.round()}', style: _labelStyle),
                      Text('₹${_priceRange.end.round()}', style: _labelStyle),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _primaryColor,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: Colors.white,
                      overlayColor: _primaryColor.withValues(alpha:  0.1),
                      trackHeight: 6,
                      rangeThumbShape: const RoundRangeSliderThumbShape(elevation: 3, pressedElevation: 6),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      onChanged: (RangeValues values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Rating
                _buildCard([
                  _buildSectionTitle('Rating'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRatingChip('★ 4+'),
                      const SizedBox(width: 12),
                      _buildRatingChip('★ 3+'),
                      const SizedBox(width: 12),
                      _buildRatingChip('★ 2+'),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),

                // Delivery Options
                _buildCard([
                  _buildSectionTitle('Delivery Options'),
                  const SizedBox(height: 8),
                  _buildToggleRow('Discount', _discount, (val) => setState(() => _discount = val)),
                  _buildDivider(),
                  _buildToggleRow('Free Shipping', _freeShipping, (val) => setState(() => _freeShipping = val)),
                  _buildDivider(),
                  _buildToggleRow('Same Day Delivery', _sameDayDelivery, (val) => setState(() => _sameDayDelivery = val)),
                ]),
                
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Sticky CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:  0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Apply filter logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Show 124 Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  Widget _buildRatingChip(String label) {
    bool isSelected = _selectedRating == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = isSelected ? '' : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha:  0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade100, height: 16);
  }
}


