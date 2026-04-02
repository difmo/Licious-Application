import 'package:logger/logger.dart';

/// Centralized Logger utility for the project.
/// Use this instead of print() or debugPrint() for consistency.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat: DateTimeFormat.dateAndTime, // Should each log print contain a timestamp
    ),
  );

  /// Log a message at level [Level.debug].
  static void d(String message) => _logger.d(message);

  /// Log a message at level [Level.info].
  static void i(String message) => _logger.i(message);

  /// Log a message at level [Level.warning].
  static void w(String message) => _logger.w(message);

  /// Log a message at level [Level.error].
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Log a message at level [Level.trace].
  static void t(String message) => _logger.t(message);

  /// Log a message at level [Level.fatal].
  static void f(String message) => _logger.f(message);
}
