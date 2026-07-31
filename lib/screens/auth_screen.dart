import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';

/// Mandatory authentication screen.
/// No guest mode. No skip button.
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignIn = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;

    if (_isSignIn) {
      error = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      error = await _authService.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    } else {
      widget.onAuthenticated();
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signInWithGoogle();

    if (!mounted) return;

    if (error == null) {
      widget.onAuthenticated();
    } else if (error == 'cancelled') {
      setState(() => _isGoogleLoading = false);
    } else if (error == 'google_unavailable') {
      setState(() {
        _isGoogleLoading = false;
        _errorMessage =
            'Google sign-in is coming soon. Please use email for now.';
      });
    } else {
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = error;
      });
    }
  }

  void _switchMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _errorMessage = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final c = AppColors(isDark: state.isDark);

    return Directionality(
      textDirection: state.textDirection,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                // More breathing room at the top
                const SizedBox(height: AppSpacing.xl),

                // ── App icon ──────────────────────────
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: c.goldLine,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            c.brand.withOpacity(0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              c.brand,
                              c.brandHover
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 34,
                          color: c.gold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tight spacing — icon + app name are
                // one visual unit.
                const SizedBox(height: AppSpacing.md),

                Text(
                  'مكتبة الروضة',
                  textDirection: TextDirection.rtl,
                  style: AppText.arabic(
                    color: c.goldText,
                    size: 22,
                    weight: FontWeight.w700,
                  ),
                ),

                // Tighter — subtitle belongs to the
                // name, not a separate section.
                const SizedBox(height: AppSpacing.xs),

                Text(
                  _isSignIn
                      ? 'Sign In to Continue'
                      : 'Create Your Account',
                  style: AppText.latin(
                      color: c.textMuted, size: 13),
                ),

                // Larger gap — next unit is the mode
                // toggle, which is a separate concern.
                const SizedBox(height: AppSpacing.xl),

                // ── Welcome message in Arabic script ──
                // Specific to an Islamic library.
                // Appears above the form, not the logo,
                // so it feels like a greeting rather
                // than branding.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.base,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: c.goldText,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        'أهلاً بك في مكتبة الروضة',
                        textDirection:
                            TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.textSecondary,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                          height: AppSpacing.xs),
                      Text(
                        'مكان للتعلم والنور',
                        textDirection:
                            TextDirection.rtl,
                        style: AppText.arabic(
                          color: c.textFaint,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Mode toggle ───────────────────────
                _ModeToggle(
                  isSignIn: _isSignIn,
                  onToggle: _switchMode,
                  colors: c,
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Google button ─────────────────────
                _GoogleButton(
                  isLoading: _isGoogleLoading,
                  onTap: _signInWithGoogle,
                  colors: c,
                ),

                const SizedBox(height: AppSpacing.base),

                // ── Arabic "أو" divider ───────────────
                _OrDivider(colors: c),

                const SizedBox(height: AppSpacing.base),

                // ── Form ─────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isSignIn) ...[
                        _FormField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Your name',
                          icon: Icons
                              .person_outline_rounded,
                          colors: c,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        // Tight — fields belong together
                        const SizedBox(
                            height: AppSpacing.md),
                      ],

                      _FormField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'your@email.com',
                        icon: Icons.email_outlined,
                        colors: c,
                        keyboardType:
                            TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!v.contains('@') ||
                              !v.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(
                          height: AppSpacing.md),

                      _FormField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        colors: c,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                            color: c.textFaint,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!_isSignIn &&
                              v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.dangerBg,
                      borderRadius:
                          AppRadius.listItemRadius,
                      border: Border.all(
                        color:
                            c.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: c.danger,
                          size: 16,
                        ),
                        const SizedBox(
                            width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppText.latin(
                              color: c.danger,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Larger gap before the CTA button —
                // it is the primary action, deserves
                // its own breathing room.
                const SizedBox(height: AppSpacing.lg),

                _SubmitButton(
                  isSignIn: _isSignIn,
                  isLoading: _isLoading,
                  onTap: _submitForm,
                  colors: c,
                ),

                const SizedBox(height: AppSpacing.base),

                GestureDetector(
                  onTap: _switchMode,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _isSignIn
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: AppText.latin(
                            color: c.textMuted,
                            size: 13,
                          ),
                        ),
                        TextSpan(
                          text: _isSignIn
                              ? 'Create one'
                              : 'Sign in',
                          style: AppText.latin(
                            color: c.brand,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final bool isSignIn;
  final VoidCallback onToggle;
  final AppColors colors;

  const _ModeToggle({
    required this.isSignIn,
    required this.onToggle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadius.listItemRadius,
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Sign In',
            active: isSignIn,
            onTap: () {
              if (!isSignIn) onToggle();
            },
            colors: c,
          ),
          _Tab(
            label: 'Create Account',
            active: !isSignIn,
            onTap: () {
              if (isSignIn) onToggle();
            },
            colors: c,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors colors;

  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? c.card : Colors.transparent,
            borderRadius: BorderRadius.circular(
                AppRadius.listItem - 2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.latin(
              color: active ? c.brand : c.textMuted,
              size: 13,
              weight: active
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final AppColors colors;

  const _GoogleButton({
    required this.isLoading,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: AppRadius.buttonRadius,
          // Gold left-border accent instead of full
          // gold border — more deliberate, less generic.
          border: Border(
            left: BorderSide(
              color: c.goldText,
              width: 3,
            ),
            top: BorderSide(color: c.divider),
            right: BorderSide(color: c.divider),
            bottom: BorderSide(color: c.divider),
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.brand,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(
                      width: AppSpacing.sm + 2),
                  Text(
                    'Continue with Google',
                    style: AppText.latin(
                      color: c.textPrimary,
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Arabic "أو" divider between two gold lines.
/// Replaces the generic "or use email" text.
class _OrDivider extends StatelessWidget {
  final AppColors colors;
  const _OrDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: c.goldText.withOpacity(0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md),
          child: Text(
            'أو',
            textDirection: TextDirection.rtl,
            style: AppText.arabic(
              color: c.goldText,
              size: 13,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: c.goldText.withOpacity(0.25),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final AppColors colors;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.colors,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.label(color: c.textMuted),
        ),
        // Tight — label belongs to its field
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textDirection: textDirection,
          textAlign: textAlign,
          validator: validator,
          style: AppText.latin(
              color: c.textPrimary, size: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.latin(
                color: c.textFaint, size: 15),
            prefixIcon:
                Icon(icon, color: c.textMuted, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide:
                  BorderSide(color: c.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide:
                  BorderSide(color: c.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                  color: c.brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide:
                  BorderSide(color: c.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                  color: c.danger, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSignIn;
  final bool isLoading;
  final VoidCallback onTap;
  final AppColors colors;

  const _SubmitButton({
    required this.isSignIn,
    required this.isLoading,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brand, c.brandHover],
          ),
          // Rounded rectangle — not a pill.
          // More deliberate, less stock-template.
          borderRadius: AppRadius.buttonRadius,
          boxShadow: [
            BoxShadow(
              color: c.brand.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : Center(
                child: Text(
                  isSignIn
                      ? 'Sign In'
                      : 'Create Account',
                  style: AppText.latin(
                    color: Colors.white,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
