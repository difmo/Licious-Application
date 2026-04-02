import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/review_service.dart';
import '../../../data/models/food_models.dart';

class OrderReviewDialog extends StatefulWidget {
  final UserOrder order;

  const OrderReviewDialog({
    super.key,
    required this.order,
  });

  @override
  State<OrderReviewDialog> createState() => _OrderReviewDialogState();
}

class _OrderReviewDialogState extends State<OrderReviewDialog> {
  int _orderRating = 5;
  String _orderComment = '';
  int _riderRating = 5;
  
  // Track ratings for each product in the order
  late Map<String, int> _productRatings;
  late Map<String, String> _productComments;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _productRatings = {
      for (var item in widget.order.items) item.productId: 5
    };
    _productComments = {
      for (var item in widget.order.items) item.productId: ''
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final reviewService = ref.read(reviewServiceProvider);
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate Your Experience', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Order Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                  _buildStarRating(_orderRating, (val) => setState(() => _orderRating = val)),
                  TextField(
                    onChanged: (val) => _orderComment = val,
                    decoration: InputDecoration(
                      hintText: 'Any feedback about the order?',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('Rate Delivery Rider', style: TextStyle(fontWeight: FontWeight.w600)),
                  _buildStarRating(_riderRating, (val) => setState(() => _riderRating = val)),
                  const Divider(height: 32),
                  const Text('Rate Items', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...widget.order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          Row(
                            children: [
                              _buildStarRating(
                                _productRatings[item.productId] ?? 5,
                                (val) => setState(() => _productRatings[item.productId] = val),
                                size: 24,
                              ),
                            ],
                          ),
                          TextField(
                            onChanged: (val) => _productComments[item.productId] = val,
                            decoration: InputDecoration(
                              hintText: 'Comment on this item (optional)',
                              hintStyle: const TextStyle(fontSize: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(reviewService),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF68B92E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit all', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarRating(int rating, Function(int) onRatingChanged, {double size = 32}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          iconSize: size,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.orange,
          ),
          onPressed: () => onRatingChanged(index + 1),
        );
      }),
    );
  }

  Future<void> _submit(ReviewService service) async {
    setState(() => _isSubmitting = true);
    
    final productReviews = widget.order.items.map((item) {
      return {
        'productId': item.productId,
        'rating': _productRatings[item.productId],
        'comment': _productComments[item.productId],
      };
    }).toList();

    final response = await service.submitOrderReview(
      orderId: widget.order.id,
      orderRating: _orderRating,
      orderComment: _orderComment,
      riderRating: _riderRating,
      productReviews: productReviews,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      // Capture messenger BEFORE popping the dialog
      final messenger = ScaffoldMessenger.of(context);
      
      if (response['success'] == true) {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to submit review')),
        );
      }
    }
  }
}
