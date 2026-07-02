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
      context.pushReplacement("/");
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
          context.pushReplacement("/");
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
        context.pushReplacement("/");
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
        context.pushReplacement("/");
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
        context.pushReplacement("/");
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: _screen_width * (3 / 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  _login_by == "email"
                      ? AppLocalizations.of(context)!.email_ucf
                      : AppLocalizations.of(context)!.login_screen_phone,
                  style: TextStyle(
                      color: MyTheme.accent_color, fontWeight: FontWeight.w600),
                ),
              ),
              if (_login_by == "email")
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 36.h,
                        child: TextField(
                          controller: _emailController,
                          autofocus: false,
                          decoration: InputDecorations.buildInputDecoration_1(
                              hint_text: AppLocalizations.of(context)!.email_hint),
                        ),
                      ),
                      otp_addon_installed.$
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _login_by = "phone";
                                });
                              },
                              child: Text(
                                AppLocalizations.of(context)!
                                    .or_login_with_a_phone,
                                style: TextStyle(
                                    color: MyTheme.accent_color,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline),
                              ),
                            )
                          : Container()
                    ],
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 36.h,
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
                          selectorTextStyle:
                              TextStyle(color: MyTheme.font_grey),
                          textStyle: TextStyle(color: MyTheme.font_grey),
                          textFieldController: _phoneNumberController,
                          formatInput: true,
                          keyboardType: TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          inputDecoration:
                              InputDecorations.buildInputDecoration_phone(
                                  hint_text: AppLocalizations.of(context)!.phone_hint),
                          onSaved: (PhoneNumber number) {
                            print('On Saved: $number');
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _login_by = "email";
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.or_login_with_an_email,
                          style: TextStyle(
                              color: MyTheme.accent_color,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline),
                        ),
                      )
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  AppLocalizations.of(context)!.password_ucf,
                  style: TextStyle(
                      color: MyTheme.accent_color, fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 36.h,
                      child: TextField(
                        controller: _passwordController,
                        autofocus: false,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecorations.buildInputDecoration_1(
                            hint_text: AppLocalizations.of(context)!.password_hint),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return PasswordForget();
                        }));
                      },
                      child: Text(
                        AppLocalizations.of(context)!
                            .login_screen_forgot_password,
                        style: TextStyle(
                            color: MyTheme.accent_color,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30.h),
                child: Container(
                  height: 45.h,
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: MyTheme.textfield_grey, width: 1.w),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12.0))),
                  child: Btn.minWidthFixHeight(
                    minWidth: MediaQuery.of(context).size.width,
                    height: 50.h,
                    color: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6.0))),
                    child: Text(
                      AppLocalizations.of(context)!.login_screen_log_in,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      onPressedLogin();
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15.h, bottom: 15.h),
                child: Center(
                    child: Text(
                  AppLocalizations.of(context)!
                      .login_screen_or_create_new_account,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 12.sp),
                )),
              ),
              Container(
                height: 45.h,
                child: Btn.minWidthFixHeight(
                  minWidth: MediaQuery.of(context).size.width,
                  height: 50.h,
                  color: MyTheme.amber,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(6.0))),
                  child: Text(
                    AppLocalizations.of(context)!.login_screen_sign_up,
                    style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Registration();
                    }));
                  },
                ),
              ),
              if (Platform.isIOS)
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: SignInWithAppleButton(
                    onPressed: () async {
                      signInWithApple();
                    },
                  ),
                ),
              Visibility(
                visible: allow_google_login.$ || allow_facebook_login.$,
                child: Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Center(
                      child: Text(
                    AppLocalizations.of(context)!.login_screen_login_with,
                    style: TextStyle(color: MyTheme.font_grey, fontSize: 12.sp),
                  )),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Center(
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: allow_google_login.$,
                          child: InkWell(
                            onTap: () {
                              onPressedGoogleLogin();
                            },
                            child: Container(
                              width: 28.w,
                              child: Image.asset("assets/google_logo.png"),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 15.w),
                          child: Visibility(
                            visible: allow_facebook_login.$,
                            child: InkWell(
                              onTap: () {
                                onPressedFacebookLogin();
                              },
                              child: Container(
                                width: 28.w,
                                child: Image.asset("assets/facebook_logo.png"),
                              ),
                            ),
                          ),
                        ),
                        if (allow_twitter_login.$)
                          Padding(
                            padding: EdgeInsets.only(left: 15.w),
                            child: InkWell(
                              onTap: () {
                                onPressedTwitterLogin();
                              },
                              child: Container(
                                width: 28.w,
                                child: Image.asset("assets/twitter_logo.png"),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}