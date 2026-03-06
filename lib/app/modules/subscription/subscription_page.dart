import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/subscription_service.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/liciousimage.jpeg', // Using an existing background asset
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha:  0.3)),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: subscriptionAsync.when(
                    data: (plans) {
                      if (plans.isEmpty) {
                        return const Center(
                          child: Text(
                            'No plans available',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            const Text(
                              'Choose Your Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Horizontal scrolling for plans if many, or just vertical list
                            // Based on image, it looks like a horizontal layout might be intended if there are only 2
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.center,
                                  children: plans.map((plan) {
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth > 600 
                                            ? (constraints.maxWidth - 40) / 2 
                                            : constraints.maxWidth,
                                      ),
                                      child: _PlanCard(plan: plan),
                                    );
                                  }).toList(),
                                );
                              }
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isGold = plan.name.toLowerCase().contains('gold');
    final isSilver = plan.name.toLowerCase().contains('silver');
    final isPopular = plan.badge?.toLowerCase() == 'popular' || isSilver;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:  0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha:  0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '£${plan.price}/${plan.billingCycle}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Features
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 30),
                
                // Button
                _GradientButton(
                  text: 'Select ${plan.name}',
                  isGold: isGold,
                  onPressed: () {
                    // Selection logic
                  },
                ),
              ],
            ),
          ),

          // Badge
          if (isPopular)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Most Popular',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final bool isGold;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.text,
    required this.isGold,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isGold
        ? const LinearGradient(
            colors: [Color(0xFFFF9D2E), Color(0xFFFF7E1A)],
          )
        : const LinearGradient(
            colors: [Color(0xFF4BAFFF), Color(0xFF2E8EFF)],
          );

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isGold ? const Color(0xFFFF7E1A) : const Color(0xFF2E8EFF))
                  .withValues(alpha:  0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}


