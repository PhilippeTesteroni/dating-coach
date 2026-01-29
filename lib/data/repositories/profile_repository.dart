import '../api/api_client.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/api/v1/user/profile');
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? gender,
    String? preferredGender,
    int? ageRangeMin,
    int? ageRangeMax,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (gender != null) body['gender'] = gender;
    if (preferredGender != null) body['preferred_gender'] = preferredGender;
    if (ageRangeMin != null) body['age_range_min'] = ageRangeMin;
    if (ageRangeMax != null) body['age_range_max'] = ageRangeMax;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _apiClient.patch('/api/v1/user/profile', data: body);
    return UserProfile.fromJson(response);
  }

  Future<Map<String, String>> getAvatarUploadUrl() async {
    final response = await _apiClient.post('/api/v1/user/avatar/upload-url');
    return {
      'upload_url': response['upload_url'] as String,
      'avatar_url': response['avatar_url'] as String,
    };
  }
}
