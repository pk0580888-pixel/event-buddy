import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My attendance')),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: AttendanceService().watchForStudent(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load attendance.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final attendance = snapshot.data ?? const <AttendanceModel>[];
          if (attendance.isEmpty) {
            return const Center(
              child: Text('Attendance will appear here after you check in.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: attendance.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = attendance[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(item.eventTitle),
                  subtitle: Text(
                    item.scannedAt == null
                        ? 'Present'
                        : 'Present • ${_format(item.scannedAt!)}',
                  ),
                  trailing: const Text(
                    'PRESENT',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _format(DateTime value) =>
      '${value.day}/${value.month}/${value.year} at '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
