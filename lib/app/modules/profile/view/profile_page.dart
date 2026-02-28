import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section.dart';
import './profile_detail_page.dart';
import './edit_profile_page.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/models/food_models.dart';
import '../../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final provider = CartProviderScope.of(context, listen: false);
    final token = provider.userProfile.token;

    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);

    final response = await _profileService.fetchProfile(token: token);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      provider.updateUserProfile(
        UserProfile(
          name: data['fullName'] ?? provider.userProfile.name,
          email: data['email'] ?? provider.userProfile.email,
          phone: data['phoneNumber'] ?? provider.userProfile.phone,
          profileImage: provider.userProfile.profileImage, // retain current
          token: token,
        ),
      );

      // Parse Addresses if present
      if (data['addresses'] != null && data['addresses'] is List) {
        final List<dynamic> addressList = data['addresses'];
        final parsedAddresses = addressList.map((addr) {
          return UserAddress(
            id: addr['_id']?.toString() ?? UniqueKey().toString(),
            title: addr['label'] ?? 'Other',
            street: addr['fullAddress'] ?? '',
            details:
                '${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pincode'] ?? ''}'
                    .trim(),
            isDefault: addr['isDefault'] ?? false,
          );
        }).toList();

        provider.updateUserAddresses(parsedAddresses);
      }
    }

    setState(() => _isLoading = false);
  }

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : SingleChildScrollView(
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
                        onTap: () =>
                            _navigateToDetail(context, 'Notifications'),
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
