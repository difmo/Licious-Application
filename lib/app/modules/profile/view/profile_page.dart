import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section.dart';
import './profile_detail_page.dart';
import './edit_profile_page.dart';
import '../../../data/services/db_service.dart';
import '../../auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _navigateToDetail(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileDetailPage(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = CartProviderScope.of(context);
    final profile = provider.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Profile Info
            ProfileHeader(
              userName: profile.name,
              userEmail: profile.email,
              profileImage: profile.profileImage,
              onEditProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
              onImageTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
            ),

            // Unified Settings List
            SettingsSection(
              items: [
                SettingsItem(
                  icon: Icons.person_outline,
                  title: 'About me',
                  onTap: () => _navigateToDetail(context, 'About me'),
                ),
                SettingsItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'My Orders',
                  onTap: () => _navigateToDetail(context, 'My Orders'),
                ),
                SettingsItem(
                  icon: Icons.favorite_border,
                  title: 'My Favorites',
                  onTap: () => _navigateToDetail(context, 'My Favorites'),
                ),
                SettingsItem(
                  icon: Icons.location_on_outlined,
                  title: 'My Address',
                  onTap: () => _navigateToDetail(context, 'My Address'),
                ),
                SettingsItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Credit Cards',
                  onTap: () => _navigateToDetail(context, 'Credit Cards'),
                ),
                SettingsItem(
                  icon: Icons.sync_alt,
                  title: 'Transactions',
                  onTap: () => _navigateToDetail(context, 'Transactions'),
                ),
                SettingsItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () => _navigateToDetail(context, 'Notifications'),
                ),
                SettingsItem(
                  icon: Icons.logout,
                  title: 'Sign out',
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),

            // Bottom Spacing (Extra for navigation bar)
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
