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
  return 'Something went wrong. Please try again.';
}
