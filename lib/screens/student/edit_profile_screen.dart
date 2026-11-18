import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';

class EditStudentProfileScreen extends StatefulWidget {
  const EditStudentProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<EditStudentProfileScreen> createState() =>
      _EditStudentProfileScreenState();
}

class _EditStudentProfileScreenState extends State<EditStudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _studentId;
  late final TextEditingController _phone;
  final _picker = ImagePicker();
  XFile? _image;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    _email = TextEditingController(text: widget.profile.email);
    _studentId = TextEditingController(text: widget.profile.studentId ?? '');
    _phone = TextEditingController(text: widget.profile.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (_error != null) _ErrorCard(message: _error!),
            Center(child: _avatar()),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Keep your student details up to date',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 26),
            _field(_name, 'Full name', Icons.person_outline),
            _field(
              _email,
              'Email address',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Enter a valid email address',
            ),
            _field(_studentId, 'Student ID', Icons.badge_outlined),
            _field(
              _phone,
              'Phone number',
              Icons.phone_outlined,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _saving ? null : _sendPasswordReset,
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Send password reset link'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final image = _image;
    final photoUrl = widget.profile.photoUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: const Color(0xFFE8DEFF),
          backgroundImage: image != null
              ? FileImage(File(image.path))
              : (photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null),
          child: image == null && (photoUrl == null || photoUrl.isEmpty)
              ? const Icon(
                  Icons.person_rounded,
                  size: 58,
                  color: Color(0xFF57369D),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: 0,
          child: IconButton.filled(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Change profile photo',
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Enter your $label'.toLowerCase()
                : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
    );
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = UserProfileService();
      String? photoUrl;
      if (_image != null) {
        photoUrl = await service.uploadProfileImage(
          filePath: _image!.path,
          uid: widget.profile.uid,
        );
      }
      await service.updateStudentProfile(
        uid: widget.profile.uid,
        fullName: _name.text,
        email: _email.text,
        studentId: _studentId.text,
        phoneNumber: _phone.text,
        photoUrl: photoUrl,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'requires-recent-login'
              ? 'For security, sign out and sign in again before changing your email.'
              : error.message ?? 'Could not update your profile.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email.'),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Could not send reset link.');
      }
    }
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
