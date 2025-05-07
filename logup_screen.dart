import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:country_code_picker/country_code_picker.dart';
import 'login_screen.dart'; // Assuming you have this file
import 'main.dart'; // Assuming you have ThemeNotifier here
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- SignUpScreen StatefulWidget ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

// --- _SignUpScreenState ---
class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  // --- State variables, controllers, timers, etc. ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // Controller for the new Email Verification Code field
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phoneCodeController = TextEditingController(); // Renamed from _codeController
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Error text state
  String? _fullNameError;
  String? _emailError;
  String? _emailCodeError; // Error for Email Verification Code
  String? _phoneError;
  String? _phoneCodeError; // Error for Phone Verification Code
  String? _passwordError;
  String? _confirmPasswordError;

  // Timer notifiers for error messages
  final ValueNotifier<Timer?> _fullNameErrorTimerNotifier = ValueNotifier(null);
  final ValueNotifier<Timer?> _emailErrorTimerNotifier = ValueNotifier(null);
  final ValueNotifier<Timer?> _emailCodeErrorTimerNotifier = ValueNotifier(null); // Timer for Email Code Error
  final ValueNotifier<Timer?> _phoneErrorTimerNotifier = ValueNotifier(null);
  final ValueNotifier<Timer?> _phoneCodeErrorTimerNotifier = ValueNotifier(null); // Timer for Phone Code Error
  final ValueNotifier<Timer?> _passwordErrorTimerNotifier = ValueNotifier(null);
  final ValueNotifier<Timer?> _confirmPasswordErrorTimerNotifier = ValueNotifier(null);

  // Animation controllers for shake effect
  late AnimationController _fullNameShakeController;
  late AnimationController _emailShakeController;
  late AnimationController _emailCodeShakeController; // Shake controller for Email Code
  late AnimationController _phoneShakeController;
  late AnimationController _phoneCodeShakeController; // Shake controller for Phone Code
  late AnimationController _passwordShakeController;
  late AnimationController _confirmPasswordShakeController;

  // Opacity state for error messages
  double _fullNameErrorOpacity = 0.0;
  double _emailErrorOpacity = 0.0;
  double _emailCodeErrorOpacity = 0.0; // Opacity for Email Code Error
  double _phoneErrorOpacity = 0.0;
  double _phoneCodeErrorOpacity = 0.0; // Opacity for Phone Code Error
  double _passwordErrorOpacity = 0.0;
  double _confirmPasswordErrorOpacity = 0.0;

  String _selectedCountryCode = '+91'; // Default country code

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _fullNameShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _emailShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _emailCodeShakeController = AnimationController( // Initialize Email Code Shake
        vsync: this, duration: const Duration(milliseconds: 500));
    _phoneShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _phoneCodeShakeController = AnimationController( // Initialize Phone Code Shake
        vsync: this, duration: const Duration(milliseconds: 500));
    _passwordShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _confirmPasswordShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose(); // Dispose Email Code Controller
    _phoneController.dispose();
    _phoneCodeController.dispose(); // Dispose Phone Code Controller
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Cancel and dispose timers via ValueNotifiers
    _fullNameErrorTimerNotifier.value?.cancel();
    _emailErrorTimerNotifier.value?.cancel();
    _emailCodeErrorTimerNotifier.value?.cancel(); // Dispose Email Code Timer
    _phoneErrorTimerNotifier.value?.cancel();
    _phoneCodeErrorTimerNotifier.value?.cancel(); // Dispose Phone Code Timer
    _passwordErrorTimerNotifier.value?.cancel();
    _confirmPasswordErrorTimerNotifier.value?.cancel();

    _fullNameErrorTimerNotifier.dispose();
    _emailErrorTimerNotifier.dispose();
    _emailCodeErrorTimerNotifier.dispose(); // Dispose Email Code Timer Notifier
    _phoneErrorTimerNotifier.dispose();
    _phoneCodeErrorTimerNotifier.dispose(); // Dispose Phone Code Timer Notifier
    _passwordErrorTimerNotifier.dispose();
    _confirmPasswordErrorTimerNotifier.dispose();

    // Dispose animation controllers
    _fullNameShakeController.dispose();
    _emailShakeController.dispose();
    _emailCodeShakeController.dispose(); // Dispose Email Code Shake Controller
    _phoneShakeController.dispose();
    _phoneCodeShakeController.dispose(); // Dispose Phone Code Shake Controller
    _passwordShakeController.dispose();
    _confirmPasswordShakeController.dispose();

    super.dispose();
  }

  // --- Visibility toggles ---
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // --- Error Timer ---
  void _startErrorTimer(VoidCallback setStateCallback, ValueNotifier<Timer?> timerNotifier) {
    timerNotifier.value?.cancel(); // Cancel any existing timer
    timerNotifier.value = Timer(const Duration(seconds: 3), () {
      if (mounted) { // Check if the widget is still in the tree
        setState(setStateCallback); // Hide the error message after delay
      }
    });
  }

  // --- Live Validation Functions ---
  void _validateFullNameLive(String value) {
    setState(() {
      _fullNameError = value.trim().isEmpty ? 'Please enter your full name' : null;
      _fullNameErrorOpacity = _fullNameError != null ? 1.0 : 0.0;
    });
  }

  void _validateEmailLive(String value) {
    final email = value.trim();
    // Basic email pattern check
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _emailError = email.isEmpty
          ? 'Please enter your email'
          : !regex.hasMatch(email)
          ? 'Please enter a valid email address'
          : null;
      _emailErrorOpacity = _emailError != null ? 1.0 : 0.0;
    });
  }

  // Validation for the Email Verification Code
  void _validateEmailCodeLive(String value) {
    final code = value.trim();
    setState(() {
      if (code.isEmpty) {
        _emailCodeError = 'Please enter the email code';
      } else if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) { // Assuming a 6-digit code
        _emailCodeError = 'Code must be 6 digits';
      } else {
        _emailCodeError = null;
      }
      _emailCodeErrorOpacity = _emailCodeError != null ? 1.0 : 0.0;
    });
  }

  void _validatePhoneLive(String value) {
    final phone = value.trim();
    setState(() {
      if (phone.isEmpty) {
        _phoneError = 'Please enter your phone number';
      } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        _phoneError = 'Please enter a valid phone number (digits only)';
      } else if (phone.length < 7 || phone.length > 15) { // Basic length check
        _phoneError = 'Phone number seems invalid';
      } else {
        _phoneError = null;
      }
      _phoneErrorOpacity = _phoneError != null ? 1.0 : 0.0;
    });
  }

  // Validation for the Phone Verification Code
  void _validatePhoneCodeLive(String value) {
    final code = value.trim();
    setState(() {
      if (code.isEmpty) {
        _phoneCodeError = 'Please enter the phone code';
      } else if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) { // Assuming a 6-digit code
        _phoneCodeError = 'Code must be 6 digits';
      } else {
        _phoneCodeError = null;
      }
      _phoneCodeErrorOpacity = _phoneCodeError != null ? 1.0 : 0.0;
    });
  }

  void _validatePasswordLive(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Please enter your password';
      } else if (value.length < 8) {
        _passwordError = 'Password must be at least 8 characters long';
      } else if (!value.contains(RegExp(r'[A-Z]'))) {
        _passwordError = 'Password must contain an uppercase letter';
      } else if (!value.contains(RegExp(r'[a-z]'))) {
        _passwordError = 'Password must contain a lowercase letter';
      } else if (!value.contains(RegExp(r'[0-9]'))) {
        _passwordError = 'Password must contain at least one number';
      } else if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        _passwordError = 'Password must contain at least one special character';
      } else {
        _passwordError = null;
      }
      _passwordErrorOpacity = _passwordError != null ? 1.0 : 0.0;
    });
  }

  void _validateConfirmPasswordLive(String value) {
    setState(() {
      _confirmPasswordError = value.isEmpty
          ? 'Please confirm your password'
          : value != _passwordController.text
          ? 'Passwords do not match'
          : null;
      _confirmPasswordErrorOpacity = _confirmPasswordError != null ? 1.0 : 0.0;
    });
  }

  // --- "Get Code" Handlers ---

  void _handleGetEmailCode() {
    // 1. Validate the email field first
    _validateEmailLive(_emailController.text);
    final currentEmailError = _emailError; // Capture error state *after* validation

    if (_emailController.text.isNotEmpty && currentEmailError == null) {
      // 2. If email is valid, proceed (e.g., call API)
      print("Requesting code for email: ${_emailController.text}");
      // --- TODO: Implement your API call to send email code ---
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending email code... (Placeholder)'), backgroundColor: Colors.blue),
      );
    } else {
      // 3. If email is invalid, show error and shake
      if (currentEmailError != null) {
        setState(() => _emailErrorOpacity = 1.0);
        _emailShakeController.forward(from: 0);
        _startErrorTimer(() => setState(() => _emailErrorOpacity = 0.0), _emailErrorTimerNotifier);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentEmailError ?? 'Please enter a valid email first'), backgroundColor: Colors.orange),
      );
    }
  }

  void _handleGetPhoneCode() {
    // 1. Validate the phone field first
    _validatePhoneLive(_phoneController.text);
    final currentPhoneError = _phoneError; // Capture error state *after* validation

    if (_phoneController.text.isNotEmpty && currentPhoneError == null) {
      // 2. If phone is valid, proceed (e.g., call API)
      print("Requesting code for phone: $_selectedCountryCode${_phoneController.text}");
      // --- TODO: Implement your API call to send phone code ---
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending phone code... (Placeholder)'), backgroundColor: Colors.blue),
      );
    } else {
      // 3. If phone is invalid, show error and shake
      if (currentPhoneError != null) {
        setState(() => _phoneErrorOpacity = 1.0);
        _phoneShakeController.forward(from: 0);
        _startErrorTimer(() => setState(() => _phoneErrorOpacity = 0.0), _phoneErrorTimerNotifier);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentPhoneError ?? 'Please enter a valid phone number first'), backgroundColor: Colors.orange),
      );
    }
  }


  // --- Sign Up Logic ---
  Future<void> _signUp() async {
    // Hide all previous errors first
    setState(() {
      _fullNameErrorOpacity = 0.0;
      _emailErrorOpacity = 0.0;
      _emailCodeErrorOpacity = 0.0;
      _phoneErrorOpacity = 0.0;
      _phoneCodeErrorOpacity = 0.0;
      _passwordErrorOpacity = 0.0;
      _confirmPasswordErrorOpacity = 0.0;
    });

    // Clear error messages
    _fullNameError = null;
    _emailError = null;
    _emailCodeError = null;
    _phoneError = null;
    _phoneCodeError = null;
    _passwordError = null;
    _confirmPasswordError = null;

    // Run validations
    _validateFullNameLive(_fullNameController.text);
    _validateEmailLive(_emailController.text);
    _validateEmailCodeLive(_emailCodeController.text);
    _validatePhoneLive(_phoneController.text);
    _validatePhoneCodeLive(_phoneCodeController.text);
    _validatePasswordLive(_passwordController.text);
    _validateConfirmPasswordLive(_confirmPasswordController.text);

    bool hasError = false;

    if (_fullNameError != null) {
      setState(() => _fullNameErrorOpacity = 1.0);
      _fullNameShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _fullNameErrorOpacity = 0.0), _fullNameErrorTimerNotifier);
      hasError = true;
    }
    if (_emailError != null) {
      setState(() => _emailErrorOpacity = 1.0);
      _emailShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _emailErrorOpacity = 0.0), _emailErrorTimerNotifier);
      hasError = true;
    }
    if (_emailCodeError != null) {
      setState(() => _emailCodeErrorOpacity = 1.0);
      _emailCodeShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _emailCodeErrorOpacity = 0.0), _emailCodeErrorTimerNotifier);
      hasError = true;
    }
    if (_phoneError != null) {
      setState(() => _phoneErrorOpacity = 1.0);
      _phoneShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _phoneErrorOpacity = 0.0), _phoneErrorTimerNotifier);
      hasError = true;
    }
    if (_phoneCodeError != null) {
      setState(() => _phoneCodeErrorOpacity = 1.0);
      _phoneCodeShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _phoneCodeErrorOpacity = 0.0), _phoneCodeErrorTimerNotifier);
      hasError = true;
    }
    if (_passwordError != null) {
      setState(() => _passwordErrorOpacity = 1.0);
      _passwordShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _passwordErrorOpacity = 0.0), _passwordErrorTimerNotifier);
      hasError = true;
    }
    if (_confirmPasswordError != null) {
      setState(() => _confirmPasswordErrorOpacity = 1.0);
      _confirmPasswordShakeController.forward(from: 0);
      _startErrorTimer(() => setState(() => _confirmPasswordErrorOpacity = 0.0), _confirmPasswordErrorTimerNotifier);
      hasError = true;
    }

    if (!hasError && (_formKey.currentState?.validate() ?? false)) {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim(); // Phone number without country code
      final password = _passwordController.text;
      final countryCode = _selectedCountryCode; // Country code

      const url = 'http://192.168.239.136/eduledger_backend/logup.php';

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': fullName,
            'email': email,
            'phone': phone,
            'country_Code': countryCode,
            'password': password,
          }),
        );

        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Sign up successful'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Sign up failed'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      print("Validation failed. Errors present or form invalid.");
    }
  }


  // --- Helper Widget Builders ---

  // Builds a standard text field with shake animation and error display
  Widget _buildTextFieldWithShake(
      TextEditingController controller,
      String hintText,
      String? errorText,
      double errorOpacity,
      AnimationController shakeController,
      Function(String) onChanged,
      double baseFontSize,
      {bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        Widget? suffixIcon, // Changed from IconButton to Widget?
        bool isDense = false // Added for potentially smaller padding
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Adjust padding based on isDense flag
    final double verticalPadding = baseFontSize * (isDense ? 0.8 : 1.0);
    final double horizontalPadding = baseFontSize * (isDense ? 1.0 : 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
      children: [
        AnimatedBuilder(
          animation: shakeController,
          builder: (context, child) {
            // Apply shake animation
            final offset = math.sin(shakeController.value * math.pi * 4) * 8;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: baseFontSize),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: baseFontSize * 0.95),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
              // Use consistent rounded border
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none, // No border line
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              // Ensure error borders are also removed visually if desired
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              // Set content padding
              contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              // Add the suffix icon if provided
              suffixIcon: suffixIcon,
              // Remove default error text space to rely on our AnimatedOpacity widget
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0), // Hide default error style
              isDense: isDense, // Apply density
            ),
          ),
        ),
        // Animated error message display below the field
        AnimatedOpacity(
          opacity: errorOpacity,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            // Adjust padding for the error message
            padding: EdgeInsets.only(left: baseFontSize * 0.75, top: baseFontSize * 0.25, bottom: baseFontSize * 0.25),
            child: Text(
              errorText ?? '', // Display error text or empty string
              style: TextStyle(color: Colors.red, fontSize: baseFontSize * 0.75),
            ),
          ),
        ),
      ],
    );
  }


  // Builds the phone input field with country code picker and Get Code button
  Widget _buildPhoneFieldWithShake(
      TextEditingController controller,
      String hintText,
      String? errorText,
      double errorOpacity,
      AnimationController shakeController,
      Function(String) onChanged,
      double baseFontSize,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];
    // Consistent padding calculations
    final double verticalPadding = baseFontSize * 1.0;
    final double horizontalPadding = baseFontSize * 0.5; // Base horizontal padding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: shakeController,
          builder: (context, child) {
            final offset = math.sin(shakeController.value * math.pi * 4) * 8;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: InputDecorator( // Using InputDecorator to wrap Row for consistent styling
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              contentPadding: EdgeInsets.zero, // Padding handled internally by Row elements
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              errorText: null, // Handled by AnimatedOpacity below
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            child: Row(
              children: [
                // Country Code Picker
                CountryCodePicker(
                  onChanged: (CountryCode countryCode) {
                    setState(() {
                      _selectedCountryCode = countryCode.dialCode ?? '+1'; // Update selected code
                    });
                    print("Selected country code: $_selectedCountryCode");
                  },
                  initialSelection: 'IN', // Default selection
                  favorite: const ['+91', '+1', '+44'], // Favorite codes
                  // Theme-aware background colors
                  backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                  dialogBackgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  // Text styles
                  textStyle: TextStyle(color: textColor, fontSize: baseFontSize * 0.95),
                  dialogTextStyle: TextStyle(color: textColor),
                  // Search field styling
                  searchDecoration: InputDecoration(
                    hintText: "Search country",
                    hintStyle: TextStyle(color: hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDark? Colors.grey[800] : Colors.white,
                  ),
                  flagWidth: baseFontSize * 1.5, // Responsive flag width
                  // Padding for the picker itself
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                ),
                // Vertical divider
                Container(
                  height: baseFontSize * 1.5, // Match flag height roughly
                  width: 1,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  margin: EdgeInsets.symmetric(horizontal: baseFontSize * 0.25), // Small margin
                ),
                // Phone number input field
                Expanded(
                  child: Padding(
                    // Minimal padding as InputDecorator handles outer bounds
                    padding: EdgeInsets.only(left: 0, right: horizontalPadding),
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor, fontSize: baseFontSize),
                      decoration: InputDecoration(
                        hintText: hintText,
                        // No borders needed here as InputDecorator handles it
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        // Content padding for the text field itself
                        contentPadding: EdgeInsets.symmetric(vertical: verticalPadding),
                        hintStyle: TextStyle(color: hintColor, fontSize: baseFontSize * 0.95),
                      ),
                    ),
                  ),
                ),
                // "Get Code" Button
                Padding(
                  padding: EdgeInsets.only(right: horizontalPadding * 1.5), // Padding on the right
                  child: TextButton(
                    onPressed: _handleGetPhoneCode, // Use the dedicated handler
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue, // Text color
                      // Responsive padding
                      padding: EdgeInsets.symmetric(horizontal: baseFontSize * 0.6, vertical: baseFontSize * 0.5),
                      minimumSize: Size.zero, // Allow button to shrink
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                    ),
                    child: Text("Get Code", style: TextStyle(fontSize: baseFontSize * 0.9)),
                  ),
                )
              ],
            ),
          ),
        ),
        // Animated error message display
        AnimatedOpacity(
          opacity: errorOpacity,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: EdgeInsets.only(left: baseFontSize * 0.75, top: baseFontSize * 0.25, bottom: baseFontSize * 0.25),
            child: Text(
              errorText ?? '',
              style: TextStyle(color: Colors.red, fontSize: baseFontSize * 0.75),
            ),
          ),
        ),
      ],
    );
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get MediaQuery data for screen size and text scaling
    final media = MediaQuery.of(context);
    final size = media.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // --- Responsive Calculations ---
    // Base font size relative to screen width, clamped to reasonable min/max
    final double baseFontSize = (size.width * 0.04).clamp(14.0, 18.0);
    // Spacing relative to screen height, clamped
    final double spacing = (size.height * 0.015).clamp(10.0, 20.0);
    // Icon sizes relative to screen width, clamped
    final double themeIconSize = (size.width * 0.06).clamp(24.0, 32.0);
    final double socialIconSize = (size.width * 0.06).clamp(24.0, 36.0); // For SocialIconButton class
    // Logo dimensions relative to screen size, clamped
    final double logoWidth = (size.width * 0.35).clamp(100.0, 200.0);
    final double logoHeight = (size.height * 0.1).clamp(50.0, 100.0);
    // Button padding relative to font size, clamped
    final double buttonVerticalPadding = (baseFontSize * 1.0).clamp(14.0, 18.0);

    return Scaffold(
      // Avoid keyboard overlap
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder( // Use LayoutBuilder for constraints
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Responsive horizontal padding
          final padding = EdgeInsets.symmetric(horizontal: (width * 0.08).clamp(16.0, 40.0));

          return Container(
            width: double.infinity,
            height: double.infinity,
            // Apply background based on theme
            decoration: isDark
                ? const BoxDecoration(color: Color(0xFF1e1f22)) // Dark theme background
                : const BoxDecoration(
              gradient: LinearGradient( // Light theme gradient
                colors: [Color(0xFFB3E5FC), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea( // Ensure content is within safe area
              child: Stack( // Stack for positioning theme toggle button
                children: [
                  // Main content column
                  Column(
                    children: [
                      // Scrollable area for the form
                      Expanded(
                        child: SingleChildScrollView(
                          padding: padding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: spacing * 2), // Top spacing
                              // Logo
                              Image.asset('assets/logo.png', width: logoWidth, height: logoHeight, fit: BoxFit.contain),
                              SizedBox(height: spacing * 2), // Spacing after logo
                              // Form widget
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // --- Full Name Field ---
                                    _buildTextFieldWithShake(
                                        _fullNameController, 'Full Name', _fullNameError, _fullNameErrorOpacity, _fullNameShakeController, _validateFullNameLive, baseFontSize),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Email Field with Get Code Button ---
                                    _buildTextFieldWithShake(
                                      _emailController, 'Email ID', _emailError, _emailErrorOpacity, _emailShakeController, _validateEmailLive, baseFontSize,
                                      keyboardType: TextInputType.emailAddress,
                                      // Suffix Icon is the "Get Code" button
                                      suffixIcon: Padding(
                                        padding: EdgeInsets.only(right: baseFontSize * 0.5), // Padding for the button
                                        child: TextButton(
                                          onPressed: _handleGetEmailCode, // Call the email code handler
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            padding: EdgeInsets.symmetric(horizontal: baseFontSize * 0.6, vertical: baseFontSize * 0.5),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text("Get Code", style: TextStyle(fontSize: baseFontSize * 0.9)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Email Verification Code Field ---
                                    _buildTextFieldWithShake(
                                        _emailCodeController, 'Email Verification Code', _emailCodeError, _emailCodeErrorOpacity, _emailCodeShakeController, _validateEmailCodeLive, baseFontSize,
                                        keyboardType: TextInputType.number, // Usually numeric
                                        isDense: true // Make it slightly more compact if needed
                                    ),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Phone Field ---
                                    _buildPhoneFieldWithShake(
                                        _phoneController, 'Phone Number', _phoneError, _phoneErrorOpacity, _phoneShakeController, _validatePhoneLive, baseFontSize),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Phone Verification Code Field ---
                                    _buildTextFieldWithShake(
                                        _phoneCodeController, 'Phone Verification Code', _phoneCodeError, _phoneCodeErrorOpacity, _phoneCodeShakeController, _validatePhoneCodeLive, baseFontSize,
                                        keyboardType: TextInputType.number, // Usually numeric
                                        isDense: true // Make it slightly more compact
                                    ),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Password Field ---
                                    _buildTextFieldWithShake(
                                        _passwordController, 'Password', _passwordError, _passwordErrorOpacity, _passwordShakeController, _validatePasswordLive, baseFontSize,
                                        obscure: _obscurePassword,
                                        keyboardType: TextInputType.visiblePassword,
                                        // Suffix icon to toggle visibility
                                        suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: _togglePasswordVisibility)),
                                    SizedBox(height: spacing * 0.5), // Reduced spacing

                                    // --- Confirm Password Field ---
                                    _buildTextFieldWithShake(
                                        _confirmPasswordController, 'Confirm Password', _confirmPasswordError, _confirmPasswordErrorOpacity, _confirmPasswordShakeController, _validateConfirmPasswordLive, baseFontSize,
                                        obscure: _obscureConfirmPassword,
                                        keyboardType: TextInputType.visiblePassword,
                                        // Suffix icon to toggle visibility
                                        suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: _toggleConfirmPasswordVisibility)),
                                  ],
                                ),
                              ),
                              SizedBox(height: spacing * 2), // Spacing before Sign Up button
                              // --- Sign Up Button ---
                              SizedBox(
                                width: double.infinity, // Full width button
                                child: ElevatedButton(
                                  onPressed: _signUp, // Call the sign-up logic
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue, // Button color
                                    padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding), // Responsive padding
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners
                                    elevation: 3, // Subtle shadow
                                  ),
                                  child: Text("Sign Up", style: TextStyle(fontSize: baseFontSize * 1.05, color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              SizedBox(height: spacing * 2), // Spacing after Sign Up button
                              // --- "Or Sign up with" Text ---
                              Text(
                                  "or Sign up with",
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: baseFontSize * 0.9)
                              ),
                              SizedBox(height: spacing), // Spacing before social icons
                              // --- Social Login Buttons ---
                              Wrap(
                                spacing: spacing * 0.8, // Horizontal spacing between icons
                                runSpacing: spacing * 0.6, // Vertical spacing if icons wrap
                                alignment: WrapAlignment.center, // Center align icons
                                children: [
                                  // Loop through image paths and create SocialIconButton
                                  for (final path in ['assets/google.png', 'assets/facebook.png', 'assets/twitter.png', 'assets/linkedin.png'])
                                    SocialIconButton( // Use the SocialIconButton class from LoginScreen
                                        imagePath: path,
                                        onPressed: () {
                                          // TODO: Implement social login logic
                                          print("Social button pressed: $path");
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Social Login Tapped: $path (Implement Logic)')),
                                          );
                                        }
                                      // The SocialIconButton class now handles its own size
                                    ),
                                ],
                              ),
                              SizedBox(height: spacing * 2), // Bottom spacing inside scroll view
                            ],
                          ),
                        ),
                      ),
                      // --- "Already have an account?" Row (outside scroll view, at the bottom) ---
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing * 1.5, top: spacing),
                        child: Wrap( // Use Wrap instead of Row
                          alignment: WrapAlignment.center, // Align items in the center
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(fontSize: baseFontSize, color: isDark ? Colors.grey[400] : Colors.black.withOpacity(0.6)),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                                }
                              },
                              child: Text(
                                "Sign In",
                                style: TextStyle(fontSize: baseFontSize, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // --- Theme Toggle Button (Positioned top-right) ---
                  Positioned(
                    top: spacing * 0.6, // Position from top
                    right: spacing * 0.6, // Position from right
                    child: GestureDetector(
                      onTap: () => themeNotifier.toggleTheme(), // Toggle theme on tap
                      child: Container(
                        padding: EdgeInsets.all(themeIconSize * 0.0), // Small padding inside circle
                        decoration: BoxDecoration(
                          // Semi-transparent background for the button
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle, // Circular shape
                        ),
                        child: Image.asset(
                          // Show sun or moon icon based on theme
                          isDark ? 'assets/sun.png' : 'assets/moon.png',
                          width: themeIconSize, height: themeIconSize,
                        ),
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
}


// --- Social Icon Button Widget (Requires import from login_screen.dart or definition here) ---
// Ensure this class is accessible, either by importing login_screen.dart
// or defining it again here if needed.
// Example definition (if not importing):
class SocialIconButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final double? iconSize; // Optional size override

  const SocialIconButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    this.iconSize, // Make size optional
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use provided size or default calculation
    final double effectiveIconSize = iconSize ?? (MediaQuery.of(context).size.width * 0.06).clamp(24.0, 36.0);
    final double buttonSize = effectiveIconSize * 1.8; // Button slightly larger than icon

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[700] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.zero, // No internal padding, center the image
          side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
          elevation: 2, // Add subtle elevation
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          splashFactory: InkRipple.splashFactory,
        ),
        child: Center( // Center the image inside the button
          child: Image.asset(
            imagePath,
            height: effectiveIconSize, // Use calculated size
            width: effectiveIconSize, // Use calculated size
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}