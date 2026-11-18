import 'package:material_ui/material_ui.dart';

import '../../models/registration_model.dart';
import '../../models/user_profile.dart';
import '../../services/registration_service.dart';
import '../../services/user_profile_service.dart';

class ParticipantManagementScreen extends StatefulWidget {
  const ParticipantManagementScreen({super.key});

  @override
  State<ParticipantManagementScreen> createState() =>
      _ParticipantManagementScreenState();
}

class _ParticipantManagementScreenState
    extends State<ParticipantManagementScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchQuery = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage participants')),
      body: StreamBuilder<List<UserProfile>>(
        stream: UserProfileService().watchParticipants(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileSnapshot.hasError) {
            return const _MessageState(
              icon: Icons.error_outline,
              message: 'Unable to load participants.',
            );
          }

          return StreamBuilder<List<RegistrationModel>>(
            stream: RegistrationService().watchAllRegistrations(),
            builder: (context, registrationSnapshot) {
              if (registrationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (registrationSnapshot.hasError) {
                return const _MessageState(
                  icon: Icons.error_outline,
                  message: 'Unable to load participant registrations.',
                );
              }

              final profiles = profileSnapshot.data ?? const <UserProfile>[];
              final registrations =
                  registrationSnapshot.data ?? const <RegistrationModel>[];
              final registrationCounts = <String, int>{};
              for (final registration in registrations) {
                registrationCounts.update(
                  registration.userId,
                  (count) => count + 1,
                  ifAbsent: () => 1,
                );
              }

              return ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, search, _) {
                  final participants = profiles
                      .where((profile) => _matchesSearch(profile, search))
                      .toList();
                  if (participants.isEmpty) {
                    return Column(
                      children: [
                        _searchField(search),
                        const Expanded(
                          child: _MessageState(
                            icon: Icons.people_outline,
                            message: 'No participants found.',
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _searchField(search),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: participants.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final participant = participants[index];
                            return _ParticipantCard(
                              participant: participant,
                              registrationCount:
                                  registrationCounts[participant.uid] ?? 0,
                              onTap: () => _showDetails(
                                participant,
                                registrations
                                    .where(
                                      (registration) =>
                                          registration.userId ==
                                          participant.uid,
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesSearch(UserProfile profile, String search) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return profile.fullName.toLowerCase().contains(query) ||
        profile.email.toLowerCase().contains(query) ||
        (profile.studentId ?? '').toLowerCase().contains(query);
  }

  Widget _searchField(String search) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (value) => _searchQuery.value = value,
        onSubmitted: (value) {
          _searchQuery.value = value;
          _searchFocusNode.requestFocus();
        },
        decoration: InputDecoration(
          hintText: 'Search by name, email or student ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery.value = '';
                    _searchFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.clear),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(
    UserProfile participant,
    List<RegistrationModel> registrations,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.fullName.isEmpty
                    ? 'Student participant'
                    : participant.fullName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(participant.email),
              if ((participant.studentId ?? '').isNotEmpty)
                Text('Student ID: ${participant.studentId}'),
              if ((participant.phoneNumber ?? '').isNotEmpty)
                Text('Phone: ${participant.phoneNumber}'),
              const SizedBox(height: 18),
              Text(
                'Registered events (${registrations.length})',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (registrations.isEmpty)
                const Text('No event registrations yet.')
              else
                ...registrations.map(
                  (registration) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(registration.eventTitle),
                    subtitle: Text(registration.status),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.registrationCount,
    required this.onTap,
  });

  final UserProfile participant;
  final int registrationCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = participant.fullName.isEmpty
        ? 'Student participant'
        : participant.fullName;
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          child: Text(displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${participant.studentId?.isNotEmpty == true ? '${participant.studentId} • ' : ''}${participant.email}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$registrationCount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('events', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
