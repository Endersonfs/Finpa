abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => runtimeType.hashCode ^ message.hashCode;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network Connection Error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local Cache Error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication Error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected Error']);
}
