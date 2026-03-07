import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_card_page.dart';

class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({super.key});

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage> {
  // Dummy saved cards list for the UI
  List<Map<String, dynamic>> savedCards = [
    {
      'id': '1',
      'number': '5129 6589 5932 0809',
      'name': 'VIMAL ANAND',
      'expiry': '05/19',
      'validFrom': '05/16',
      'type': 'visa',
      'colors': [const Color(0xFF6271D8), const Color(0xFF9066D6)],
      'isDefault': true,
    },
    {
      'id': '2',
      'number': '5128 6701 0095 0337',
      'name': 'DEEP ANAND',
      'expiry': '05/19',
      'validFrom': '07/15',
      'type': 'mastercard',
      'colors': [const Color(0xFFFCA36A), const Color(0xFFF9608B)],
      'isDefault': false,
    },
  ];

  void _onAddCard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SAVED CARDS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemCount: savedCards.length,
              itemBuilder: (context, index) {
                final card = savedCards[index];
                return _buildCardItem(card);
              },
            ),
          ),
          _buildAddCardButton(),
        ],
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: card['colors'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: card['colors'][1].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chip
              Container(
                width: 45,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Center(
                    child: Icon(Icons.grid_3x3,
                        color: Colors.white.withValues(alpha: 0.4), size: 20)),
              ),
              // Card Logo
              Text(
                card['type'] == 'visa' ? 'VISA' : 'mastercard',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            card['number'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            card['name'].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('MEMBER SINCE 16 DC RW',
                      style: TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VALID ${card['validFrom']}  THRU ${card['expiry']}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 8)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    savedCards.removeWhere((c) => c['id'] == card['id']);
                  });
                },
                child:
                    const Icon(Icons.delete, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GestureDetector(
          onTap: _onAddCard,
          child: Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6271D8), Color(0xFF9066D6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9066D6).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: Colors.white, size: 30),
                Text(
                  'ADD NEW CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
