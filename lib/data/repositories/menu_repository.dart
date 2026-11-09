import 'package:dio/dio.dart';
import '../../core/network/api_response.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';

class MenuRepository {
  final Dio _dio;
  MenuRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  /// Lấy danh sách danh mục (kèm mục 'Tất cả' và 'Set Menu Combo')
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
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
      final response = await _dio.get(
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
      final response = await _dio.get(ApiEndpoints.combos);
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

  /// Tạo món ăn mới (Admin)
  Future<ItemModel> createItem({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    double? priceAfterDiscount,
    required String status,
    required int categoryId,
    String? categoryName,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.items,
        data: {
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
          'price': price,
          if (priceAfterDiscount != null && priceAfterDiscount > 0)
            'priceAfterDiscount': priceAfterDiscount,
          'status': status.toUpperCase(),
          'categoryId': categoryId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          return ItemModel.fromJson(
            Map<String, dynamic>.from(data),
            categoryNameFallback: categoryName,
          );
        }
      }
      throw Exception('Không nhận được dữ liệu món ăn mới từ máy chủ');
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật thông tin món ăn (Admin)
  Future<ItemModel> updateItem(
    int id, {
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    double? priceAfterDiscount,
    required String status,
    required int categoryId,
    String? categoryName,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.itemById(id),
        data: {
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
          'price': price,
          if (priceAfterDiscount != null && priceAfterDiscount > 0)
            'priceAfterDiscount': priceAfterDiscount,
          'status': status.toUpperCase(),
          'categoryId': categoryId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          return ItemModel.fromJson(
            Map<String, dynamic>.from(data),
            categoryNameFallback: categoryName,
          );
        }
      }
      throw Exception('Không thể cập nhật món ăn');
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa món ăn (Admin)
  Future<bool> deleteItem(int id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.itemById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật trạng thái món ăn (AVAILABLE / UNAVAILABLE)
  Future<bool> updateItemStatus(ItemModel item, String newStatus) async {
    if (item.isCombo) {
      final raw = responseData(await _dio.get('combos/${item.id}'));
      if (raw is! Map || raw['id'] != item.id || raw['items'] is! List)
        throw const FormatException('Không tải được chi tiết combo.');
      final data = {
        for (final key in [
          'name',
          'description',
          'imageUrl',
          'price',
          'priceAfterDiscount',
          'items'
        ])
          key: raw[key],
        'status': newStatus
      };
      responseData(await _dio.put('combos/${item.id}', data: data));
      return true;
    }
    try {
      // 1. Thử gọi PATCH /api/items/{id}/status nếu có
      try {
        final patchRes = await _dio.patch(
          ApiEndpoints.itemStatus(item.id),
          queryParameters: {'status': newStatus.toUpperCase()},
          data: {'status': newStatus.toUpperCase()},
        );
        if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
          return true;
        }
      } catch (_) {}

      // 2. Gọi PUT /api/items/{id} chuẩn của ApiItemController
      final putRes = await _dio.put(
        ApiEndpoints.itemById(item.id),
        data: {
          'name': item.name,
          'description': item.description,
          'imageUrl': item.imageUrl,
          'price': item.price,
          if (item.priceAfterDiscount != null)
            'priceAfterDiscount': item.priceAfterDiscount,
          'status': newStatus.toUpperCase(),
          'categoryId': item.categoryId,
        },
      );
      return putRes.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
