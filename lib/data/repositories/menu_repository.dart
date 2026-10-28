import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';

class MenuRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<CategoryModel>> getCategories() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.categories);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          final mapped = list.map((e) => CategoryModel.fromJson(e)).toList();
          return [CategoryModel(id: 1, name: 'Tất cả'), ...mapped];
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.categories;
  }

  Future<List<ItemModel>> getItems({int? categoryId, String? search}) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.itemsList,
        queryParameters: {
          if (categoryId != null && categoryId > 1) 'categoryId': categoryId,
          if (search != null && search.isNotEmpty) 'search': search,
          'size': 100,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final pageData = response.data['data'] ?? response.data;
        final list = (pageData['items'] as List?) ?? (pageData['content'] as List?) ?? (pageData as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => ItemModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Filter Mock items
    var result = List<ItemModel>.from(MockData.items);
    if (categoryId != null && categoryId > 1) {
      result = result.where((item) => item.categoryId == categoryId).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase().trim();
      result = result.where((item) => item.name.toLowerCase().contains(q) || item.description.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}
