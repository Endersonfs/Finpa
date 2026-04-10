/// Base class for use cases in the domain layer.
/// Type: return type on success
/// Params: input parameters
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams {
  const NoParams();
}

