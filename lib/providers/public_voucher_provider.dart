import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_voucher_model.dart';
import '../data/repositories/admin_voucher_repository.dart';

final adminVoucherRepositoryProvider = Provider<AdminVoucherRepository>((ref) {
  return AdminVoucherRepository();
});

final publicVouchersProvider = FutureProvider.autoDispose<List<AdminVoucherModel>>((ref) async {
  final repo = ref.watch(adminVoucherRepositoryProvider);
  try {
    final page = await repo.list(page: 1, size: 20);
    return page.items;
  } catch (e) {
    return [];
  }
});
