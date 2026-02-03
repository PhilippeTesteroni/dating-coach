import '../api/api_client.dart';
import '../models/character.dart';

/// Репозиторий для работы с персонажами
class CharactersRepository {
  final ApiClient _apiClient;

  CharactersRepository(this._apiClient);

  /// Получить список персонажей
  /// [preferredGender] — фильтр: 'male', 'female', 'all'
  Future<List<Character>> getCharacters({String? preferredGender}) async {
    final queryParams = <String, dynamic>{};
    if (preferredGender != null) {
      queryParams['preferred_gender'] = preferredGender;
    }

    final response = await _apiClient.get(
      '/api/v1/characters',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final characters = (response['characters'] as List)
        .map((json) => Character.fromJson(json as Map<String, dynamic>))
        .toList();

    return characters;
  }
}
