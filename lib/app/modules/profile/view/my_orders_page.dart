import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // Dummy data matching the visual design
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '1',
      'title': 'Red Shrimp',
      'description': '1x Red, White & Tiger Shrimp',
      'price': 499.00,
      'image': 'assets/images/shrimp_tiger_trio.png',
      'isDelivered': false,
    },
    {
      'id': '2',
      'title': 'Tiger Shrimp',
      'description': '1x Grilled Red &\nShrimp Skuisers',
      'price': 790.00,
      'image': 'assets/images/shrimp_cooked_duo.png',
      'isDelivered': true,
    },
    {
      'id': '3',
      'title': 'Peeled Shrimp',
      'description': '1x White Shrimpi with\nGarlic Lemon Sauce',
      'price': 290.00,
      'image': 'assets/images/shrimp_dish_1.png',
      'isDelivered': false,
    },
    {
      'id': '4',
      'title': 'Sizzling Garlic Shrimp',
      'description': '1x Large Portion\nExtra Spicy',
      'price': 549.00,
      'image': 'assets/images/shrimp_dish_2.png',
      'isDelivered': true,
    },
  ];

  void _reorder(String title) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title added to cart for reorder!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF114F3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteOrder(String id) {
    HapticFeedback.heavyImpact();
    setState(() {
      _orders.removeWhere((order) => order['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 60.0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 14),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Orders',
                style: TextStyle(
                  color: Color(0xFF114F3B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _OrderCard(
                    order: _orders[index],
                    onDelete: () => _deleteOrder(_orders[index]['id']),
                    onReorder: () => _reorder(_orders[index]['title']),
                  );
                },
                childCount: _orders.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onDelete;
  final VoidCallback onReorder;

  const _OrderCard({
    required this.order,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Dismissible(
      key: Key(order['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) => widget.onDelete(),
      child: GestureDetector(
        onDoubleTap: () {
          widget.onReorder();
          _controller.forward().then((_) => _controller.reverse());
        },
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA), // slightly lighter
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D3436).withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  child: Image.asset(
                    order['image'],
                    width: 130,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3436), // Subtle dark charcoal
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (order['isDelivered'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFD8A8)),
                                ),
                                child: const Text(
                                  'Delivered',
                                  style: TextStyle(
                                    color: Color(0xFFE67E22), // Subtle orange
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['description'],
                          style: const TextStyle(
                            color: Color(0xFF636E72), // Subtle cool grey
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Bill',
                                  style: TextStyle(
                                    color: Color(0xFF636E72),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '₹${order['price'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                                onTap: () {
                                  widget.onReorder();
                                  _controller.forward().then((_) => _controller.reverse());
                                },
                                child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Reorder',
                                  style: TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
