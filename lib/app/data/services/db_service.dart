import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/food_models.dart';
import 'cart_service.dart';
import 'wallet_service.dart';
import 'address_service.dart';
import '../network/api_client.dart';

class CartProvider extends ChangeNotifier {
  final CartService? _service;
  final WalletService? _walletService;
  final AddressService? _addressService;
  final List<CartItem> _items = [];

  CartProvider({
    CartService? service,
    WalletService? walletService,
    AddressService? addressService,
  })  : _service = service,
        _walletService = walletService,
        _addressService = addressService {
    loadAddresses();
    syncWallet();
  }

  AddressService? get addressService => _addressService;

  UserProfile _userProfile = const UserProfile(
    name: 'Guest User',
    email: '',
    phone: '',
    profileImage: 'assets/images/image copy 2.png',
  );

  bool get isLoggedIn => _userProfile.email.isNotEmpty;

  final List<FoodCategory> _foodCategories = const [
    FoodCategory(
      id: '1',
      name: 'White Shrimp',
      image: 'assets/images/image copy 11.png',
      colorValue: 0xFFFFF8E1, // Light Orange
    ),
    FoodCategory(
      id: '2',
      name: 'Tiger Shrimp',
      image: 'assets/images/shrimp_tiger_trio.png',
      colorValue: 0xFFE8F5E9, // Light Green
    ),
    FoodCategory(
      id: '4',
      name: 'Peeled Shrimp',
      image: 'assets/images/shrimp_cooked_duo.png',
      colorValue: 0xFFF3E5F5, // Light Purple
    ),
  ];

  final List<Restaurant> _restaurants = const [
    Restaurant(
      id: '1',
      name: 'New Pizza King',
      image: 'assets/images/image copy 2.png',
      rating: 4.2,
      deliveryTime: '25-30 mins',
      discount: '₹101 OFF above ₹149',
      minOrder: '₹149',
      categories: ['Pizza', 'Fast Food'],
    ),
    Restaurant(
      id: '2',
      name: 'Oven Story Pizza',
      image: 'assets/images/image copy 2.png',
      rating: 4.1,
      deliveryTime: '20-25 mins',
      discount: 'Items starting at ₹79',
      minOrder: '₹79',
      categories: ['Pizza'],
    ),
    Restaurant(
      id: '3',
      name: 'Radhe Ke Khas',
      image: 'assets/images/image copy 2.png',
      rating: 4.3,
      deliveryTime: '10-15 mins',
      discount: '₹101 OFF above ₹149',
      minOrder: '₹149',
      categories: ['North Indian'],
    ),
  ];

  List<UserOrder> _orders = [];
  bool _isOrdersLoading = false;

  bool get isOrdersLoading => _isOrdersLoading;

  void setOrders(List<UserOrder> newOrders) {
    _orders = newOrders;
    notifyListeners();
  }

  void setLoadingOrders(bool loading) {
    _isOrdersLoading = loading;
    notifyListeners();
  }

  double _walletBalance = 0.0;
  List<dynamic> _transactions = [];

  double get walletBalance => _walletBalance;
  List<dynamic> get transactions => _transactions;

  Future<void> syncWallet() async {
    if (_walletService == null) return;
    final result = await _walletService!.getBalance();
    if (result['success']) {
      _walletBalance = (result['balance'] as num).toDouble();
      notifyListeners();
    }
    _transactions = await _walletService!.getTransactionHistory();
    notifyListeners();
  }

  List<UserAddress> _addresses = [];
  bool _isAddressesLoading = false;
  int _selectedAddressIndex = 0;

  bool get isAddressesLoading => _isAddressesLoading;

  int get selectedAddressIndex => _selectedAddressIndex;

  void selectAddress(int index) {
    _selectedAddressIndex = index;
    notifyListeners();
  }

  UserAddress? get selectedAddress {
    if (_addresses.isEmpty) return null;
    if (_selectedAddressIndex >= 0 &&
        _selectedAddressIndex < _addresses.length) {
      return _addresses[_selectedAddressIndex];
    }
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere((a) => a.isDefault,
        orElse: () => _addresses.first);
  }

  final List<UserPaymentMethod> _payments = [
    const UserPaymentMethod(
      id: 'PAY001',
      type: 'Visa',
      lastFour: '4567',
      expiry: '12/28',
    ),
    const UserPaymentMethod(
      id: 'PAY002',
      type: 'UPI',
      lastFour: 'rajaji@upi',
      expiry: '-',
    ),
  ];

