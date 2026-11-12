var this_year = DateTime.now().year.toString();

class AppConfig {
  static String copyright_text =
      "@ BidPoint " + this_year; //this shows in the splash screen
  static String app_name = "BidPoint"; //this shows in the splash screen

  static String purchase_code =
      "9a663b28-9ec7-4567-b05b-849cd4461fa44"; //enter your purchase code for the app from codecanyon
  static String system_key =
      r"9a663b28-9ec7-4567-b05b-849cd4461fa44"; //enter your purchase code for the app from codecanyon

  //Default language config
  // static String default_language = "en";
  // static String mobile_app_code = "en";
  static String default_language = "es";
  static String mobile_app_code = "es";
  static bool app_language_rtl = false;

  //configure this
  static const bool HTTPS = true;

  static const DOMAIN_PATH = "bidpoint.mx";

  //do not configure these below
  static const String API_ENDPATH = "api/v2";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "${PROTOCOL}${DOMAIN_PATH}";
  static const String BASE_URL = "${RAW_BASE_URL}/${API_ENDPATH}";

  // ==============================================================
  // PUSHER (realtime) - same credentials the web version uses.
  // PUSHER_APP_KEY / PUSHER_APP_CLUSTER are public values, they are
  // safe to ship inside the app. The secret key stays on the server.
  // ==============================================================
  static const String PUSHER_APP_KEY = "0a1c36467599289cc0ec";
  static const String PUSHER_APP_CLUSTER = "us2";
  static const bool PUSHER_USE_TLS = true;

  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
}
