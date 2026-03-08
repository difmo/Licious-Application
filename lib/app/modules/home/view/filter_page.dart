import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  int _selectedRating = 4;
  bool _discount = false;
  bool _freeShipping = true;
  bool _sameDayDelivery = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apply Filters',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: () {
              setState(() {
                _selectedRating = 4;
                _discount = false;
                _freeShipping = true;
                _sameDayDelivery = true;
              });
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionCard(
            title: 'Price Range',
            child: Row(
              children: [
                Expanded(child: _buildPriceInput('Min.')),
                const SizedBox(width: 16),
                Expanded(child: _buildPriceInput('Max.')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Star Rating',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = index + 1),
                        child: Icon(
                          index < _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: index < _selectedRating
                              ? Colors.amber
                              : Colors.grey,
                          size: 24,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Text(
                    '$_selectedRating stars',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Others',
            child: Column(
              children: [
                _buildFilterRow(
                  Icons.local_offer_outlined,
                  'Discount',
                  _discount,
                  (v) => setState(() => _discount = v),
                ),
                const Divider(height: 24),
                _buildFilterRow(
                  Icons.local_shipping_outlined,
                  'Free shipping',
                  _freeShipping,
                  (v) => setState(() => _freeShipping = v),
                ),
                const Divider(height: 24),
                _buildFilterRow(
                  Icons.access_time_outlined,
                  'Same day delivery',
                  _sameDayDelivery,
                  (v) => setState(() => _sameDayDelivery = v),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF439462),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Apply filter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceInput(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildFilterRow(
    IconData icon,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF68B92E) : Colors.transparent,
              border: Border.all(
                color: value
                    ? const Color(0xFF68B92E)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: value ? Colors.white : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
