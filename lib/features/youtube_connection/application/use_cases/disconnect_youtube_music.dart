import '../../domain/repositories/youtube_auth_repository.dart';

class DisconnectYouTubeMusic {
  const DisconnectYouTubeMusic(this._repository);

  final YouTubeAuthRepository _repository;

  Future<void> call() => _repository.disconnect();
}
