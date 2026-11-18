import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'admin_dashboard.dart';
import 'models/user_profile.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/auth/invitation_completion_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'services/user_profile_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _invitationLink;

  @override
  void initState() {
    super.initState();
    _listenForInvitationLinks();
  }

  Future<void> _listenForInvitationLinks() async {
    final links = AppLinks();
    try {
      // When the link opens the hosted Flutter web app, the email action
      // parameters are available in the browser URL instead of App Links.
      _setInvitationLink(Uri.base);
      final initialLink = await links.getInitialLink();
      _setInvitationLink(initialLink);
      _linkSubscription = links.uriLinkStream.listen(_setInvitationLink);
    } catch (_) {
      // The app can still run normally if deep-link support is unavailable.
    }
  }

  void _setInvitationLink(Uri? link) {
    if (link == null) return;
    try {
      final linkValue = link.toString();
      if (FirebaseAuth.instance.isSignInWithEmailLink(linkValue) && mounted) {
        if (_invitationLink?.toString() == linkValue) return;
        setState(() => _invitationLink = link);
      }
    } catch (_) {
      // Ignore unrelated application links.
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_invitationLink != null) {
      return InvitationCompletionScreen(
        emailLink: _invitationLink.toString(),
        onCompleted: () => setState(() => _invitationLink = null),
      );
    }
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }
          final user = snapshot.data;
          if (user == null) return const WelcomeScreen();
          return _ProfileGate(user: user);
        },
      );
    } catch (_) {
      return const WelcomeScreen();
    }
  }
}

class _ProfileGate extends StatelessWidget {
  const _ProfileGate({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: UserProfileService().getProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final profile = snapshot.data;
        if (snapshot.hasError || profile == null) {
          return const _ProfileErrorScreen();
        }
        return profile.isAdmin
            ? const AdminDashboard()
            : const StudentDashboard();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  const _ProfileErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We could not load your account profile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
