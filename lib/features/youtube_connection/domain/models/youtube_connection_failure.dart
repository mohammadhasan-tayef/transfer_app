enum YouTubeConnectionFailureType {
  cancelled,
  noInternet,
  timeout,
  configuration,
  authenticationFailed,
  validationFailed,
  rateLimited,
  serverError,
  malformedResponse,
  unknown,
}

class YouTubeConnectionFailure {
  const YouTubeConnectionFailure(this.type, {this.httpStatus});

  final YouTubeConnectionFailureType type;
  final int? httpStatus;
}
