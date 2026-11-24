import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/admin/create_event_screen.dart';
import 'screens/admin/event_list_screen.dart';
import 'screens/admin/announcement_management_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/analysis_portal_screen.dart';
import 'screens/admin/feedback_management_screen.dart';
import 'screens/admin/participant_management_screen.dart';
import 'screens/admin/participant_export_screen.dart';
import 'screens/admin/certificate_management_screen.dart';
import 'screens/admin/top_performers_screen.dart';
import 'screens/admin/event_attendance_qr_screen.dart';
import 'screens/admin/score_management_screen.dart';
import 'screens/admin/attendance_scanner_screen.dart';
import 'screens/admin/team_access_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final Color navy = const Color(0xFF192D53);
  final Color blue = const Color(0xFF3975FF);

  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } on FirebaseException {
      // Widget tests can render the dashboard before a Firebase platform
      // channel is available. Production initialization still happens in
      // main() before the app is run.
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get eventsStream {
    final user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // Return to the root screen.
    // Your app's authentication screen should handle
    // the signed-out state.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [dashboardPage(), eventsPage(), profilePage()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: navy,
        title: const Text(
          'Event Buddy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: _AdminLogoMark(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showMessage('Notifications coming soon!'),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SafeArea(child: pages[selectedIndex]),

      floatingActionButton: selectedIndex == 0 || selectedIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              onPressed: _openCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex,
        indicatorColor: const Color(0xFFE6EDFF),
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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

  // DASHBOARD PAGE

  Widget dashboardPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Welcome back, ${currentUser?.displayName ?? 'Admin'}!',
              style: TextStyle(
                color: navy,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your events from one place.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 18),

            adminHero(docs.length),

            const SizedBox(height: 22),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                statCard(
                  'Total Events',
                  '${docs.length}',
                  Icons.event,
                  Colors.blue,
                ),
                statCard('Participants', '0', Icons.people, Colors.green),
                statCard('Announcements', '0', Icons.campaign, Colors.orange),
                statCard('Reports', '0', Icons.analytics, Colors.purple),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Quick Actions',
              style: TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            quickAction(
              Icons.add_circle_outline,
              'Create New Event',
              'Organize a cultural event or hackathon',
              _openCreateEvent,
            ),

            quickAction(
              Icons.people_outline,
              'Manage Participants',
              'View and manage registrations',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParticipantManagementScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.group_add_outlined,
              'Team Access',
              'Authorize professors and event team members',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamAccessScreen()),
              ),
            ),

            quickAction(
              Icons.file_download_outlined,
              'Export Student Records',
              'Download Excel or PDF records',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParticipantExportScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.workspace_premium_outlined,
              'Manage Certificates',
              'Upload templates and publish certificates',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CertificateManagementScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.emoji_events_outlined,
              'Top Performers',
              'Show the top three students for each event',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopPerformersScreen()),
              ),
            ),

            quickAction(
              Icons.qr_code_2_outlined,
              'Event Attendance QR',
              'Display a unique QR for Google Form attendance',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventAttendanceQrScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.emoji_events_outlined,
              'Assign Scores',
              'Record participant event scores',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScoreManagementScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.table_chart_outlined,
              'Analysis Portal',
              'View attendance, scores, feedback, and event history in one live sheet',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalysisPortalScreen()),
              ),
            ),

            quickAction(
              Icons.qr_code_scanner,
              'Scan QR Attendance',
              'Mark attendance from a student event pass',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendanceScannerScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.edit_calendar_outlined,
              'Mark Manual Attendance',
              'Use this when a student cannot scan their pass',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManualAttendanceScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.campaign_outlined,
              'Announcements',
              'Share important event updates',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnnouncementManagementScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.rate_review_outlined,
              'Review Feedback',
              'Read student ratings and comments',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FeedbackManagementScreen(),
                ),
              ),
            ),

            quickAction(
              Icons.analytics_outlined,
              'Reports & Analytics',
              'View event performance',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              'Recent Events',
              style: TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              const Text('Unable to load events.')
            else if (docs.isEmpty)
              emptyEvents()
            else
              ...docs.take(3).map((doc) {
                return eventCard(doc.data());
              }),
          ],
        );
      },
    );
  }

  Widget adminHero(int eventCount) {
    return Container(
      height: 142,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -52,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x223DD9FF),
              ),
            ),
          ),
          Positioned(
            right: 26,
            bottom: 18,
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white.withValues(alpha: 0.17),
              size: 76,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 100, 18),
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
                    'ORGANIZER CONTROL CENTER',
                    style: TextStyle(
                      color: Color(0xFFBCEEFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Your campus, beautifully organized.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$eventCount ${eventCount == 1 ? 'event' : 'events'} currently in your workspace',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATISTICS CARD

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // QUICK ACTION CARD

  Widget quickAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) {
    final actionColor = _actionColor(title);
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: actionColor.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: actionColor.withValues(alpha: 0.12),
          child: Icon(icon, color: actionColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: action,
      ),
    );
  }

  Color _actionColor(String title) {
    if (title.contains('Create')) return const Color(0xFF3975FF);
    if (title.contains('Participant') || title.contains('Attendance')) {
      return const Color(0xFF16A085);
    }
    if (title.contains('Certificate') || title.contains('Performer')) {
      return const Color(0xFF7B4BC4);
    }
    if (title.contains('Score')) return const Color(0xFFE18A13);
    if (title.contains('Announcement')) return const Color(0xFFE18A13);
    if (title.contains('Feedback')) return const Color(0xFFD94A7A);
    if (title.contains('Report') || title.contains('Export')) {
      return const Color(0xFF3975FF);
    }
    return blue;
  }

  Widget eventsPage() => const AdminEventListScreen();

  Future<void> _openCreateEvent() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
  }

  // Legacy dashboard event view retained for compatibility with existing data.

  Widget legacyEventsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading events.'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 70, color: Colors.grey.shade400),
                const SizedBox(height: 15),
                const Text(
                  'No events created yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Create your first event to get started.'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Manage Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 15),
            ...docs.map((doc) => eventCard(doc.data())),
          ],
        );
      },
    );
  }

  // EVENT CARD

  Widget eventCard(Map<String, dynamic> data) {
    final eventDate = data['eventDate'];

    String date = 'Date not available';

    if (eventDate is Timestamp) {
      date =
          '${eventDate.toDate().day}/${eventDate.toDate().month}/${eventDate.toDate().year}';
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF0FF),
          child: Icon(Icons.event, color: Color(0xFF3975FF)),
        ),
        title: Text(
          data['title'] ?? 'Untitled Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${data['category'] ?? 'Event'} • $date\n'
          '${data['venue'] ?? 'Venue not specified'}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget emptyEvents() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note, size: 45, color: Colors.grey),
          SizedBox(height: 10),
          Text('No events yet', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Create your first event using the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // CREATE EVENT

  Future<void> createEvent() async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController();
    final venueController = TextEditingController();

    String category = 'Cultural Event';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Event'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Name',
                          hintText: 'Enter event name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter event name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Event Category',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cultural Event',
                            child: Text('Cultural Event'),
                          ),
                          DropdownMenuItem(
                            value: 'Hackathon',
                            child: Text('Hackathon'),
                          ),
                          DropdownMenuItem(
                            value: 'Competition',
                            child: Text('Competition'),
                          ),
                          DropdownMenuItem(
                            value: 'Communication Event',
                            child: Text('Communication Event'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue',
                          hintText: 'Enter event location',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter venue';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Event Date'),
                        subtitle: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final user = currentUser;

                          if (user == null) {
                            showMessage('Please login again.');
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await FirebaseFirestore.instance
                                .collection('events')
                                .add({
                                  'title': titleController.text.trim(),
                                  'category': category,
                                  'venue': venueController.text.trim(),
                                  'eventDate': Timestamp.fromDate(selectedDate),
                                  'createdBy': user.uid,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'status': 'draft',
                                });

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            showMessage('Event created successfully!');
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });
                            showMessage('Could not create event: $e');
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Event'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    venueController.dispose();
  }

  // PROFILE PAGE

  Widget profilePage() {
    final user = currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF192D53), Color(0xFF3975FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 48,
                  color: Color(0xFF3975FF),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.displayName ?? 'Admin',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? 'No email available',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ADMINISTRATOR • ORGANIZER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Account Type'),
                subtitle: Text('Admin / Organizer'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.security_outlined),
                title: Text('Authentication'),
                subtitle: Text('Firebase'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminLogoMark extends StatelessWidget {
  const _AdminLogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF213F82),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF42D5F5), width: 2),
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
