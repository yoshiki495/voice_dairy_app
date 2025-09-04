import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: authState.user != null ? '/home' : '/signin',
    redirect: (context, state) {
      final isAuthenticated = authState.user != null;
      final isLoading = authState.isLoading;
      
      // ローディング中は現在の画面を維持
      if (isLoading) return null;
      
      final isOnAuthScreen = state.matchedLocation == '/signin' || 
                           state.matchedLocation == '/signup';
      
      // 未認証でauth画面以外にいる場合はサインイン画面へ
      if (!isAuthenticated && !isOnAuthScreen) {
        return '/signin';
      }
      
      // 認証済みでauth画面にいる場合はホーム画面へ
      if (isAuthenticated && isOnAuthScreen) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/record',
        name: 'record',
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'ページが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${state.uri}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
  );
});
