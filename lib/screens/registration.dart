import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

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
import 'package:active_ecommerce_flutter/ui_elements/auth_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:active_ecommerce_flutter/social_config.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:twitter_login/twitter_login.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom/loading.dart';
import '../repositories/address_repository.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String _register_by = "email"; //phone or email
  String initialCountry = 'US';

  // PhoneNumber phoneCode = PhoneNumber(isoCode: 'US', dialCode: "+1");
  var countries_code = <String?>[];

  String? _phone = "";
  bool? _isAgree = false;
  bool _isCaptchaShowing = false;
  String googleRecaptchaKey = "";

  // Password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength variables
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;
  double _strengthProgress = 0.0;

  //controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    fetch_country();
    
    // Add listener to password controller for strength checking
    _passwordController.addListener(_updatePasswordStrength);
  }

  // Password strength calculation method
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = '';
        _strengthColor = Colors.grey;
        _strengthProgress = 0.0;
        return;
      }
      
      // Calculate password strength
      int strength = 0;
      
      // Length check
      if (password.length >= 6) strength++;
      if (password.length >= 8) strength++;
      
      // Contains number
      if (password.contains(RegExp(r'[0-9]'))) strength++;
      
      // Contains uppercase and lowercase
      if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) strength++;
      
      // Contains special character
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
      
      // Determine strength level (max 5)
      if (strength <= 1) {
        _passwordStrength = AppLocalizations.of(context)!.password_weak;
        _strengthColor = Colors.red;
        _strengthProgress = 0.2;
      } else if (strength == 2) {
        _passwordStrength = AppLocalizations.of(context)!.password_fair;
        _strengthColor = Colors.orange;
        _strengthProgress = 0.4;
      } else if (strength == 3) {
        _passwordStrength = AppLocalizations.of(context)!.password_good;
        _strengthColor = Colors.yellow.shade700;
        _strengthProgress = 0.6;
      } else if (strength == 4) {
        _passwordStrength = AppLocalizations.of(context)!.password_strong;
        _strengthColor = Colors.lightGreen;
        _strengthProgress = 0.8;
      } else {
        _passwordStrength = AppLocalizations.of(context)!.password_very_strong;
        _strengthColor = Colors.green;
        _strengthProgress = 1.0;
      }
    });
  }

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countries_code.add(c.code));
  }

  @override
  void dispose() {
    //before going to other screen show statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    _passwordController.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  onPressSignUp() async {
    Loading.show(context);

    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var password_confirm = _passwordConfirmController.text.toString();

    if (name == "") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.enter_your_name,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (_register_by == 'email' && (email == "" || !isEmail(email))) {
      ToastComponent.showWarning(AppLocalizations.of(context)!.enter_valid_email,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (_register_by == 'phone' && _phone == "") {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.enter_phone_number,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password == "") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.enter_password,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password_confirm == "") {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.confirm_your_password,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password.length < 6) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!
              .password_must_contain_at_least_6_characters,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (password != password_confirm) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.passwords_do_not_match,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Loading.close();
      return;
    }

    if (_isAgree != true) {
      ToastComponent.showWarning(
          AppLocalizations.of(context)!.please_agree_to_terms,
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

      ToastComponent.showError(message, gravity: Toast.center, duration: 3);
    } else {
      ToastComponent.showSuccess(signupResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      AuthHelper().setUserData(signupResponse);

      // redirect to main
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) {
            return Main();
          }), (route) => false);

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
            // update device token
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken);
          }
        }
      }
    }
  }


  onPressedFacebookLogin() async {
    try {
      final facebookLogin = await FacebookAuth.instance
          .login(loginBehavior: LoginBehavior.webOnly);

      if (facebookLogin.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        var loginResponse = await AuthRepository().getSocialLoginResponse(
            "facebook",
            userData['name'].toString(),
            userData['email'].toString(),
            userData['id'].toString(),
            access_token: facebookLogin.accessToken!.token);
        print("..........................${loginResponse.toString()}");
        
        if (loginResponse.result == false) {
          ToastComponent.showError(loginResponse.message!,
              gravity: Toast.center, duration: Toast.lengthLong);
        } else {
          ToastComponent.showSuccess(loginResponse.message!,
              gravity: Toast.center, duration: Toast.lengthLong);

          await AuthHelper().setUserData(loginResponse);
          // Navigate to Main
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const Main();
          }));
          FacebookAuth.instance.logOut();
        }
      } else {
        print("....Facebook auth Failed.........");
        print(facebookLogin.status);
        print(facebookLogin.message);
        ToastComponent.showError(AppLocalizations.of(context)!.facebook_login_failed,
            gravity: Toast.center, duration: Toast.lengthLong);
      }
    } on Exception catch (e) {
      print(e);
      ToastComponent.showError(AppLocalizations.of(context)!.facebook_login_error,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  onPressedGoogleLogin() async {
    try {
      final GoogleSignInAccount googleUser = (await GoogleSignIn().signIn())!;

      print(googleUser.toString());

      GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser.authentication;
      String? accessToken = googleSignInAuthentication.accessToken;

      print("displayName ${googleUser.displayName}");
      print("email ${googleUser.email}");
      print("googleUser.id ${googleUser.id}");

      var loginResponse = await AuthRepository().getSocialLoginResponse(
          "google", googleUser.displayName, googleUser.email, googleUser.id,
          access_token: accessToken);

      if (loginResponse.result == false) {
        ToastComponent.showError(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
      } else {
        ToastComponent.showSuccess(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
        await AuthHelper().setUserData(loginResponse);
        // Navigate to Main
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const Main();
        }));
      }
      GoogleSignIn().disconnect();
    } on Exception catch (e) {
      print("error is ....... $e");
      ToastComponent.showError(AppLocalizations.of(context)!.google_login_error,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  onPressedTwitterLogin() async {
    try {
      final twitterLogin = new TwitterLogin(
          apiKey: SocialConfig().twitter_consumer_key,
          apiSecretKey: SocialConfig().twitter_consumer_secret,
          redirectURI: 'activeecommerceflutterapp://');
      // Trigger the sign-in flow

      final authResult = await twitterLogin.login();

      print("authResult");

      var loginResponse = await AuthRepository().getSocialLoginResponse(
          "twitter",
          authResult.user!.name,
          authResult.user!.email,
          authResult.user!.id.toString(),
          access_token: authResult.authToken,
          secret_token: authResult.authTokenSecret);

      if (loginResponse.result == false) {
        ToastComponent.showError(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
      } else {
        ToastComponent.showSuccess(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
        await AuthHelper().setUserData(loginResponse);
        // Navigate to Main
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const Main();
        }));
      }
    } on Exception catch (e) {
      print("error is ....... $e");
      ToastComponent.showError(AppLocalizations.of(context)!.twitter_login_error,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      var loginResponse = await AuthRepository().getSocialLoginResponse(
          "apple",
          appleCredential.givenName,
          appleCredential.email,
          appleCredential.userIdentifier,
          access_token: appleCredential.identityToken);

      if (loginResponse.result == false) {
        ToastComponent.showError(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
      } else {
        ToastComponent.showSuccess(loginResponse.message!,
            gravity: Toast.center, duration: Toast.lengthLong);
        await AuthHelper().setUserData(loginResponse);
        // Navigate to Main
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const Main();
        }));
      }
    } on Exception catch (e) {
      print(e);
      ToastComponent.showError(AppLocalizations.of(context)!.apple_login_error,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _screen_height = MediaQuery.of(context).size.height;
    final _screen_width = MediaQuery.of(context).size.width;
    return AuthScreen.buildScreen(
        context,
        "${AppLocalizations.of(context)!.join_ucf} " + AppConfig.app_name,
        buildBody(context, _screen_width));
  }

  Widget buildBody(BuildContext context, double _screen_width) {
    final inputBorderColor = Colors.grey.shade300;
    final isSmallScreen = _screen_width < 400;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ============================================
            // Heading: "Create Your Account" - GRAY COLOR
            // ============================================
            Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 30.h),
              child: Text(
                AppLocalizations.of(context)!.create_your_account,
                style: TextStyle(
                  color: Colors.grey.shade700, // Changed to gray
                  fontSize: isSmallScreen ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            
            // ============================================
            // Full Name Input Field WITH ICON
            // ============================================
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                border: Border.all(color: inputBorderColor, width: 1.w),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: false,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.full_name,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.grey.shade400,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // ============================================
            // Email / Phone Input Field WITH ICON
            // ============================================
            if (_register_by == "email")
              Column(
                children: [
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: inputBorderColor, width: 1.w),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: TextField(
                      controller: _emailController,
                      autofocus: false,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.email_address,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey.shade400,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Register with phone - FLOAT TO THE RIGHT
                  if (otp_addon_installed.$)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _register_by = "phone";
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.or_register_with_a_phone,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 12.sp,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: inputBorderColor, width: 1.w),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: CustomInternationalPhoneNumberInput(
                      countries: countries_code,
                      onInputChanged: (PhoneNumber number) {
                        print(number.phoneNumber);
                        setState(() {
                          _phone = number.phoneNumber;
                        });
                      },
                      onInputValidated: (bool value) {
                        print(value);
                      },
                      selectorConfig: SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: TextStyle(color: MyTheme.font_grey, fontSize: 14.sp),
                      textStyle: TextStyle(color: MyTheme.font_grey, fontSize: 14.sp),
                      textFieldController: _phoneNumberController,
                      formatInput: true,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      inputDecoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.phone_number,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: Colors.grey.shade400,
                          size: 20.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                      ),
                      onSaved: (PhoneNumber number) {
                        print('On Saved: $number');
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Register with email - FLOAT TO THE RIGHT
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _register_by = "email";
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)!.or_register_with_an_email,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 12.h),
            
            // ============================================
            // Password Input Field with Eye Icon & Icon
            // ============================================
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                border: Border.all(color: inputBorderColor, width: 1.w),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextField(
                controller: _passwordController,
                autofocus: false,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.password,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 20.sp,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                      color: Colors.grey.shade500,
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            
            // ============================================
            // Password Strength Indicator (only when typing)
            // ============================================
            if (_passwordController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.r),
                        color: Colors.grey.shade300,
                      ),
                      child: LinearProgressIndicator(
                        value: _strengthProgress,
                        backgroundColor: Colors.grey.shade300,
                        color: _strengthColor,
                        minHeight: 4.h,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _passwordStrength,
                      style: TextStyle(
                        color: _strengthColor,
                        fontSize: isSmallScreen ? 9.sp : 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .password_must_contain_at_least_6_characters,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isSmallScreen ? 8.sp : 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 12.h),
            
            // ============================================
            // Confirm Password Input Field with Eye Icon & Icon
            // ============================================
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                border: Border.all(color: inputBorderColor, width: 1.w),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextField(
                controller: _passwordConfirmController,
                autofocus: false,
                obscureText: _obscureConfirmPassword,
                enableSuggestions: false,
                autocorrect: false,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.confirm_password,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 20.sp,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword 
                          ? Icons.visibility_off 
                          : Icons.visibility,
                      color: Colors.grey.shade500,
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // ============================================
            // Recaptcha
            // ============================================
            if (google_recaptcha.$)
              Container(
                height: _isCaptchaShowing ? 350.h : 50.h,
                width: 300.w,
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
            
            // ============================================
            // Terms & Conditions Checkbox
            // ============================================
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20.h,
                    width: 20.w,
                    child: Checkbox(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      value: _isAgree,
                      onChanged: (newValue) {
                        _isAgree = newValue;
                        setState(() {});
                      },
                      activeColor: MyTheme.accent_color,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isSmallScreen ? 10.sp : 12.sp,
                        ),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.i_agree_to_the,
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommonWebviewScreen(
                                      page_name: AppLocalizations.of(context)!.terms_conditions,
                                      url: "${AppConfig.RAW_BASE_URL}/mobile-page/terms",
                                    ),
                                  ),
                                );
                              },
                            style: TextStyle(
                              color: MyTheme.accent_color,
                              fontWeight: FontWeight.w600,
                            ),
                            text: " ${AppLocalizations.of(context)!.terms_conditions}",
                          ),
                          TextSpan(
                            text: " ${AppLocalizations.of(context)!.and_ucf}",
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommonWebviewScreen(
                                      page_name: AppLocalizations.of(context)!.privacy_policy,
                                      url: "${AppConfig.RAW_BASE_URL}/mobile-page/privacy-policy",
                                    ),
                                  ),
                                );
                              },
                            style: TextStyle(
                              color: MyTheme.accent_color,
                              fontWeight: FontWeight.w600,
                            ),
                            text: " ${AppLocalizations.of(context)!.privacy_policy}",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // ============================================
            // Create Account Button
            // ============================================
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isAgree! ? onPressSignUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  AppLocalizations.of(context)!.create_account,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14.sp : 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // ============================================
            // Already have account? Login
            // ============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.already_have_an_account,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isSmallScreen ? 12.sp : 14.sp,
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Login();
                    }));
                  },
                  child: Text(
                    AppLocalizations.of(context)!.log_in,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: isSmallScreen ? 12.sp : 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // ============================================
            // OR Sign Up With (Divider)
            // ============================================
            Visibility(
              visible: allow_google_login.$ || allow_facebook_login.$,
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1.w,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      AppLocalizations.of(context)!.or_sign_up_with,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isSmallScreen ? 10.sp : 12.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1.w,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // ============================================
            // Social Login Buttons - SIDE BY SIDE (icon and text)
            // ============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Button
                Visibility(
                  visible: allow_google_login.$,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: _buildSocialLoginButtonSideBySide(
                      label: "Google",
                      iconPath: "assets/google_logo.png",
                      onTap: onPressedGoogleLogin,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ),
                // Facebook Button
                Visibility(
                  visible: allow_facebook_login.$,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: _buildSocialLoginButtonSideBySide(
                      label: "Facebook",
                      iconPath: "assets/facebook_logo.png",
                      onTap: onPressedFacebookLogin,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ),
                // // Twitter Button
                // Visibility(
                //   visible: allow_twitter_login.$,
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 6.w),
                //     child: _buildSocialLoginButtonSideBySide(
                //       label: "Twitter",
                //       iconPath: "assets/twitter_logo.png",
                //       onTap: onPressedTwitterLogin,
                //       isSmallScreen: isSmallScreen,
                //     ),
                //   ),
                // ),
              ],
            ),
            
            // Apple Login (iOS only) - Full width
            if (Platform.isIOS)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: SizedBox(
                  width: double.infinity,
                  child: SignInWithAppleButton(
                    onPressed: signInWithApple,
                  ),
                ),
              ),
            
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
  
  // ============================================
  // Social Login Button - SIDE BY SIDE (icon and text) - FIXED
  // ============================================
  Widget _buildSocialLoginButtonSideBySide({
    required String label,
    required String iconPath,
    required VoidCallback onTap,
    bool isSmallScreen = false,
  }) {
    return SizedBox(
      width: 120.w,  // Fixed width for all buttons
      height: 44.h,   // Fixed height for all buttons
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 1.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          backgroundColor: Colors.grey.shade100,  // Light gray background
          padding: EdgeInsets.symmetric(horizontal: 12.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: isSmallScreen ? 18.w : 22.w,
              height: isSmallScreen ? 18.w : 22.w,
              child: Image.asset(
                iconPath,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: isSmallScreen ? 11.sp : 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}