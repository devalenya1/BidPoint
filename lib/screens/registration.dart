import 'dart:io';

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/google_recaptcha.dart';
import 'package:active_ecommerce_flutter/custom/input_decorations.dart';
import 'package:active_ecommerce_flutter/custom/intl_phone_input.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/other_config.dart';
import 'package:active_ecommerce_flutter/repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/screens/login.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';

import '../custom/loading.dart';
import '../repositories/address_repository.dart';

class Registration extends StatefulWidget {
  final VoidCallback? onRegistrationSuccess;
  
  const Registration({Key? key, this.onRegistrationSuccess}) : super(key: key);

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String _register_by = "email"; //phone or email
  String initialCountry = 'US';

  var countries_code = <String?>[];

  String? _phone = "";
  bool? _isAgree = false;
  bool _isCaptchaShowing = false;
  String googleRecaptchaKey = "";

  // Password strength
  bool _passwordLengthValid = false;
  bool _passwordUppercaseValid = false;
  bool _passwordLowercaseValid = false;
  bool _passwordNumberValid = false;
  bool _passwordSpecialValid = false;
  int _passwordStrength = 0;
  bool _showPasswordRequirements = false;

  //controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    fetch_country();
    
    // Add password listener
    _passwordController.addListener(_validatePassword);
    _passwordConfirmController.addListener(_checkPasswordMatch);
  }
  
  void _validatePassword() {
    final password = _passwordController.text;
    
    setState(() {
      _passwordLengthValid = password.length >= 8;
      _passwordUppercaseValid = RegExp(r'[A-Z]').hasMatch(password);
      _passwordLowercaseValid = RegExp(r'[a-z]').hasMatch(password);
      _passwordNumberValid = RegExp(r'[0-9]').hasMatch(password);
      _passwordSpecialValid = RegExp(r'[!\-_@#$%^&*(),.?":{}|<>]').hasMatch(password);
      
      _passwordStrength = [
        _passwordLengthValid,
        _passwordUppercaseValid,
        _passwordLowercaseValid,
        _passwordNumberValid,
        _passwordSpecialValid,
      ].where((v) => v).length;
      
      _showPasswordRequirements = password.isNotEmpty;
    });
  }
  
  void _checkPasswordMatch() {
    setState(() {});
  }
  
  String _getStrengthText() {
    if (_passwordController.text.isEmpty) return "Enter a password";
    if (_passwordStrength <= 2) return "Weak password";
    if (_passwordStrength == 3) return "Fair password";
    if (_passwordStrength == 4) return "Good password";
    return "Strong password";
  }
  
  Color _getStrengthColor() {
    if (_passwordController.text.isEmpty) return const Color(0xFF718096);
    if (_passwordStrength <= 2) return const Color(0xFFF56565);
    if (_passwordStrength == 3) return const Color(0xFFED8936);
    if (_passwordStrength == 4) return const Color(0xFFECC94B);
    return const Color(0xFF48BB78);
  }
  
  double _getStrengthWidth() {
    if (_passwordController.text.isEmpty) return 0;
    if (_passwordStrength <= 2) return 0.25;
    if (_passwordStrength == 3) return 0.5;
    if (_passwordStrength == 4) return 0.75;
    return 1.0;
  }

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    _passwordController.removeListener(_validatePassword);
    _passwordConfirmController.removeListener(_checkPasswordMatch);
    super.dispose();
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go("/");
    }
  }

  onPressSignUp() async {
    Loading.show(context);

    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var password_confirm = _passwordConfirmController.text.toString();

    if (name == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (_register_by == 'email' && (email == "" || !isEmail(email))) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (_register_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.enter_phone_number,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password_confirm == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.confirm_your_password,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .password_must_contain_at_least_6_characters,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password != password_confirm) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.passwords_do_not_match,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    }
    
    // Check password strength
    if (_passwordStrength < 4) {
      ToastComponent.showDialog(
          "Please create a stronger password with at least 8 characters, uppercase, lowercase, number, and special character.",
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    }

    var signupResponse = await AuthRepository().getSignupResponse(
        name,
        _register_by == 'email' ? email : _phone,
        password,
        password_confirm,
        _register_by,
        googleRecaptchaKey);
    Loading.close();

    if (signupResponse.result == false) {
      var message = "";
      signupResponse.message.forEach((value) {
        message += value + "\n";
      });
      ToastComponent.showDialog(message, gravity: Toast.center, duration: 3);
    } else {
      ToastComponent.showDialog(signupResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      AuthHelper().setUserData(signupResponse);
      
      // Call success callback if provided
      if (widget.onRegistrationSuccess != null) {
        widget.onRegistrationSuccess!();
      }

      // redirect to main
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) {
            return Main();
          }), (newRoute) => false);

      // push notification starts
      if (OtherConfig.USE_PUSH_NOTIFICATION) {
        final FirebaseMessaging _fcm = FirebaseMessaging.instance;
        await _fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        String? fcmToken = await _fcm.getToken();

        if (fcmToken != null) {
          print("--fcm token--");
          print(fcmToken);
          if (is_logged_in.$ == true) {
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken);
          }
        }
      }

      context.go("/");
    }
  }

  @override
  Widget build(BuildContext context) {
    final _screen_width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side Image (visible on larger screens)
          if (_screen_width > 900)
            Expanded(
              flex: 7,
              child: Container(
                height: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: Image.asset(
                  'assets/register_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: MyTheme.accent_color.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.storefront,
                          size: 100,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Right Side - Registration Form
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _screen_width > 600 ? 40 : 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: _navigateBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Site Icon
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Image.asset(
                        'assets/logo.png',
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: MyTheme.accent_color,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Title
                    Text(
                      AppLocalizations.of(context)!.create_an_account,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Registration Form
                    _buildRegistrationForm(),
                    
                    const SizedBox(height: 24),
                    
                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.already_have_an_account,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return Login();
                              }));
                            },
                            child: Text(
                              AppLocalizations.of(context)!.log_in,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0092AC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Social Login Section
                    _buildSocialLogin(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name Field
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.full_name_ucf,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.full_name_ucf,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MyTheme.accent_color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Email/Phone Field
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _register_by == "email"
                    ? AppLocalizations.of(context)!.email_ucf
                    : AppLocalizations.of(context)!.phone_ucf,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              if (_register_by == "email")
                TextField(
                  controller: _emailController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "johndoe@example.com",
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: MyTheme.accent_color),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                )
              else
                Container(
                  height: 48,
                  child: CustomInternationalPhoneNumberInput(
                    countries: countries_code,
                    onInputChanged: (PhoneNumber number) {
                      setState(() {
                        _phone = number.phoneNumber;
                      });
                    },
                    onInputValidated: (bool value) {},
                    selectorConfig: SelectorConfig(
                      selectorType: PhoneInputSelectorType.DIALOG,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.disabled,
                    selectorTextStyle: const TextStyle(color: Color(0xFF64748B)),
                    textStyle: const TextStyle(color: Color(0xFF0F172A)),
                    textFieldController: _phoneNumberController,
                    formatInput: true,
                    keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                    inputDecoration: InputDecoration(
                      hintText: "01XXX XXX XXX",
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: MyTheme.accent_color),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSaved: (PhoneNumber number) {},
                  ),
                ),
              
              // Toggle between email and phone
              if (otp_addon_installed.$)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _register_by = _register_by == "email" ? "phone" : "email";
                      });
                    },
                    child: Text(
                      _register_by == "email"
                          ? AppLocalizations.of(context)!.or_register_with_a_phone
                          : AppLocalizations.of(context)!.or_register_with_an_email,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Password Field with Strength Meter
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.password_ucf,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                autofocus: false,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MyTheme.accent_color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              
              // Password Strength Meter
              if (_showPasswordRequirements) ...[
                const SizedBox(height: 8),
                Container(
                  height: 4,
 decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getStrengthWidth(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getStrengthColor(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStrengthText(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getStrengthColor(),
                  ),
                ),
                const SizedBox(height: 8),
                // Password Requirements
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildRequirementItem(
                      "At least 8 characters",
                      _passwordLengthValid,
                    ),
                    _buildRequirementItem(
                      "At least 1 uppercase letter",
                      _passwordUppercaseValid,
                    ),
                    _buildRequirementItem(
                      "At least 1 lowercase letter",
                      _passwordLowercaseValid,
                    ),
                    _buildRequirementItem(
                      "At least 1 number",
                      _passwordNumberValid,
                    ),
                    _buildRequirementItem(
                      "At least 1 special character (!-_@#\$%^&*)",
                      _passwordSpecialValid,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Confirm Password Field
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.retype_password_ucf,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmController,
                autofocus: false,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  errorText: (_passwordConfirmController.text.isNotEmpty && 
                             _passwordController.text != _passwordConfirmController.text)
                      ? "Passwords do not match"
                      : null,
                  errorStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: MyTheme.accent_color),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        
        // reCAPTCHA
        if (google_recaptcha.$)
          Container(
            height: _isCaptchaShowing ? 350 : 50,
            width: 300,
            child: Captcha(
              (keyValue) {
                googleRecaptchaKey = keyValue;
                setState(() {});
              },
              handleCaptcha: (data) {
                if (_isCaptchaShowing.toString() != data) {
                  _isCaptchaShowing = data;
                  setState(() {});
                }
              },
              isIOS: Platform.isIOS,
            ),
          ),
        
        // Terms and Conditions
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _isAgree,
                  onChanged: (newValue) {
                    setState(() {
                      _isAgree = newValue;
                    });
                  },
                  activeColor: MyTheme.accent_color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                    children: [
                      const TextSpan(text: "By signing up you agree to our "),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommonWebviewScreen(
                                  page_name: "Terms Conditions",
                                  url: "${AppConfig.RAW_BASE_URL}/mobile-page/terms",
                                ),
                              ),
                            );
                          },
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontWeight: FontWeight.w500,
                        ),
                        text: "terms and conditions.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Create Account Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 24),
          child: ElevatedButton(
            onPressed: (_isAgree == true && _passwordStrength >= 4 && 
                (_passwordController.text == _passwordConfirmController.text || _passwordConfirmController.text.isEmpty))
                ? onPressSignUp
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
            ),
            child: Text(
              AppLocalizations.of(context)!.create_account,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRequirementItem(String text, bool isValid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle,
          size: 10,
          color: isValid ? const Color(0xFF48BB78) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isValid ? const Color(0xFF48BB78) : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSocialLogin() {
    if (!allow_google_login.$ && !allow_facebook_login.$ && !allow_twitter_login.$) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        const Center(
          child: Text(
            'Or Join With',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (allow_facebook_login.$)
              _buildSocialButton(
                icon: 'assets/facebook_logo.png',
                onTap: () {
                  // Facebook login logic
                },
              ),
            if (allow_twitter_login.$)
              _buildSocialButton(
                icon: 'assets/twitter_logo.png',
                onTap: () {
                  // Twitter login logic
                },
                marginLeft: 16,
              ),
            if (allow_google_login.$)
              _buildSocialButton(
                icon: 'assets/google_logo.png',
                onTap: () {
                  // Google login logic
                },
                marginLeft: 16,
              ),
            if (Platform.isIOS)
              _buildSocialButton(
                icon: 'assets/apple_logo.png',
                onTap: () {
                  // Apple login logic
                },
                marginLeft: 16,
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onTap,
    double marginLeft = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(left: marginLeft),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            icon,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person_outline,
                size: 20,
                color: Color(0xFF64748B),
              );
            },
          ),
        ),
      ),
    );
  }
}