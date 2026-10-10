sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiNotFound extends ApiException {
  const ApiNotFound(super.message);
}

class ApiOffline extends ApiException {
  const ApiOffline()
      : super('No internet connection. Check your network and try again.');
}

class ApiServerAsleep extends ApiException {
  const ApiServerAsleep()
      : super(
          'The university server is waking up. The first request can take about a minute. Try again.',
        );
}

class ApiUnknown extends ApiException {
  const ApiUnknown(super.message);
}

String describeError(Object error) {
  if (error is ApiException) return error.message;
  if (error is StateError && error.message.isNotEmpty) return error.message;
  final text = '$error'.toLowerCase();
  if (text.contains('permission-denied') || text.contains('permission_denied')) {
    return 'This action is not allowed yet. Publish the latest Firestore rules, then try again.';
  }
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('unavailable') ||
      text.contains('failed host lookup')) {
    return 'No internet connection. Check your network and try again.';
  }
  return 'Something went wrong. Please try again.';
}
