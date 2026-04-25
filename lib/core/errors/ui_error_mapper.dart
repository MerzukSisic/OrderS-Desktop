import 'package:rs2_desktop/core/errors/ui_error.dart';

class UiErrorMapper {
  static const String _defaultFallback =
      'Something went wrong. Please try again.';

  static UiError fromRaw(String? raw, {String fallback = _defaultFallback}) {
    if (raw == null || raw.trim().isEmpty) {
      return UiError(userMessage: fallback, technicalMessage: raw);
    }

    final normalized = raw.trim();
    final lower = normalized.toLowerCase();

    if (_containsAny(lower, ['timeout', 'timed out'])) {
      return UiError(
        userMessage: 'Request timed out. Please try again.',
        technicalMessage: normalized,
      );
    }

    if (_containsAny(lower, ['unauthorized', '401', 'session expired'])) {
      return UiError(
        userMessage: 'Your session has expired. Please log in again.',
        technicalMessage: normalized,
      );
    }

    if (_containsAny(lower, ['forbidden', '403'])) {
      return UiError(
        userMessage: 'You do not have permission to perform this action.',
        technicalMessage: normalized,
      );
    }

    if (_containsAny(lower, ['not found', '404'])) {
      return UiError(
        userMessage: 'The requested data was not found.',
        technicalMessage: normalized,
      );
    }

    if (_containsAny(lower, [
      'cannot connect',
      'connection error',
      'socketexception',
      'network error',
      'failed host lookup',
      'backend',
      'docker',
      'connection refused',
    ])) {
      return UiError(
        userMessage: 'Cannot reach the server right now. Please try again.',
        technicalMessage: normalized,
      );
    }

    if (_containsAny(lower, ['bad request', 'validation', 'invalid'])) {
      return UiError(
        userMessage: 'Please check your input and try again.',
        technicalMessage: normalized,
      );
    }

    // Keep already-friendly messages but strip common technical prefixes.
    final cleaned = normalized
        .replaceFirst(
          RegExp(r'^(exception:|error:)\s*', caseSensitive: false),
          '',
        )
        .trim();
    if (cleaned.length <= 140 &&
        !_containsAny(cleaned.toLowerCase(), ['http://', 'https://', ' at '])) {
      return UiError(userMessage: cleaned, technicalMessage: normalized);
    }

    return UiError(userMessage: fallback, technicalMessage: normalized);
  }

  static UiError fromException(
    Object error, {
    String fallback = _defaultFallback,
  }) {
    return fromRaw(error.toString(), fallback: fallback);
  }

  static String userMessageFromRaw(
    String? raw, {
    String fallback = _defaultFallback,
  }) {
    return fromRaw(raw, fallback: fallback).userMessage;
  }

  static bool _containsAny(String source, List<String> patterns) {
    for (final pattern in patterns) {
      if (source.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
}
