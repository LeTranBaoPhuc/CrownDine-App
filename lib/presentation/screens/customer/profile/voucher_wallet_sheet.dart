import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/my_voucher_model.dart';
import '../../../../providers/my_vouchers_provider.dart';

class VoucherWalletSheet extends ConsumerWidget {
  /// Selection returns a code; the caller must validate it against the real order.
  final bool selectForCheckout;
  const VoucherWalletSheet({super.key, this.selectForCheckout = false});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      ref.invalidate(myVouchersProvider);
      await ref.read(myVouchersProvider.future);
    } catch (_) {
      // The AsyncValue below renders the error and retry action.
    }
  }

  Future<void> _copy(BuildContext context, String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã sao chép mã $code'),
        duration: const Duration(seconds: 2),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không thể sao chép mã. Vui lòng thử lại.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchers = ref.watch(myVouchersProvider);
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.confirmation_number_outlined,
                color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    selectForCheckout ? 'Chọn voucher' : 'Ví voucher của tôi',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(
                tooltip: 'Làm mới voucher',
                onPressed: vouchers.isLoading ? null : () => _refresh(ref),
                icon: const Icon(Icons.refresh)),
            IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          Text(selectForCheckout
              ? 'Chọn mã để kiểm tra điều kiện và áp dụng cho đơn hiện tại.'
              : 'Voucher còn hạn và còn lượt sử dụng. Sao chép mã để dùng khi đặt món.'),
          const SizedBox(height: 16),
          Expanded(
              child: vouchers.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text(myVouchersError(error), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () => _refresh(ref), child: const Text('Thử lại')),
            ])),
            data: (items) => RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                          SizedBox(height: 48),
                          Icon(Icons.local_offer_outlined, size: 48),
                          SizedBox(height: 16),
                          Text('Bạn chưa có voucher khả dụng.',
                              textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text('Kéo xuống để cập nhật ưu đãi mới.',
                              textAlign: TextAlign.center),
                        ])
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _card(context, items[index]),
                    ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _card(BuildContext context, MyVoucherModel voucher) {
    final discount = voucher.type == MyVoucherType.percentage
        ? '${NumberFormat('0.##').format(voucher.discountValue)}%'
        : CurrencyFormatter.format(voucher.discountValue);
    final remaining = voucher.remainingUses;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Giảm $discount',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(voucher.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(voucher.code,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (voucher.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(voucher.description),
          ],
          const SizedBox(height: 10),
          Text(voucher.minValue == null || voucher.minValue == 0
              ? 'Không yêu cầu giá trị đơn tối thiểu'
              : 'Đơn từ ${CurrencyFormatter.format(voucher.minValue!)}'),
          if (voucher.maxDiscountValue != null)
            Text(
                'Giảm tối đa ${CurrencyFormatter.format(voucher.maxDiscountValue!)}'),
          Text(voucher.expiredAt == null
              ? 'Không giới hạn thời hạn'
              : 'Hạn dùng: ${DateFormat('dd/MM/yyyy HH:mm').format(voucher.expiredAt!)}'),
          Text(remaining == null
              ? 'Không giới hạn lượt dùng'
              : 'Còn $remaining lượt sử dụng'),
          if (!voucher.isAvailable)
            const Text(
                'Voucher đã hết hạn hoặc hết lượt. Vui lòng làm mới danh sách.'),
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: !voucher.isAvailable
                    ? null
                    : () {
                        // Recheck expiry at tap time in case the sheet was left open.
                        if (!voucher.isAvailable) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Voucher không còn khả dụng. Vui lòng làm mới danh sách.')));
                          return;
                        }
                        if (selectForCheckout) {
                          Navigator.pop(context, voucher.code);
                        } else {
                          _copy(context, voucher.code);
                        }
                      },
                icon: Icon(selectForCheckout ? Icons.check : Icons.copy,
                    size: 18),
                label: Text(selectForCheckout ? 'Áp dụng' : 'Sao chép mã'),
              )),
        ]),
      ),
    );
  }
}
