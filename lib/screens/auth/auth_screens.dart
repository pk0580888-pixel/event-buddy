import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';

enum LoginRole { student, admin }

const _navy = Color(0xFF192D53);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F1FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    const _WelcomeHero(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openLogin(context, LoginRole.student),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Student login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openLogin(context, LoginRole.admin),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Admin login'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text('Create a student account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLogin(BuildContext context, LoginRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101E54), Color(0xFF263C8B), Color(0xFF512A91)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33101E54),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'CAMPUS EVENTS, REIMAGINED',
                style: TextStyle(
                  color: Color(0xFFBFEAFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 210,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF49D7FF), width: 3),
                    borderRadius: BorderRadius.circular(22),
                    color: Color(0x332E5AA4),
                  ),
                ),
                const Positioned(top: 0, left: 105, child: _CalendarRing()),
                const Positioned(top: 0, right: 105, child: _CalendarRing()),
                const Icon(
                  Icons.groups_rounded,
                  size: 86,
                  color: Color(0xFF42D5F5),
                ),
                Positioned(
                  right: 54,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0B1948),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF42D5F5),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Event ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Buddy',
                  style: TextStyle(color: Color(0xFF42D5F5)),
                ),
              ],
            ),
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'CONNECT  •  CREATE  •  CELEBRATE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFCAD5FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarRing extends StatelessWidget {
  const _CalendarRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x442FDDFF), blurRadius: 8)],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.role, super.key});

  final LoginRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == LoginRole.admin;
    return _AuthPage(
      hero: const _WelcomeHero(),
      title: isAdmin ? 'Admin login' : 'Welcome back',
      subtitle: isAdmin
          ? 'Sign in to manage Event Buddy.'
          : 'Sign in to continue to Event Buddy.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _requiredEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                child: const Text('Forgot password?'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () => _showEmailHelp(context),
                child: const Text('Forgot your email?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const _ButtonProgress()
                    : Text(isAdmin ? 'Sign in as admin' : 'Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signIn(
        email: _email.text,
        password: _password.text,
        expectedRole: widget.role == LoginRole.admin ? 'admin' : 'student',
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Find your registered email'),
        content: const Text(
          'For your security, Firebase does not reveal account emails from a student ID or phone number. Check your email accounts for Event Buddy registration messages, or contact the Event Buddy administrator with your Student ID for identity verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _email,
      _studentId,
      _phone,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPage(
      title: 'Create student account',
      subtitle: 'Register with your campus details.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            _field(_fullName, 'Full name', Icons.person_outline),
            _field(
              _email,
              'Email',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: _requiredEmail,
            ),
            _field(_studentId, 'Student ID', Icons.badge_outlined),
            _field(
              _phone,
              'Phone number',
              Icons.phone_outlined,
              type: TextInputType.phone,
            ),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value != null && value.length >= 6
                  ? null
                  : 'Use at least 6 characters',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) =>
                  value == _password.text ? null : 'Passwords do not match',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const _ButtonProgress()
                    : const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) => Padding(
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().registerStudent(
        fullName: _fullName.text,
        email: _email.text,
        password: _password.text,
        studentId: _studentId.text,
        phoneNumber: _phone.text,
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthPage(
    title: 'Reset password',
    subtitle: 'We will email you a secure password reset link.',
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          if (_message != null) _SuccessBanner(message: _message!),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _requiredEmail,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const _ButtonProgress()
                  : const Text('Send reset link'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await AuthService().sendPasswordResetEmail(_email.text);
      if (mounted) {
        setState(
          () => _message = 'If an account exists, a reset link has been sent.',
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _AuthPage extends StatelessWidget {
  const _AuthPage({required this.child, this.hero, this.title, this.subtitle});
  final Widget child;
  final Widget? hero;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                if (hero != null) ...[hero!, const SizedBox(height: 24)],
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: _navy),
                    textAlign: TextAlign.center,
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 28),
                    child: Text(subtitle!, textAlign: TextAlign.center),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _Banner(
    message: message,
    color: Colors.red.shade50,
    icon: Icons.error_outline,
  );
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _Banner(
    message: message,
    color: Colors.green.shade50,
    icon: Icons.check_circle_outline,
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    required this.icon,
  });
  final String message;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

String? _requiredEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter your email';
  }
  if (!value.contains('@')) return 'Enter a valid email address';
  return null;
}