  final List<Product> _recommendedProducts = const [
    Product(
      id: 'p1',
      name: 'White Shrimp',
      image: 'assets/images/image copy 11.png',
      price: 349,
      weight: '500g',
      category: 'White Shrimp',
      description:
          'White Shrimp is one of the most popular and widely consumed shrimp varieties across the world. Known for its mild flavor, firm texture, and high nutritional value, it is perfect for everyday home cooking as well as gourmet recipes. At Shrimpbite, our White Shrimp is sourced directly from trusted Indian aqua farmers, ensuring freshness, quality, and food safety in every pack.',
      whyChoose: [
        'Fresh and Naturally Sweet Flavor',
        'Firm Texture ideal for frying, grilling, curries, and stir-fries',
        'High in Protein & Low in Fat',
        'Zero Preservatives & Antibiotic-Free',
        'Sustainably Farmed & Hygienically Processed',
        'Available in Multiple Sizes for All Cooking Needs',
      ],
    ),
    Product(
      id: 'p2',
      name: 'Tiger Prawns',
      image: 'assets/images/shrimp_tiger_trio.png',
      price: 499,
      weight: '1kg',
      category: 'Tiger Shrimp',
      isFavorite: true,
      description:
          'Tiger Prawns are known for their spectacular size and bold, sweet flavor. Their distinctive stripes make them a chef favorite for presentation. These Jumbo prawns are perfect for big feasts.',
      whyChoose: [
        'Large, juicy meat with a sweet finish',
        'Perfect for tandoori, bbq, and grilling',
        'Rich in Omega-3 fatty acids for heart health',
        'Individually Quick Frozen to lock in peak freshness',
        'Naturally sourced from sustainable coastal farms',
      ],
    ),
    Product(
      id: 'p3',
      name: 'King Thai Shrimps',
      image: 'assets/images/shrimp_lemon_herb.png',
      price: 649,
      weight: '500g',
      category: 'White Shrimp',
      description:
          'Authentic King Thai Shrimps, marinated with subtle herbs for a unique coastal flavor. Best enjoyed sautéed or in light broths. A premium variety sought after for its delicate snap.',
      whyChoose: [
        'Premium export quality sourced for retail',
        'De-veined and cleaned for your convenience',
        'Consistent size and quality in every pack',
        'Chemical-free and natural processing',
      ],
    ),
    Product(
      id: 'p4',
      name: 'Cooked Prawns Duo',
      image: 'assets/images/shrimp_cooked_duo.png',
      price: 349,
      weight: '250g',
      category: 'Peeled Shrimp',
      description:
          'Perfectly steamed and ready-to-eat prawns. Save time in the kitchen without compromising on that fresh seaside taste. These are pre-peeled and cooked to perfection.',
      whyChoose: [
        'Ready to eat - just thaw and serve in minutes',
        'Uniformly cooked to maintain juicy texture',
        'Ideal for salads, rolls, and shrimp cocktails',
        'No mess, no hassle cleaning needed',
      ],
    ),
    Product(
      id: 'p5',
      name: 'Fresh Shrimps',
      image: 'assets/images/shrimp_fresh_pile.png',
      price: 249,
      weight: '500g',
      category: 'Peeled Shrimp',
      description:
          'Daily catch fresh shrimps, delivered straight from the coast to your kitchen. Vibrant, tender, and full of natural sea flavor. These are the foundation of any great seafood dish.',
      whyChoose: [
        'Caught and delivered within 24 hours of sea time',
        'Never frozen, always fresh and chilled',
        'Sweet coastal flavor with a clean finish',
        'Hygienically sorted and packed in safe containers',
      ],
    ),
    Product(
      id: 'p6',
      name: 'Spicy Prawn Curry',
      image: 'assets/images/image copy 10.png',
      price: 549,
      weight: '1 portion',
      category: 'Grocery',
      description:
          'Chef-crafted spicy prawn curry, ready to heat and eat. A perfect blend of traditional Indian spices and creamy coconut milk. Experience the authentic taste of the coast.',
      whyChoose: [
        'Authentic coastal recipe with secret spices',
        'Ready in 5 minutes - heat and serve',
        'Made with fresh, premium prawns',
        'No artificial colors or added MSG',
      ],
    ),
    Product(
      id: 'p7',
      name: 'Lemon Garlic Shrimp',
      image: 'assets/images/image copy 5.png',
      price: 599,
      weight: '1 plate',
      category: 'Grocery',
      description:
          'Tangy and buttery lemon garlic shrimp. A restaurant-style delicacy in the comfort of your home. Perfect for a quick dinner or a fancy appetizer.',
      whyChoose: [
        'Infused with fresh lemon zest and garlic',
        'Tender, melt-in-your-mouth shrimp',
        'Low calorie and high in protein',
        'Chef-suggested pairing with sourdough or pasta',
      ],
    ),
    Product(
      id: 'p8',
      name: 'Farm Fresh Prawns',
      image: 'assets/images/image copy 3.png',
      price: 429,
      weight: '500g',
      category: 'White Shrimp',
      description:
          'Quality prawns from our sustainably managed aqua farms. Healthy, safe, and delicious. We monitor every stage of growth to ensure the highest standards.',
      whyChoose: [
        'Traceable back to the farm of origin',
        'Balanced diet for shrimps ensures better nutrition',
        'Stringent quality checks at every harvest',
        'Available year-round with consistent flavor',
      ],
    ),
    Product(
      id: 'p9',
      name: 'Sizzling Garlic Shrimp',
      image: 'assets/images/shrimp_dish_1.png',
      price: 549,
      weight: '250g',
      category: 'Grocery',
      description:
          'Our best-selling Sizzling Garlic Shrimp is a flavor explosion. Tossed in a rich garlic butter sauce with a hint of chili, it is the ultimate comfort food for seafood lovers.',
      whyChoose: [
        'Intense garlic flavor in every bite',
        'Perfectly sautéed to retain juice',
        'Great source of lean protein',
        'Top-rated by our regular customers',
      ],
    ),
    Product(
      id: 'p10',
      name: 'Peppery Onion Prawns',
      image: 'assets/images/shrimp_dish_2.png',
      price: 489,
      weight: '300g',
      category: 'Grocery',
      description:
          'A rustic and hearty dish featuring prawns sautéed with crushed black pepper and caramelised onions. This dish brings out the earthy flavors of Indian coastal cuisine.',
      whyChoose: [
        'Traditional "Ved" style cooking inspiration',
        'Freshly ground black pepper for a sharp kick',
        'No added preservatives or processing',
        'High in antioxidants from natural spices',
      ],
    ),
    Product(
      id: 'p11',
      name: 'Honey Chilli Shrimp',
      image: 'assets/images/shrimp_dish_3.png',
      price: 599,
      weight: '1 plate',
      category: 'Grocery',
      description:
          'A delightful Indo-Chinese fusion dish. Crispy shrimp glazed in a sweet and spicy honey-chili sauce, topped with sesame seeds. A perfect party starter.',
      whyChoose: [
        'The perfect balance of sweet and spicy',
        'Crispy texture with a juicy core',
        'Restaurant-style quality at home',
        'Guaranteed hit for all age groups',
      ],
    ),
    Product(
      id: 'p12',
      name: 'Spicy Fried Shrimp',
      image: 'assets/images/shrimp_dish_4.png',
      price: 529,
      weight: '400g',
      category: 'Grocery',
      description:
          'Classic crispy fried shrimp with a spicy rub. These are golden-brown on the outside and tender on the inside. Served best with a tangy dip.',
      whyChoose: [
        'Extra crispy coating with signature spices',
        'Ideal snack for game nights or gatherings',
        'Sourced from the freshest daily catch',
        'High nutritional value in every bite',
      ],
    ),
    Product(
      id: 'p13',
      name: 'Zesty Lemon Prawns',
      image: 'assets/images/shrimp_dish_5.png',
      price: 649,
      weight: '350g',
      category: 'Tiger Shrimp',
      description:
          'Refresh your palate with these Zesty Lemon Prawns. Marinated in a citrusy blend of lemon juice, cilantro, and mild spices. Light and healthy.',
      whyChoose: [
        'Zesty and refreshing citrus flavor profile',
        'Excellent for weight-watchers and healthy eaters',
        'Rich in Vitamin C and Essential minerals',
        'Pairs beautifully with grilled vegetables',
      ],
    ),
    Product(
      id: 'p14',
      name: 'Classic Cooked Shrimps',
      image: 'assets/images/shrimp_dish_6.png',
      price: 599,
      weight: '400g',
      category: 'Peeled Shrimp',
      description:
          'Simple, elegant, and timeless. These shrimps are lightly seasoned and perfectly cooked to highlight their natural sweetness. The pure taste of Shrimpbite.',
      whyChoose: [
        'Pure taste of the ocean with minimal seasoning',
        'Perfectly cleaned and deveined',
        'Ideal for pastas, salads, and more',
        'The gold standard of prepared seafood',
      ],
    ),
    Product(
      id: 'p15',
      name: 'Fresh Broccoli',
      image: 'assets/images/image copy 7.png',
      price: 49,
      weight: '250g',
      category: 'Vegetables',
      description:
          'Farm-fresh green broccoli. rich in fiber and vitamins. Perfect for steamed sides or healthy stir-fries.',
      whyChoose: [
        'Organically grown without pesticides',
        'High in antioxidants and vitamin K',
        'Crispy and tender texture when cooked',
      ],
    ),
    Product(
      id: 'p16',
      name: 'Red Bell Peppers',
      image: 'assets/images/image copy 5.png',
      price: 89,
      weight: '2 pcs',
      category: 'Vegetables',
      description:
          'Sweet and vibrant red bell peppers. Adds a crunch and color to any dish. Sourced daily for peak flavor.',
      whyChoose: [
        'Rich in Vitamin C and A',
        'Versatile for salads, roasting, or stuffing',
        'Sweet, low-acid flavor profile',
      ],
    ),
    Product(
      id: 'p18',
      name: 'Organic Carrots',
      image: 'assets/images/image copy 11.png',
      price: 39,
      weight: '500g',
      category: 'Vegetables',
      description:
          'Sweet and crunchy organic carrots. Perfect for salads, juices, or as a healthy snack.',
      whyChoose: [
        'Loaded with Beta-Carotene',
        'Farm-fresh and soil-grown',
        'Great for eye health',
      ],
    ),
    Product(
      id: 'p20',
      name: 'Baby Spinach',
      image: 'assets/images/image copy 7.png',
      price: 29,
      weight: '100g',
      category: 'Vegetables',
      description:
          'Tender baby spinach leaves, pre-washed and ready for your salads or green smoothies.',
      whyChoose: [
        'Iron-rich superfood',
        'Zero pesticide residue',
        'Delicate and mild flavor',
      ],
    ),
  ];

