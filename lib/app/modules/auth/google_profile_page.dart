import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'provider/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'dart:async';

class GoogleProfilePage extends ConsumerStatefulWidget {
  final GoogleSignInAccount account;
  const GoogleProfilePage({super.key, required this.account});

  @override
  ConsumerState<GoogleProfilePage> createState() => _GoogleProfilePageState();
}

class _GoogleProfilePageState extends ConsumerState<GoogleProfilePage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _isAuthenticating = false;

  void _showSnackBar(String message, {Color color = Colors.black87}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _proceedToApp() async {
    setState(() => _isAuthenticating = true);
    try {
      final auth = await widget.account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _showSnackBar('Could not retrieve ID token from Google', color: Colors.red);
        setState(() => _isAuthenticating = false);
        return;
      }

      await ref.read(authProvider.notifier).googleAuth(idToken: idToken);

      if (!mounted) return;
      final authState = ref.read(authProvider);

      if (authState is AuthAuthenticated) {
        _showSnackBar('Successfully signed in!', color: Colors.green);
        if (authState.user.role == 'rider') {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.riderHome, (r) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        }
      } else if (authState is AuthError) {
        _showSnackBar(authState.message, color: Colors.red);
        ref.read(authProvider.notifier).reset();
      }
    } catch (e) {
      _showSnackBar('Authentication failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final initials = (account.displayName ?? 'G')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsible header ──
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _signOut(context),
                tooltip: 'Sign out',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Profile photo or initials avatar
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        child: account.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  account.photoUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        account.displayName ?? 'Google User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body sections ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account info card
                  _SectionCard(
                    title: 'Account Details',
                    children: [
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: account.displayName ?? 'Not available',
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: account.email,
                      ),
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Google ID',
                        value: account.id,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Settings card
                  _SectionCard(
                    title: 'Preferences',
                    children: [
                      _ToggleTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                      _ToggleTile(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        value: _darkModeEnabled,
                        onChanged: (v) => setState(() => _darkModeEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick actions card
                  _SectionCard(
                    title: 'Quick Actions',
                    children: [
                      _ActionTile(
                        icon: Icons.home_outlined,
                        label: 'Go to Home',
                        color: const Color(0xFF2E7D32),
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (r) => false,
                        ),
                      ),
                      _ActionTile(
                        icon: Icons.shopping_cart_outlined,
                        label: 'My Orders',
                        color: const Color(0xFF1976D2),
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                      ),
                      _ActionTile(
                        icon: Icons.person_outline,
                        label: 'Edit Profile',
                        color: const Color(0xFF7B1FA2),
                        onTap: () {},
                      ),
                      _ActionTile(
                        icon: Icons.logout,
                        label: 'Sign Out',
                        color: Colors.red,
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isAuthenticating ? null : _proceedToApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isAuthenticating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }
}

// ── Section card ──────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: value ? const Color(0xFF2E7D32) : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF2E7D32),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }
}

// ── Clickable action tile ─────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}
