abstract interface class YouTubeAuthorizationProvider {
  Future<Map<String, String>?> authorizationHeaders();
}
