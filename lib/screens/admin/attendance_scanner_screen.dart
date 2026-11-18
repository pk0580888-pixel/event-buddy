import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../services/attendance_service.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../services/user_profile_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  final _service = AttendanceService();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _processing = false;
  String? _message;
  AttendanceScanResult? _result;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;

    await _scannerController.pause();
    setState(() {
      _processing = true;
      _message = 'Checking pass…';
    });

    try {
      final result = await _service.markFromQr(value);
      if (!mounted) return;
      setState(() {
        _result = result;
        _message = result.alreadyMarked
            ? 'Already marked: ${result.attendance.participantName}\n'
                  '${result.attendance.eventTitle}'
            : 'Attendance marked for ${result.attendance.participantName}\n'
                  '${result.attendance.eventTitle}';
      });
    } on AttendanceFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Unable to mark attendance. Check your connection and try again.';
      });
    }
  }

  void _scanAgain() {
    setState(() {
      _processing = false;
      _message = null;
      _result = null;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan attendance QR')),
      body: _result != null ? _successView(_result!) : _scannerView(),
    );
  }

  Widget _scannerView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleBarcode,
              ),
              IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const Positioned(
                bottom: 28,
                left: 24,
                right: 24,
                child: Text(
                  'Place the student QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_message != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: const Color(0xFFFFEBEE),
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _successView(AttendanceScanResult result) {
    final isDuplicate = result.alreadyMarked;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDuplicate ? Icons.info_outline : Icons.check_circle,
              color: isDuplicate
                  ? Colors.orange.shade700
                  : Colors.green.shade600,
              size: 132,
            ),
            const SizedBox(height: 22),
            Text(
              isDuplicate ? 'Attendance already marked' : 'Attendance marked',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF192D53),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Present for ${result.attendance.eventTitle}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              result.attendance.participantName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 42),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan another pass'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final _searchController = TextEditingController();
  String? _selectedEventId;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectEvent(EventModel event) {
    _searchController.clear();
    setState(() {
      _selectedEventId = event.id;
      _query = '';
    });
  }

  void _backToEvents() {
    _searchController.clear();
    setState(() {
      _selectedEventId = null;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _selectedEventId == null
            ? null
            : IconButton(
                tooltip: 'Back to events',
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToEvents,
              ),
        title: Text(
          _selectedEventId == null ? 'Select event' : 'Manual attendance',
        ),
        bottom: _selectedEventId == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(74),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _searchField(context),
                ),
              ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().watchPublishedEvents(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventSnapshot.hasError) {
            return const Center(
              child: Text('Could not load published events.'),
            );
          }
          final events = eventSnapshot.data ?? const <EventModel>[];
          if (_selectedEventId == null) return _eventList(events);
          final selectedEvent = events.cast<EventModel?>().firstWhere(
            (event) => event?.id == _selectedEventId,
            orElse: () => null,
          );
          if (selectedEvent == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _backToEvents();
            });
            return const Center(
              child: Text('This event is no longer published.'),
            );
          }
          return _studentList(selectedEvent);
        },
      ),
    );
  }

  Widget _eventList(List<EventModel> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No published events available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(child: Icon(Icons.event_outlined)),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${event.category} • ${event.venue}\n'
              '${_dateLabel(event.startAt)}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectEvent(event),
          ),
        );
      },
    );
  }

  Widget _studentList(EventModel event) {
    return StreamBuilder<List<RegistrationModel>>(
      stream: RegistrationService().watchAllRegistrations(),
      builder: (context, registrationSnapshot) {
        if (registrationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (registrationSnapshot.hasError) {
          return const Center(child: Text('Could not load registrations.'));
        }
        return StreamBuilder(
          stream: UserProfileService().watchStudents(),
          builder: (context, profileSnapshot) {
            final profiles = (profileSnapshot.data ?? const [])
                .cast<dynamic>()
                .toList();
            final profileById = {
              for (final profile in profiles) profile.uid: profile,
            };
            final registrations = (registrationSnapshot.data ?? const [])
                .where(
                  (registration) =>
                      registration.status == 'confirmed' &&
                      registration.eventId == event.id &&
                      profileById.containsKey(registration.userId),
                )
                .where((registration) {
                  final profile = profileById[registration.userId];
                  final text = [
                    registration.participantName,
                    profile.fullName,
                    profile.studentId ?? '',
                    profile.email,
                  ].join(' ').toLowerCase();
                  return _query.isEmpty || text.contains(_query);
                })
                .toList();
            if (registrations.isEmpty) {
              return Center(
                child: Text(
                  _query.isEmpty
                      ? 'No confirmed students registered for this event.'
                      : 'No student matches your search.',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final registration = registrations[index];
                final profile = profileById[registration.userId];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      profile.fullName.isEmpty
                          ? registration.participantName
                          : profile.fullName,
                    ),
                    subtitle: Text(
                      '${profile.studentId ?? 'Student ID not available'}\n'
                      '${profile.email}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => _mark(context, registration),
                      child: const Text('Mark'),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _searchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.text,
      autocorrect: false,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: 'Search student',
        hintText: 'Name, student ID, or email',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _mark(
    BuildContext context,
    RegistrationModel registration,
  ) async {
    try {
      final result = await AttendanceService().markManual(registration);
      if (!result.alreadyMarked) {
        await SystemSound.play(SystemSoundType.alert);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyMarked
                ? 'Attendance was already marked.'
                : 'Attendance marked for ${registration.participantName}.',
          ),
        ),
      );
    } on AttendanceFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
