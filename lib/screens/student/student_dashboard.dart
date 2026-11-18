import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import 'events_screen.dart';
import 'registrations_screen.dart';
import 'scores_screen.dart';
import 'certificates_screen.dart';
import 'attendance_screen.dart';
import 'edit_profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [_homePage(), _eventsPage(), _profilePage()];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Buddy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _EventBuddyLogoMark(),
          ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _homePage() {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hello, ${user?.displayName ?? 'Student'}!',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF192D53),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find your next campus experience.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 18),
        _homeHero(),
        const SizedBox(height: 26),
        StreamBuilder<List<AnnouncementModel>>(
          stream: AnnouncementService().watchPublished(),
          builder: (context, snapshot) {
            final announcements = snapshot.data ?? const <AnnouncementModel>[];
            if (announcements.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest announcements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...announcements
                    .take(3)
                    .map(
                      (announcement) => Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(Icons.campaign_outlined),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      announcement.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      announcement.message,
                                      style: const TextStyle(height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
              ],
            );
          },
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF192D53), Color(0xFF3975FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.explore_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Events',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Browse upcoming campus events and register.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 17),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _homeHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 148,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF172E61), Color(0xFF3975FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -42,
              child: _heroOrb(size: 145, color: Color(0x333DD9FF)),
            ),
            Positioned(
              right: 72,
              bottom: -54,
              child: _heroOrb(size: 120, color: Color(0x225E4DFF)),
            ),
            Positioned(
              right: 22,
              top: 19,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFBCEEFF),
                    size: 32,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 116, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42D5F5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'CAMPUS LIFE, YOUR WAY',
                      style: TextStyle(
                        color: Color(0xFFBCEEFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Make every campus moment count.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explore. Connect. Celebrate.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _eventsPage() => const StudentEventsScreen();

  Widget _profilePage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please sign in again.'));
    return StreamBuilder<UserProfile?>(
      stream: UserProfileService().watchProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _profileHeader(profile, user),
            const SizedBox(height: 18),
            if (profile != null)
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditStudentProfileScreen(profile: profile),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            const SizedBox(height: 18),
            const _ProfileSectionTitle(title: 'Your Event Buddy'),
            _profileAction(
              icon: Icons.confirmation_num_outlined,
              color: const Color(0xFF3975FF),
              title: 'My registrations',
              subtitle: 'View your confirmed event registrations.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentRegistrationsScreen(),
                ),
              ),
            ),
            _profileAction(
              icon: Icons.emoji_events_outlined,
              color: const Color(0xFFE18A13),
              title: 'My scores',
              subtitle: 'View scores assigned for your events.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentScoresScreen()),
              ),
            ),
            _profileAction(
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF16A085),
              title: 'My attendance',
              subtitle: 'See the events where you were present.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentAttendanceScreen(),
                ),
              ),
            ),
            _profileAction(
              icon: Icons.workspace_premium_outlined,
              color: const Color(0xFF7B4BC4),
              title: 'My certificates',
              subtitle:
                  'Download your participation and appreciation certificates.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentCertificatesScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFFFF3F1),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFDCD7),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    color: Color(0xFFD94A3A),
                  ),
                ),
                title: const Text(
                  'Account recovery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Reset your password or get sign-in help.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRecoveryHelp(
                  context,
                  profile?.email ?? user.email ?? '',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout, color: Color(0xFFD94A3A)),
              label: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFD94A3A)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileHeader(UserProfile? profile, User user) {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : user.displayName ?? 'Student';
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : user.email ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF192D53), Color(0xFF3975FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33192D53),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 43,
            backgroundColor: Colors.white,
            backgroundImage: profile?.photoUrl?.isNotEmpty == true
                ? NetworkImage(profile!.photoUrl!)
                : (user.photoURL?.isNotEmpty == true
                      ? NetworkImage(user.photoURL!)
                      : null),
            child:
                (profile?.photoUrl?.isNotEmpty != true &&
                    user.photoURL?.isNotEmpty != true)
                ? const Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: Color(0xFF3975FF),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.white70)),
          if (profile?.studentId?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Student ID: ${profile!.studentId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _profileAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showRecoveryHelp(BuildContext context, String email) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account recovery'),
        content: Text(
          email.isEmpty
              ? 'Open Edit profile to add your email, then use the password reset option.'
              : 'Your registered email is $email. Use it to reset your password. If you no longer have access to this email, contact the Event Buddy administrator to verify your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (email.isNotEmpty)
            FilledButton(
              onPressed: () async {
                await AuthService().sendPasswordResetEmail(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset link sent.')),
                  );
                }
              },
              child: const Text('Send reset link'),
            ),
        ],
      ),
    );
  }
}

class _EventBuddyLogoMark extends StatelessWidget {
  const _EventBuddyLogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF213F82),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF42D5F5), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3342D5F5),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFF42D5F5),
              size: 22,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: Color(0xFF0E1D4D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF42D5F5),
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF192D53),
      ),
    ),
  );
}
