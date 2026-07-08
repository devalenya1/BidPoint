import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/input_decorations.dart';
import 'package:active_ecommerce_flutter/custom/intl_phone_input.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/helpers/auth_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/other_config.dart';
import 'package:active_ecommerce_flutter/repositories/auth_repository.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:active_ecommerce_flutter/screens/main.dart';
import 'package:active_ecommerce_flutter/screens/password_forget.dart';
import 'package:active_ecommerce_flutter/screens/registration.dart';
import 'package:active_ecommerce_flutter/social_config.dart';
import 'package:active_ecommerce_flutter/ui_elements/auth_ui.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:toast/toast.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom/loading.dart';
import '../repositories/address_repository.dart';

class Login extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const Login({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "email"; //phone or email
  String initialCountry = 'US';

  var countries_code = <String?>[];

  String? _phone = "";

  //controllers
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // ✅ Add flag to prevent multiple redirects
  bool _hasRedirected = false;
  
  // ✅ Password visibility toggle
  bool _obscurePassword = true;

  // ✅ Remember me state
  bool _rememberMe = false;

  @override
  void initState() {
    //on Splash Screen hide statusbar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
    fetch_country();
    // ✅ Check if user is already logged in
    _checkIfLoggedIn();
  }

  // ✅ Check if user is already logged in and redirect to home
  void _checkIfLoggedIn() {
    if (is_logged_in.$ == true && !_hasRedirected) {
      _hasRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go("/");
        }
      });
    }
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
    super.dispose();
  }


  onPressedLogin() async {
    Loading.show(context);
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showWarning(AppLocalizations.of(context)!.enter_email,
          gravity: Toast.center, duration: Toast.lengthLong);
      Loading.close();
      return;
    } else if (_login_by == 'phone' && _phone == "") {
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
    }

    var loginResponse = await AuthRepository().getLoginResponse(
        _login_by == 'email' ? email : _phone, password, _login_by);
    Loading.close();
    
    if (loginResponse.result == false) {
      if (loginResponse.message.runtimeType == List) {
        ToastComponent.showError(loginResponse.message!.join("\n"),
            gravity: Toast.center, duration: 3);
        return;
      }
      ToastComponent.showError(loginResponse.message!.toString(),
          gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showSuccess(loginResponse.message!,
          gravity: Toast.center, duration: Toast.lengthLong);
      
      await AuthHelper().setUserData(loginResponse);
      
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
          if (is_logged_in.$ == true) {
            // update device token
            var deviceTokenUpdateResponse = await ProfileRepository()
                .getDeviceTokenUpdateResponse(fcmToken);
          }
        }
      }

      // ✅ Use pushReplacement to remove login from stack
      // Also call the callback if provided
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
      
      // Navigate back to Home
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        context.pushReplacement("/");
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
          // ✅ Use pushReplacement to remove login from stack
          
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
          }
          
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          } else {
            context.pushReplacement("/");
          }

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
        // ✅ Use pushReplacement to remove login from stack
      
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
        
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.pushReplacement("/");
        }
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
        // ✅ Use pushReplacement to remove login from stack
        
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
        
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.pushReplacement("/");
        }
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
        // ✅ Use pushReplacement to remove login from stack
        
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
        
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.pushReplacement("/");
        }
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
        "${AppLocalizations.of(context)!.login_to} " + AppConfig.app_name,
        buildBody(context, _screen_width));
  }

  Widget buildBody(BuildContext context, double _screen_width) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBorderColor = Colors.grey.shade300;
    final isSmallScreen = _screen_width < 400;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ============================================
            // Heading: "Login Your Account" - GRAY COLOR
            // ============================================
            Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: 30.h),
              child: Text(
                AppLocalizations.of(context)!.login_your_account,
                style: TextStyle(
                  color: Colors.grey.shade700, // Changed to gray
                  fontSize: isSmallScreen ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            
            // ============================================
            // Email Input Field (Full Width) WITH ICON
            // ============================================
            if (_login_by == "email")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey.shade400,
                          size: 20.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Phone login option - FLOAT TO THE RIGHT
                  if (otp_addon_installed.$)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _login_by = "phone";
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.or_login_with_a_phone,
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
            
            // ============================================
            // Phone Input Field (Full Width) WITH ICON
            // ============================================
            if (_login_by == "phone")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Email login option - FLOAT TO THE RIGHT
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _login_by = "email";
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)!.or_login_with_an_email,
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
            
            SizedBox(height: 16.h),
            
            // ============================================
            // Password Input Field (Full Width) with Eye Icon & Icon
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
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
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
            
            SizedBox(height: 12.h),
            
            // ============================================
            // Remember Me (Left) & Forgot Password (Right)
            // ============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember Me - NOW CLICKABLE
                InkWell(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: MyTheme.accent_color,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.remember_me,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Forgot Password
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return PasswordForget();
                    }));
                  },
                  child: Text(
                    AppLocalizations.of(context)!.forgot_password,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // ============================================
            // Login Button (Full Width, accent_color)
            // ============================================
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: onPressedLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.login_screen_log_in,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14.sp : 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // ============================================
            // Don't have an account? Sign Up (Text only)
            // ============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${AppLocalizations.of(context)!.dont_have_account} ",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isSmallScreen ? 12.sp : 14.sp,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Registration();
                    }));
                  },
                  child: Text(
                    AppLocalizations.of(context)!.sign_up,
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
            // OR Log In With (Divider)
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
                      AppLocalizations.of(context)!.or_log_in_with,
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
                // Twitter Button
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
  // Social Login Buttons - SIDE BY SIDE (icon and text)
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