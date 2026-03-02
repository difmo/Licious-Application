import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';

class ProfileDetailPage extends StatefulWidget {
  final String title;

  const ProfileDetailPage({super.key, required this.title});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  int? _expandedOrderIndex = 0; // Default first one expanded as in Image 3
  bool _makeDefaultAddress = true;
  bool _makeDefaultCard = true;

  @override
  Widget build(BuildContext context) {
    final cartProvider = CartProviderScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.title == 'My Address' || widget.title == 'Credit Cards')
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF1A1A1A),
              ),
              onPressed: () {
                // Handle add new
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: _buildContent(widget.title, cartProvider, context),
        ),
      ),
    );
  }

  Widget _buildContent(
    String title,
    CartProvider provider,
    BuildContext context,
  ) {
    switch (title) {
      case 'My Address':
        return _buildAddressDetail(provider);
      case 'My Orders':
        return _buildOrdersDetail(provider);
      case 'My Favorites':
        return _buildFavoritesDetail(provider);
      case 'Transactions':
        return _buildTransactionsDetail();
      case 'Notifications':
        return _buildNotificationsDetail();
      case 'Credit Cards':
        return _buildCardsDetail(provider);
      case 'About me':
        return _buildAboutMeDetail(provider);
      default:
        return Center(child: Text('Content for $title coming soon!'));
    }
  }

  // --- MY ADDRESS DESIGN (Image 2) ---
  Widget _buildAddressDetail(CartProvider provider) {
    return Column(
      children: [
        // Saved Address Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBFFD7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: Color(0xFF68B92E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEBFFD7),
                    child: Icon(
                      Icons.location_on,
                      color: const Color(0xFF68B92E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Russell Austin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '2811 Crescent Day, LA Port, California, United States 77571',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '+1 202 555 0142',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_less, color: Color(0xFF68B92E)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Adding Form Fields (The input boxes in design)
        _buildIconTextField(Icons.person_outline, 'Name'),
        const SizedBox(height: 12),
        _buildIconTextField(Icons.location_on_outlined, 'Address'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildIconTextField(Icons.map_outlined, 'City')),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIconTextField(Icons.mail_outline, 'Zip code'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildIconTextField(
          Icons.public,
          'Country',
          trailingIcon: Icons.keyboard_arrow_down,
        ),
        const SizedBox(height: 12),
        _buildIconTextField(Icons.phone_outlined, 'Phone number'),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(
              value: _makeDefaultAddress,
              onChanged: (v) => setState(() => _makeDefaultAddress = v),
              activeThumbColor: const Color(0xFF68B92E),
              activeTrackColor: const Color(0xFFEBFFD7),
            ),
            const Text(
              'Make default',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSaveButton('Save address'),
      ],
    );
  }

  // --- MY ORDERS / TRACKING DESIGN (Image 3) ---
  Widget _buildOrdersDetail(CartProvider provider) {
    return Column(
      children: List.generate(4, (index) {
        final isExpanded = _expandedOrderIndex == index;
        return _buildOrderCard(index, isExpanded);
      }),
    );
  }

  Widget _buildOrderCard(int index, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFEBFFD7),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF68B92E),
              ),
            ),
            title: const Text(
              'Order #90897',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Placed on October 19 2021',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Items:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(
                      ' 10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Total:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(
                      ' \$16.90',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: const Color(0xFF68B92E),
            ),
            onTap: () {
              setState(() {
                _expandedOrderIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildTimelineItem(
                    'Order Placed',
                    'October 21 2021',
                    Icons.inventory_2_outlined,
                    true,
                    true,
                  ),
                  _buildTimelineItem(
                    'Order Confirmed',
                    'October 21 2021',
                    Icons.check_circle_outline,
                    true,
                    true,
                  ),
                  _buildTimelineItem(
                    'Order Shipped',
                    'October 21 2021',
                    Icons.edit_road_outlined,
                    true,
                    true,
                  ),
                  _buildTimelineItem(
                    'Out for Delivery',
                    'Pending',
                    Icons.local_shipping_outlined,
                    false,
                    false,
                  ),
                  _buildTimelineItem(
                    'Order Delivered',
                    'Pending',
                    Icons.shopping_basket_outlined,
                    false,
                    false,
                    isLast: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- NOTIFICATIONS DESIGN (Image 4) ---
  Widget _buildNotificationsDetail() {
    return Column(
      children: [
        _buildNotificationCard(
          'Allow Notifications',
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed diam nonummym',
          true,
        ),
        _buildNotificationCard(
          'Email Notifications',
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed diam nonummym',
          false,
        ),
        _buildNotificationCard(
          'Order Notifications',
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed diam nonummym',
          false,
        ),
        _buildNotificationCard(
          'General Notifications',
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed diam nonummym',
          true,
        ),
        const SizedBox(height: 60),
        _buildSaveButton('Save settings'),
      ],
    );
  }

  // --- MY CARDS DESIGN (Image 5) ---
  Widget _buildCardsDetail(CartProvider provider) {
    return Column(
      children: [
        // MasterCard expanded
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBFFD7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    color: Color(0xFF68B92E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF7F8FA),
                    child: Icon(Icons.credit_card, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Card',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'XXXX XXXX XXXX 5678',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          'Expiry: 01/22  CVV: 908',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_less, color: Color(0xFF68B92E)),
                ],
              ),
              const SizedBox(height: 24),
              _buildIconTextField(Icons.person_outline, 'Russell Austin'),
              const SizedBox(height: 12),
              _buildIconTextField(
                Icons.credit_card_outlined,
                'XXXX XXXX XXXX 5678',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildIconTextField(
                      Icons.calendar_today_outlined,
                      '01/22',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIconTextField(Icons.lock_outline, '908'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _makeDefaultCard,
                    onChanged: (v) => setState(() => _makeDefaultCard = v),
                    activeThumbColor: const Color(0xFF68B92E),
                    activeTrackColor: const Color(0xFFEBFFD7),
                  ),
                  const Text(
                    'Make default',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCardItem(
          'Visa Card',
          'XXXX XXXX XXXX 5678',
          Icons.credit_card,
          Colors.blue,
        ),
        _buildCardItem(
          'Master Card',
          'XXXX XXXX XXXX 5678',
          Icons.payment,
          Colors.orange,
        ),
        const SizedBox(height: 32),
        _buildSaveButton('Save card'),
      ],
    );
  }

  // --- SHARED COMPONENTS ---

  Widget _buildIconTextField(
    IconData icon,
    String hint, {
    IconData? trailingIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: trailingIcon != null
              ? Icon(trailingIcon, color: Colors.grey)
              : null,
        ),
      ),
    );
  }

  Widget _buildSaveButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF439462), // Darker designer green
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    bool isActive,
    bool isCompleted, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFEBFFD7)
                    : const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted ? const Color(0xFF68B92E) : Colors.grey,
                size: 24,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted
                    ? const Color(0xFFEBFFD7)
                    : const Color(0xFFF1F4F8),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Divider(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(String title, String desc, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: (v) {},
            activeThumbColor: const Color(0xFF68B92E),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(
    String title,
    String number,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF1F4F8),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  number,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, color: Color(0xFFD1D1D1)),
        ],
      ),
    );
  }

  // --- MY FAVORITES DESIGN (Image 5) ---
  Widget _buildFavoritesDetail(CartProvider provider) {
    return Column(
      children: [
        _buildFavoriteCard(
          'Fresh Broccoli',
          '1.50 lbs',
          '2.22',
          4,
          'assets/images/image copy.png',
          const Color(0xFFEBFFD7),
        ),
        _buildFavoriteCard(
          'Black Grapes',
          '5.0 lbs',
          '2.32',
          4,
          'assets/images/image copy 2.png',
          const Color(0xFFFFF1F1),
        ),
        _buildFavoriteCard(
          'Avocado',
          '1.50 lbs',
          '2.22',
          4,
          'assets/images/image copy.png',
          const Color(0xFFFFF8E1),
        ),
        _buildFavoriteCard(
          'Pineapple',
          'dozen',
          '3.22',
          4,
          'assets/images/image copy 2.png',
          const Color(0xFFFFF3E0),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(
    String title,
    String weight,
    String price,
    int count,
    String image,
    Color bgColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    image,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$$price x $count',
                    style: const TextStyle(
                      color: Color(0xFF68B92E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    weight,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF68B92E),
                  ),
                  onPressed: () {},
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
            if (title == 'Black Grapes') // Match Image 5's swipe state
              Container(
                width: 60,
                height: 110,
                color: const Color(0xFFFF5252),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  // --- TRANSACTIONS DESIGN ---
  Widget _buildTransactionsDetail() {
    return Column(
      children: [
        _buildTransactionItem(
          'Order Payment',
          'Oct 24, 2021',
          '-\$34.50',
          'Completed',
          isNegative: true,
        ),
        _buildTransactionItem(
          'Wallet Top-up',
          'Oct 22, 2021',
          '+\$50.00',
          'Completed',
          isNegative: false,
        ),
        _buildTransactionItem(
          'Refund received',
          'Oct 20, 2021',
          '+\$12.00',
          'Completed',
          isNegative: false,
        ),
        _buildTransactionItem(
          'Order Payment',
          'Oct 19, 2021',
          '-\$16.90',
          'Completed',
          isNegative: true,
        ),
        _buildTransactionItem(
          'Order Payment',
          'Oct 18, 2021',
          '-\$22.10',
          'Failed',
          isNegative: true,
          isFailed: true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String date,
    String amount,
    String status, {
    bool isNegative = true,
    bool isFailed = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isFailed
                ? Colors.red.withValues(alpha: 0.1)
                : (isNegative
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1)),
            child: Icon(
              isFailed
                  ? Icons.error_outline
                  : (isNegative
                        ? Icons.shopping_bag_outlined
                        : Icons.account_balance_wallet_outlined),
              color: isFailed
                  ? Colors.red
                  : (isNegative ? Colors.orange : Colors.green),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isFailed
                      ? Colors.grey
                      : (isNegative ? Colors.black : Colors.green),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  color: isFailed ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ABOUT ME DESIGN (Image 4) ---
  Widget _buildAboutMeDetail(CartProvider provider) {
    final profile = provider.userProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        _buildIconTextField(Icons.person_outline, profile.name),
        const SizedBox(height: 12),
        _buildIconTextField(Icons.mail_outline, profile.email),
        const SizedBox(height: 12),
        _buildIconTextField(Icons.phone_android_outlined, profile.phone),
        const SizedBox(height: 32),
        const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        _buildIconTextField(Icons.lock_outline, 'Current password'),
        const SizedBox(height: 12),
        _buildIconTextField(
          Icons.lock_outline,
          '••••••',
          trailingIcon: Icons.visibility_outlined,
        ),
        const SizedBox(height: 12),
        _buildIconTextField(Icons.lock_outline, 'Confirm password'),
        const SizedBox(height: 40),
        _buildSaveButton('Save settings'),
      ],
    );
  }
}
