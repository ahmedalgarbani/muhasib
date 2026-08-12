import 'dart:developer' as developer;

class AppLogs {
  static void info(String message) {
    developer.log(message, name: 'INFO');
  }

  static void error(String message) {
    developer.log(message, name: 'ERROR', error: message);
  }

  static void warning(String message) {
    developer.log(message, name: 'WARNING');
  }

  static void debug(String message) {
    developer.log(message, name: 'DEBUG');
  }
}
