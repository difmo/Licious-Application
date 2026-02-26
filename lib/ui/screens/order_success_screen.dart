import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Success',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shopping bag icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: CustomPaint(
                      painter: _ShoppingBagPainter(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Your order was\nsuccesfull !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You will get a response within\na few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Track Order button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to home / track order page
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B24D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Track order',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws the shopping bag outline icon in green
class _ShoppingBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38B24D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double cx = size.width / 2;
    final double bagTop = size.height * 0.38;
    final double bagBottom = size.height * 0.88;
    final double bagLeft = size.width * 0.18;
    final double bagRight = size.width * 0.82;

    // --- Draw bag body ---
    final bagPath = Path();
    // top-left corner
    bagPath.moveTo(bagLeft + 10, bagTop);
    // top edge left side
    bagPath.lineTo(bagLeft, bagTop + 8);
    // left edge going down (slight inward trapezoid)
    bagPath.lineTo(bagLeft * 0.6, bagBottom - 10);
    // bottom-left rounded corner
    bagPath.quadraticBezierTo(bagLeft * 0.6, bagBottom, bagLeft * 0.6 + 10, bagBottom);
    // bottom edge
    bagPath.lineTo(bagRight * 1.0 + size.width * 0.2 - 10, bagBottom);
    // bottom-right rounded corner
    final double bagRightEdge = size.width - bagLeft * 0.6;
    bagPath.quadraticBezierTo(
        bagRightEdge, bagBottom, bagRightEdge, bagBottom - 10);
    // right edge going up
    bagPath.lineTo(bagRight, bagTop + 8);
    // top-right corner
    bagPath.lineTo(bagRight - 10, bagTop);
    bagPath.close();

    canvas.drawPath(bagPath, paint);

    // --- Draw handle ---
    final handlePath = Path();
    final double handleLeft = cx - size.width * 0.18;
    final double handleRight = cx + size.width * 0.18;
    final double handleTop = size.height * 0.12;
    handlePath.moveTo(handleLeft, bagTop);
    handlePath.cubicTo(
      handleLeft, handleTop,
      handleRight, handleTop,
      handleRight, bagTop,
    );
    canvas.drawPath(handlePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
