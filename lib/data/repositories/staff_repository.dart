import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/user_model.dart';

final staffRepositoryProvider =
    Provider<StaffRepository>((ref) => StaffRepository());

class StaffRepository {
  final Dio _dio;
  StaffRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  Future<List<UserModel>> getAllStaffs() async =>
      responseList(responseData(await _dio.get('admin/staff/all')))
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<List<UserModel>> searchStaff(String query) async =>
      responseList(responseData(await _dio
              .get('admin/staff/search', queryParameters: {'name': query})))
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  String? _iso(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('/');
    return parts.length == 3
        ? '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}'
        : value;
  }

  String? _slash(String? value) {
    final iso = _iso(value);
    if (iso == null) return null;
    final parts = iso.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  Future<UserModel> createStaff(
          {required String username,
          required String firstName,
          required String lastName,
          required String email,
          required String password,
          String? phone,
          String? gender,
          String? dateOfBirth}) async =>
      UserModel.fromJson(Map<String, dynamic>.from(
          responseData(await _dio.post('admin/staff', data: {
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'dateOfBirth': _iso(dateOfBirth),
      }))));
  Future<UserModel> updateStaff(
          {required int id,
          required String firstName,
          required String lastName,
          String? phone,
          String? gender,
          String? dateOfBirth}) async =>
      UserModel.fromJson(Map<String, dynamic>.from(
          responseData(await _dio.put('admin/staff/$id', data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'gender': gender ?? 'OTHER',
        'dateOfBirth': _slash(dateOfBirth),
      }))));
  Future<bool> changeStaffStatus(
      {required int id, required bool isActive}) async {
    responseData(await _dio.patch('admin/staff/$id/status',
        queryParameters: {'status': isActive ? 'ACTIVE' : 'INACTIVE'}));
    return true;
  }

  Future<bool> deleteStaff(int id) async {
    responseData(await _dio.delete('admin/staff/$id'));
    return true;
  }
}
