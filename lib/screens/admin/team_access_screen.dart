import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/team_invitation.dart';
import '../../models/user_profile.dart';
import '../../services/team_invitation_service.dart';
import '../../services/user_profile_service.dart';

class TeamAccessScreen extends StatefulWidget {
  const TeamAccessScreen({super.key});

  @override
  State<TeamAccessScreen> createState() => _TeamAccessScreenState();
}

class _TeamAccessScreenState extends State<TeamAccessScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _accountFilter = 'All';
  String _invitationFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> _filterProfiles(List<UserProfile> profiles) {
    return profiles.where((profile) {
      final searchText = [
        profile.fullName,
        profile.studentId ?? '',
        profile.email,
      ].join(' ').toLowerCase();
      final matchesSearch = _query.isEmpty || searchText.contains(_query);
      final matchesFilter =
          _accountFilter == 'All' ||
          (_accountFilter == 'Organizers' && profile.isOrganizer) ||
          (_accountFilter == 'Students' && !profile.isOrganizer);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<TeamInvitation> _filterInvitations(List<TeamInvitation> invitations) {
    return invitations.where((invitation) {
      final searchText = '${invitation.fullName} ${invitation.email}'
          .toLowerCase();
      final matchesSearch = _query.isEmpty || searchText.contains(_query);
      final status = invitation.isPending
          ? 'Pending'
          : invitation.status == 'accepted'
          ? 'Accepted'
          : 'Closed';
      final matchesFilter =
          _invitationFilter == 'All' || _invitationFilter == status;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team access'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _searchField(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        icon: const Icon(Icons.mail_outline),
        label: const Text('Invite member'),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: UserProfileService().watchAllProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load team members.'));
          }
          final profiles = snapshot.data ?? const <UserProfile>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _AccessHero(
                memberCount: profiles.where((p) => p.isOrganizer).length,
              ),
              const SizedBox(height: 22),
              const Text(
                'Registered accounts',
                style: TextStyle(
                  color: Color(0xFF192D53),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a registered professor or team member and grant Organizer access. They can then sign in through Admin login.',
                style: TextStyle(color: Colors.grey, height: 1.35),
              ),
              const SizedBox(height: 14),
              _filterChips(
                values: const ['All', 'Students', 'Organizers'],
                selected: _accountFilter,
                onSelected: (value) => setState(() => _accountFilter = value),
              ),
              const SizedBox(height: 12),
              if (_filterProfiles(profiles).isEmpty)
                const _EmptyTeamState()
              else
                ..._filterProfiles(profiles)
                    .map((profile) => _memberTile(context, profile)),
              const SizedBox(height: 22),
              const Text(
                'Invitation history',
                style: TextStyle(
                  color: Color(0xFF192D53),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<TeamInvitation>>(
                stream: TeamInvitationService().watchInvitations(),
                builder: (context, invitationSnapshot) {
                  if (invitationSnapshot.hasError) {
                    return const Text('Could not load invitations.');
                  }
                  final invitations = _filterInvitations(
                    invitationSnapshot.data ?? const <TeamInvitation>[],
                  );
                  final allInvitations =
                      invitationSnapshot.data ?? const <TeamInvitation>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _filterChips(
                        values: const ['All', 'Pending', 'Accepted', 'Closed'],
                        selected: _invitationFilter,
                        onSelected: (value) =>
                            setState(() => _invitationFilter = value),
                      ),
                      const SizedBox(height: 10),
                      if (invitations.isEmpty)
                        Text(
                          allInvitations.isEmpty
                              ? 'No invitations sent yet.'
                              : 'No invitations match your search or filter.',
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        ...invitations
                            .take(10)
                            .map(
                              (invitation) =>
                                  _invitationTile(context, invitation),
                            ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChips({
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: values
          .map(
            (value) => FilterChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
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
        labelText: 'Search students or team members',
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

  Widget _memberTile(BuildContext context, UserProfile profile) {
    final isOrganizer = profile.isOrganizer;
    final color = isOrganizer
        ? const Color(0xFF16A085)
        : const Color(0xFF3975FF);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isOrganizer ? Icons.verified_user_outlined : Icons.person_outline,
            color: color,
          ),
        ),
        title: Text(
          profile.fullName.isEmpty ? 'Unnamed account' : profile.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${profile.email}\n${isOrganizer ? 'Organizer access enabled' : 'Student access'}',
          style: const TextStyle(height: 1.35),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isOrganizer,
              activeThumbColor: const Color(0xFF16A085),
              onChanged: (enabled) => _changeAccess(context, profile, enabled),
            ),
            IconButton(
              tooltip: 'Delete profile record',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteMember(context, profile),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMember(BuildContext context, UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete profile record?'),
        content: Text(
          'This removes ${profile.fullName} from Event Buddy records. Their Firebase sign-in account will not be deleted from this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await UserProfileService().deleteProfile(profile.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile record deleted.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to delete this record.'),
          ),
        );
      }
    }
  }

  Future<void> _changeAccess(
    BuildContext context,
    UserProfile profile,
    bool enabled,
  ) async {
    final action = enabled
        ? 'grant Organizer access to'
        : 'remove Organizer access from';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? 'Grant team access?' : 'Remove team access?'),
        content: Text('Are you sure you want to $action ${profile.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(enabled ? 'Grant access' : 'Remove access'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await UserProfileService().setOrganizerAccess(
        uid: profile.uid,
        enabled: enabled,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Organizer access granted.'
                  : 'Organizer access removed.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only the primary administrator can change team access.',
            ),
          ),
        );
      }
    }
  }

  Widget _invitationTile(BuildContext context, TeamInvitation invitation) {
    final pending = invitation.isPending;
    final accepted = invitation.status == 'accepted';
    final color = accepted
        ? const Color(0xFF16A085)
        : pending
        ? const Color(0xFFE18A13)
        : Colors.grey;
    final status = accepted
        ? 'Accepted'
        : pending
        ? 'Pending • expires ${invitation.expiresAt.day}/${invitation.expiresAt.month}'
        : invitation.status == 'send_failed'
        ? 'Email could not be sent'
        : 'Revoked or expired';
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            accepted ? Icons.check_circle_outline : Icons.mail_outline,
            color: color,
          ),
        ),
        title: Text(
          invitation.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${invitation.email}\n$status'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pending)
              IconButton(
                tooltip: 'Cancel invitation',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => _cancelInvitation(context, invitation),
              ),
            IconButton(
              tooltip: 'Delete invitation',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteInvitation(context, invitation),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteInvitation(
    BuildContext context,
    TeamInvitation invitation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invitation?'),
        content: Text('Remove the invitation for ${invitation.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await TeamInvitationService().deleteInvitation(invitation.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invitation deleted.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only the primary administrator can delete invitations.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    var sending = false;
    String? error;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Invite team member'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'A secure Firebase sign-in link will be sent to this Gmail. The link expires in 7 days.',
                      style: TextStyle(color: Colors.grey, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter their name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Gmail address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          sending = true;
                          error = null;
                        });
                        try {
                          await TeamInvitationService().sendInvitation(
                            fullName: name.text,
                            email: email.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Invitation sent to ${email.text.trim()}.',
                                ),
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (exception) {
                          setDialogState(() {
                            sending = false;
                            error = exception.code == 'operation-not-allowed'
                                ? 'Enable Email link sign-in in Firebase Authentication first.'
                                : exception.message ??
                                      'Could not send invitation.';
                          });
                        } catch (exception) {
                          setDialogState(() {
                            sending = false;
                            error = exception.toString().replaceFirst(
                              'Bad state: ',
                              '',
                            );
                          });
                        }
                      },
                child: sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send invitation'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      email.dispose();
    }
  }

  Future<void> _cancelInvitation(
    BuildContext context,
    TeamInvitation invitation,
  ) async {
    await TeamInvitationService().cancelInvitation(invitation.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invitation cancelled.')));
    }
  }
}

class _AccessHero extends StatelessWidget {
  const _AccessHero({required this.memberCount});
  final int memberCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF192D53), Color(0xFF3975FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white24,
          child: Icon(Icons.group_add_rounded, color: Colors.white, size: 29),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Build your event team',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$memberCount organizer${memberCount == 1 ? '' : 's'} currently authorized',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyTeamState extends StatelessWidget {
  const _EmptyTeamState();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          Icon(Icons.people_outline, size: 48, color: Color(0xFF3975FF)),
          SizedBox(height: 10),
          Text('No registered accounts found.'),
          SizedBox(height: 4),
          Text(
            'Ask your team member to create an account first.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
