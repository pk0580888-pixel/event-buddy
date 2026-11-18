import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/team_invitation_service.dart';

class InvitationCompletionScreen extends StatefulWidget {
  const InvitationCompletionScreen({
    required this.emailLink,
    required this.onCompleted,
    super.key,
  });

  final String emailLink;
  final VoidCallback onCompleted;

  @override
  State<InvitationCompletionScreen> createState() =>
      _InvitationCompletionScreenState();
}

class _InvitationCompletionScreenState
    extends State<InvitationCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF192D53), Color(0xFF3975FF)],
                      ),
                    ),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Complete your team invitation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use the same Gmail address that received this invitation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!),
                    ),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Invited Gmail address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter the invited email address'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _complete,
                      icon: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(
                        _loading ? 'Verifying...' : 'Verify invitation',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    var completed = false;
    try {
      await TeamInvitationService().acceptInvitation(
        email: _email.text,
        emailLink: widget.emailLink,
      );
      // Finish this screen's state transition before AuthGate replaces it
      // with the authenticated dashboard. Updating the parent first can
      // deactivate this form while its loading state is still being changed.
      if (mounted) setState(() => _loading = false);
      completed = true;
      widget.onCompleted();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'invalid-action-code'
              ? 'This invitation link is invalid or has already been used.'
              : error.message ?? 'Could not verify the invitation.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted && !completed) setState(() => _loading = false);
    }
  }
}
