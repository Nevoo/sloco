class DeepLException implements Exception {
  final String message;
  final StackTrace stackTrace;

  const DeepLException(
    this.message, {
    required this.stackTrace,
  });
}
