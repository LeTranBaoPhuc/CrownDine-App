import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/favorite_model.dart';

class FavoriteRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy danh sách món & combo yêu thích của người dùng hiện tại
  Future<List<FavoriteModel>> getMyFavorites() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.favorites);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null) {
          return list.map((e) => FavoriteModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Thêm món ăn vào yêu thích
  Future<bool> addFavoriteItem(int itemId) async {
    try {
      final response = await _client.dio.post(ApiEndpoints.favoriteItem(itemId));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa món ăn khỏi yêu thích
  Future<bool> removeFavoriteItem(int itemId) async {
    try {
      final response = await _client.dio.delete(ApiEndpoints.favoriteItem(itemId));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm combo vào yêu thích
  Future<bool> addFavoriteCombo(int comboId) async {
    try {
      final response = await _client.dio.post(ApiEndpoints.favoriteCombo(comboId));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa combo khỏi yêu thích
  Future<bool> removeFavoriteCombo(int comboId) async {
    try {
      final response = await _client.dio.delete(ApiEndpoints.favoriteCombo(comboId));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// Kiểm tra xem món ăn đã được yêu thích chưa
  Future<bool> checkFavoriteItem(int itemId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.checkFavoriteItem(itemId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Kiểm tra xem combo đã được yêu thích chưa
  Future<bool> checkFavoriteCombo(int comboId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.checkFavoriteCombo(comboId));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] == true;
      }
    } catch (_) {}
    return false;
  }
}