  List<Product> getProductsByCategory(String category) {
    return _recommendedProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<Product> get recommendedProducts => _recommendedProducts;

  List<CartItem> get items => List.unmodifiable(_items);
  List<FoodCategory> get foodCategories => _foodCategories;
  List<Restaurant> get restaurants => _restaurants;
  List<UserOrder> get orders => _orders;
  List<UserAddress> get addresses => _addresses;
  List<UserPaymentMethod> get payments => _payments;
  UserProfile get userProfile => _userProfile;

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  void clearSession() {
    _userProfile = const UserProfile(
      name: 'Guest User',
      email: '',
      phone: '',
      profileImage: 'assets/images/image copy 2.png',
    );
    _items.clear();
    _favoriteIds.clear();
    notifyListeners();
  }

  // ── API Integration ───────────────────────────────────────────────────────
  /// Syncs the local cart with the backend.
  Future<void> loadCartFromApi() async {
    if (_service == null) return;
    try {
      final remoteItems = await _service!.getCart();
      _items.clear();
      _items.addAll(remoteItems);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from API: $e');
    }
  }

  final List<String> _favoriteIds = ['1', '3']; // Default favorites for demo

  List<Restaurant> get favRestaurants {
    if (_restaurants.isEmpty) return [];
    
    final List<Restaurant> favs = [];
    for (var id in _favoriteIds) {
      final r = _restaurants.firstWhere((res) => res.id == id,
          orElse: () => _restaurants.first);
      if (!_favoriteIds.contains(r.id)) {
        continue; // Double check but it should be fine
      }
      if (!favs.contains(r)) {
        favs.add(r);
      }
    }
    
    // Correct way: map ids to restaurants in order
    return _favoriteIds
        .map((id) => _restaurants.firstWhere((r) => r.id == id,
            orElse: () => _restaurants.first))
        .toList();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void reorderFavorites(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final String item = _favoriteIds.removeAt(oldIndex);
    _favoriteIds.insert(newIndex, item);
    notifyListeners();
  }

  void addAddress(UserAddress address) async {
    if (_addressService != null) {
      final addressParts = address.details.split(',');
      final cityName = addressParts.isNotEmpty ? addressParts.first.trim() : 'City';
      final result = await _addressService!.saveAddress(
        label: address.title,
        fullAddress: address.street,
        city: cityName,
        state: address.details.contains(',')
            ? address.details.split(',')[1].trim()
            : '',
        pincode: address.details.split(' ').last,
        isDefault: address.isDefault,
      );
      if (result['success']) {
        loadAddresses();
      }
    } else {
      // Fallback for local testing
      if (address.isDefault) {
        for (int i = 0; i < _addresses.length; i++) {
          _addresses[i] = UserAddress(
            id: _addresses[i].id,
            title: _addresses[i].title,
            street: _addresses[i].street,
            details: _addresses[i].details,
            isDefault: false,
          );
        }
      }
      _addresses.add(address);
      notifyListeners();
    }
  }

  Future<void> loadAddresses() async {
    if (_addressService == null) return;
    _isAddressesLoading = true;
    notifyListeners();

    try {
      final token = await ApiClient.getToken();
      if (token == null || token.isEmpty) {
        _isAddressesLoading = false;
        notifyListeners();
        return;
      }

      final result = await _addressService!.getAddresses();
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        _addresses = data
            .map((json) => UserAddress(
                  id: json['_id'] ?? '',
                  title: json['label'] ?? 'Address',
                  street: json['fullAddress'] ?? '',
                  details:
                      '${json['city'] ?? ''}, ${json['state'] ?? ''} ${json['pincode'] ?? ''}',
                  isDefault: json['isDefault'] ?? false,
                ))
            .toList();

        // Reset selection to default address if available
        final defaultIdx = _addresses.indexWhere((a) => a.isDefault);
        if (defaultIdx != -1) {
          _selectedAddressIndex = defaultIdx;
        } else if (_addresses.isNotEmpty) {
          _selectedAddressIndex = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      _isAddressesLoading = false;
      notifyListeners();
    }
  }

  void updateAddress(UserAddress address) {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      if (address.isDefault) {
        for (int i = 0; i < _addresses.length; i++) {
          _addresses[i] = UserAddress(
            id: _addresses[i].id,
            title: _addresses[i].title,
            street: _addresses[i].street,
            details: _addresses[i].details,
            isDefault: false,
          );
        }
      }
      _addresses[index] = address;
      notifyListeners();
    }
  }

  void removeAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shippingCharges => _items.isEmpty ? 0.0 : 1.6;

  double get total => subtotal + shippingCharges;

  bool isInCart(String title) {
    return _items.any((item) => item.title == title);
  }

  String? get cartShopId => _items.isEmpty ? null : _items.first.shopId;
  String? get cartShopName => _items.isEmpty ? null : _items.first.shopName;

  bool isSameShop(String? shopId) {
    if (_items.isEmpty) return true;
    if (shopId == null) return true;
    return cartShopId == shopId;
  }

  void addToCart(CartItem cartItem) {
    final idx = _items.indexWhere((item) => item.title == cartItem.title);
    if (idx >= 0) {
      _items[idx].quantity += cartItem.quantity;
      if (_service != null) {
        _service!.updateQuantity(_items[idx].id, _items[idx].quantity);
      }
    } else {
      _items.add(cartItem);
      if (_service != null) {
        _service!.addToCart(cartItem.id, cartItem.quantity);
      }
    }
    notifyListeners();
  }

  void increment(String title) {
    final idx = _items.indexWhere((item) => item.title == title);
    if (idx >= 0) {
      _items[idx].quantity++;
      if (_service != null) {
        _service!.updateQuantity(_items[idx].id, _items[idx].quantity);
      }
      notifyListeners();
    }
  }

  void decrement(String title) {
    final idx = _items.indexWhere((item) => item.title == title);
    if (idx >= 0) {
      final itemId = _items[idx].id;
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
        if (_service != null) {
          _service!.updateQuantity(itemId, _items[idx].quantity);
        }
      } else {
        _items.removeAt(idx);
        if (_service != null) {
          _service!.removeFromCart(itemId);
        }
      }
      notifyListeners();
    }
  }

  void removeItem(String title) {
    _items.removeWhere((item) => item.title == title);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    if (_service != null) {
      _service!.clearCart();
    }
    notifyListeners();
  }
}

// InheritedNotifier wrapper so screens can access CartProvider without extra packages
class CartProviderScope extends InheritedNotifier<CartProvider> {
  const CartProviderScope({
    super.key,
    required CartProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static CartProvider of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CartProviderScope>()!
        .notifier!;
  }
}
