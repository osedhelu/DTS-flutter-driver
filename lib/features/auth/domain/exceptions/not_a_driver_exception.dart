class NotADriverException implements Exception {
  const NotADriverException();

  @override
  String toString() => 'Solo conductores pueden iniciar sesión en esta app';
}
