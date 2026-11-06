import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';

class MenuRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy danh sách danh mục (kèm mục 'Tất cả' và 'Set Menu Combo')
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.categories);
      if (response.statusCode == 200 && response.data != null) {
        final list =
            (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          final mapped = list
              .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return [
            CategoryModel(id: 0, name: 'Tất cả'),
            ...mapped,
            CategoryModel(
                id: -99,
                name: 'Set Menu Combo',
                description: 'Tiết kiệm và đầy đủ cho nhóm'),
          ];
        }
      }
    } catch (e) {
      rethrow;
    }

    return [
      CategoryModel(id: 0, name: 'Tất cả'),
      CategoryModel(
          id: -99,
          name: 'Set Menu Combo',
          description: 'Tiết kiệm và đầy đủ cho nhóm'),
    ];
  }

  /// Lấy danh sách món ăn từ Backend API (hỗ trợ phân loại, tìm kiếm, sắp xếp)
  Future<List<ItemModel>> getItems({
    int? categoryId,
    String? search,
    String? sortBy,
    String? dir,
    Map<int, String>? categoryNames,
  }) async {
    // 1. Trường hợp chọn riêng danh mục "Set Menu Combo"
    if (categoryId == -99) {
      return await _getCombos(search: search);
    }

    // 2. Gọi API /api/items/list
    final queryParams = <String, dynamic>{
      'page': 1,
      'size': 100,
    };

    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sortBy'] = sortBy;
    }
    if (dir != null && dir.isNotEmpty) {
      queryParams['dir'] = dir;
    }

    try {
      final response = await _client.dio.get(
        ApiEndpoints.itemsList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final pageData = response.data['data'] ?? response.data;
        List? rawList;
        if (pageData is Map) {
          rawList = (pageData['data'] as List?) ??
              (pageData['items'] as List?) ??
              (pageData['content'] as List?);
        } else if (pageData is List) {
          rawList = pageData;
        }

        if (rawList != null) {
          final items = rawList.map((e) {
            final map = Map<String, dynamic>.from(e);
            final catId = (map['categoryId'] is int)
                ? map['categoryId'] as int
                : int.tryParse('${map['categoryId']}');
            final catName = (catId != null && categoryNames != null)
                ? categoryNames[catId]
                : null;
            return ItemModel.fromJson(map, categoryNameFallback: catName);
          }).toList();

          // Nếu chọn "Tất cả" và không lọc theo danh mục, gộp thêm các Combo đặc biệt
          if ((categoryId == null || categoryId == 0) &&
              (search == null || search.isEmpty)) {
            final combos = await _getCombos(search: search);
            items.addAll(combos);
          }

          return items;
        }
      }
    } catch (e) {
      rethrow;
    }

    return [];
  }

  /// Lấy danh sách Combo từ /api/combos
  Future<List<ItemModel>> _getCombos({String? search}) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.combos);
      if (response.statusCode == 200 && response.data != null) {
        final list =
            (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          var mapped = list
              .map((e) => ItemModel.fromJson(
                  {...Map<String, dynamic>.from(e), 'isCombo': true},
                  categoryNameFallback: 'Set Menu Combo'))
              .toList();
          if (search != null && search.trim().isNotEmpty) {
            final q = search.toLowerCase().trim();
            mapped = mapped
                .where((item) =>
                    item.name.toLowerCase().contains(q) ||
                    item.description.toLowerCase().contains(q))
                .toList();
          }
          return mapped;
        }
      }
    } catch (_) {}

    return [];
  }
}
