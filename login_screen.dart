import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'main.dart';
import 'home_page.dart';
import 'logup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  Timer? _emailErrorTimer;
  Timer? _passwordErrorTimer;

  late AnimationController emailShakeController;
  late AnimationController passwordShakeController;

  double emailErrorOpacity = 0.0;
  double passwordErrorOpacity = 0.0;

  bool isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Regex to check for a valid email format
  final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  // Regex to check for a valid phone number format (basic 10-15 digit number)
  final RegExp phoneRegex = RegExp(r'^[0-9]{10,15}$');

  @override
  void initState() {
    super.initState();
    emailShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    passwordShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _emailErrorTimer?.cancel();
    _passwordErrorTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    emailShakeController.dispose();
    passwordShakeController.dispose();
    super.dispose();
  }

  void validateEmailLive(String value) {
    if (value.isEmpty) {
      setState(() {
        emailError = null;
        emailErrorOpacity = 0.0;
      });
      return;
    }
    if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value)) {
      setState(() {
        emailError = "Invalid Email/Phone format";
        emailErrorOpacity = 1.0;
      });
    } else {
      setState(() {
        emailError = null;
        emailErrorOpacity = 0.0;
      });
    }
  }

  void validatePasswordLive(String value) {
    setState(() {
      passwordError = null;
      passwordErrorOpacity = 0.0;
    });
  }

  void _startEmailErrorTimer() {
    _emailErrorTimer?.cancel();
    _emailErrorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          emailErrorOpacity = 0.0;
        });
      }
    });
  }

  void _startPasswordErrorTimer() {
    _passwordErrorTimer?.cancel();
    _passwordErrorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          passwordErrorOpacity = 0.0;
        });
      }
    });
  }

  void validateAndLogin() async {
    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();
    bool hasError = false;

    if (identifier.isEmpty) {
      setState(() {
        emailError = "Email/Phone cannot be empty";
        emailErrorOpacity = 1.0;
      });
      emailShakeController.forward(from: 0);
      _startEmailErrorTimer();
      hasError = true;
    } else if (!emailRegex.hasMatch(identifier) && !phoneRegex.hasMatch(identifier)) {
      setState(() {
        emailError = "Invalid Email/Phone format";
        emailErrorOpacity = 1.0;
      });
      emailShakeController.forward(from: 0);
      _startEmailErrorTimer();
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        passwordError = "Password cannot be empty";
        passwordErrorOpacity = 1.0;
      });
      passwordShakeController.forward(from: 0);
      _startPasswordErrorTimer();
      hasError = true;
    }

    if (!hasError) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://192.168.239.136/eduledger_backend/login.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'identifier': identifier, 'password': password}),
        );

        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          if (_rememberMe) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userIdentifier', identifier);
          }

          if (mounted) {
            setState(() => isLoading = false);
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const HomePage()));
          }
        } else {
          if (mounted) {
            setState(() {
              isLoading = false;
              passwordError = "Invalid credentials";
              passwordErrorOpacity = 1.0;
            });
            passwordShakeController.forward(from: 0);
            _startPasswordErrorTimer();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            passwordError = "Unable to connect, try again later";
            passwordErrorOpacity = 1.0;
          });
          passwordShakeController.forward(from: 0);
          _startPasswordErrorTimer();
        }
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final scale = media.textScaleFactor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final padding = EdgeInsets.symmetric(horizontal: width * 0.08);
          final spacing = height * 0.02;

          return Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? null
                  : const LinearGradient(
                colors: [Color(0xFFB3E5FC), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              color: isDark ? const Color(0xFF1e1f22) : null,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: padding,
                    child: Transform.translate(
                      offset: const Offset(0, 40),
                      child: ConstrainedBox(
                        constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: spacing * 2),
                              Image.asset('assets/logo.png', width: width * 0.4),
                              SizedBox(height: spacing * 2),
                              _buildEmailField(context),
                              SizedBox(height: spacing),
                              _buildPasswordField(context),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.padded,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              _buildSignInButton(width),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) =>
                                        setState(() => _rememberMe = value ?? false),
                                  ),
                                  const Text("Remember Me")
                                ],
                              ),
                              _buildSignUpButton(width, context),
                              SizedBox(height: spacing),
                              const Text("or Sign in with"),
                              SizedBox(height: spacing),
                              Wrap(
                                spacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final path in [
                                    'assets/google.png',
                                    'assets/facebook.png',
                                    'assets/twitter.png',
                                    'assets/linkedin.png'
                                  ])
                                    SocialIconButton(
                                        imagePath: path, onPressed: () {}),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(height: spacing * 2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => themeNotifier.toggleTheme(),
                      child: Image.asset(
                        isDark ? 'assets/sun.png' : 'assets/moon.png',
                        width: 25,
                        height: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: emailShakeController,
          builder: (context, child) {
            final offset = math.sin(emailShakeController.value * math.pi * 4) * 8;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: TextField(
            controller: emailController,
            onChanged: validateEmailLive,
            decoration: InputDecoration(
              hintText: "Email ID / Phonenumber",
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            keyboardType: TextInputType.text,
          ),
        ),
        AnimatedOpacity(
          opacity: emailErrorOpacity,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(emailError ?? '',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: passwordShakeController,
          builder: (context, child) {
            final offset =
                math.sin(passwordShakeController.value * math.pi * 4) * 8;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: TextField(
            controller: passwordController,
            onChanged: validatePasswordLive,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "Password",
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: passwordErrorOpacity,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(passwordError ?? '',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(double width) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : validateAndLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : const Text("Sign In",
            style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSignUpButton(double width, BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("Sign Up",
            style: TextStyle(
                fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class SocialIconButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;

  const SocialIconButton(
      {super.key, required this.imagePath, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[700] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.zero,
          side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            isDark
                ? const Color.fromRGBO(255, 255, 255, 0.2)
                : const Color.fromRGBO(0, 0, 0, 0.2),
          ),
          splashFactory: InkRipple.splashFactory,
        ),
        child:
        Image.asset(imagePath, height: 24, width: 24, fit: BoxFit.contain),
      ),
    );
  }
}