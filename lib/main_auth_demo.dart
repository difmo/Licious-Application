import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/auth_guard.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_notifier.dart';

// Protected Home Screen Example
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home (Protected)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to the internal dashboard!')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load Environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Production Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // 2. Use AuthGuard at the root of navigation
      home: AuthGuard(
        authenticatedRoute: const HomeScreen(),
        unauthenticatedRoute: const LoginScreen(),
      ),
    );
  }
}
