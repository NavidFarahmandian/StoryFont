// auth_page.dart
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:storyfont/viewmodels/auth_viewmodel.dart';
import '../main.dart';

// AuthPage is a StatefulWidget that handles user authentication (login/signup)
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

// State class for AuthPage, managing animations, form inputs, and validation
class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  // Controllers for email and password text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // Focus nodes to track field focus
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  // Animation controllers for fade, slide, and shake effects
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  // State variables for login/signup mode and password focus
  bool isLogin = true;
  bool isPasswordFocused = false;
  // State variables for password validation criteria
  bool hasMinLength = false;
  bool hasNumber = false;

  @override
  void initState() {
    super.initState();
    // Initialize fade and slide animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Define opacity animation for fade-in effect
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Define slide animation for form entrance
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Initialize shake animation controller for error feedback
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Define shake animation sequence for error indication
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);

    // Reset shake animation when completed
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    // Monitor password field focus changes
    passwordFocusNode.addListener(() {
      setState(() {
        isPasswordFocused = passwordFocusNode.hasFocus;
      });
    });

    // Listen to password input changes for real-time validation
    passwordController.addListener(_validatePassword);

    // Start the fade and slide animations
    _controller.forward();
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Validates email format using a regular expression
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validates password and updates state for UI feedback
  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      hasMinLength = password.length >= 8;
      hasNumber = password.contains(RegExp(r'\d'));
    });
  }

  // Determines which Lottie animation to display based on auth state
  String _getLottieAnimation(AuthViewModel authVM) {
    if (authVM.isSuccess) {
      return 'assets/anims/success_password.json';
    } else if (authVM.error != null) {
      return 'assets/anims/error_password.json';
    } else if (isPasswordFocused) {
      return 'assets/anims/hidden_password.json';
    }
    return 'assets/anims/idle_password.json';
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthViewModel using Provider
    final authVM = Provider.of<AuthViewModel>(context);
    // Determine if submit button should be shown
    final isFormValid = _isValidEmail(emailController.text.trim()) &&
        (isLogin || (hasMinLength && hasNumber));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "StoryFont",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: AnimatedScale(
              scale: themeNotifier.value == ThemeMode.dark ? 1.0 : 1.1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                themeNotifier.value == ThemeMode.dark ? EvaIcons.sun : EvaIcons.moon,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Selector<AuthViewModel, String?>(
                selector: (_, authVM) => authVM.error,
                builder: (context, error, child) {
                  // Trigger shake animation on error
                  if (error != null && !_shakeController.isAnimating) {
                    _shakeController.forward(from: 0);
                  }
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Animated Lottie asset for visual feedback
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.background,
                            BlendMode.modulate,
                          ),
                          child: Lottie.asset(
                            _getLottieAnimation(authVM),
                            key: ValueKey(_getLottieAnimation(authVM)),
                            height: 220,
                            animate: true,
                            frameRate: FrameRate(60),
                            repeat: true,
                            filterQuality: FilterQuality.high,
                            renderCache: RenderCache.drawingCommands,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title text for login or signup
                      Text(
                        isLogin ? 'Welcome Back' : 'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      Text(
                        isLogin ? 'Sign in to continue' : 'Join us today',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Email input field with validation
                      Focus(
                        child: TextFormField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              EvaIcons.emailOutline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            errorText: emailController.text.isNotEmpty && !_isValidEmail(emailController.text)
                                ? 'Invalid email format'
                                : null,
                            errorStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}), // Trigger UI update on input change
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password input field
                      Focus(
                        child: TextFormField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          obscureText: true,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: Icon(
                              EvaIcons.lockOutline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password validation UI with tick indicators, shown only during signup
                      if (!isLogin)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasMinLength ? EvaIcons.checkmarkCircle2 : EvaIcons.checkmarkCircle2Outline,
                                  color: hasMinLength
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'At least 8 characters',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: hasMinLength
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  hasNumber ? EvaIcons.checkmarkCircle2 : EvaIcons.checkmarkCircle2Outline,
                                  color: hasNumber
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Contains a number',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: hasNumber
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      // Display error message if present
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: authVM.error != null
                            ? Text(
                          authVM.error!,
                          key: ValueKey(authVM.error),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                            : const SizedBox.shrink(key: ValueKey('no_error')),
                      ),
                      const SizedBox(height: 24),
                      // Submit button, shown only if form is valid
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: isFormValid && !authVM.isLoading
                            ? ElevatedButton(
                          onPressed: () {
                            final email = emailController.text.trim();
                            final pass = passwordController.text.trim();
                            isLogin ? authVM.signIn(email, pass) : authVM.signUp(email, pass);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLogin
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            isLogin ? 'Sign In' : 'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                            : authVM.isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          key: ValueKey('loading'),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const SizedBox.shrink(key: ValueKey('hidden_button')),
                      ),
                      const SizedBox(height: 8),
                      // Toggle between login and signup
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(
                          isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}