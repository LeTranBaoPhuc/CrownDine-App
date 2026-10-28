import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../data/models/item_model.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../widgets/write_feedback_sheet.dart';

class MenuDetailSheet extends ConsumerStatefulWidget {
  final ItemModel item;

  const MenuDetailSheet({super.key, required this.item});

  @override
  ConsumerState<MenuDetailSheet> createState() => _MenuDetailSheetState();
}

class _MenuDetailSheetState extends ConsumerState<MenuDetailSheet> {
  int _quantity = 1;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = item.displayPrice * _quantity;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with rating
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          item.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: AppColors.lightSurface,
                            child: const Icon(Icons.restaurant, size: 60, color: AppColors.primary),
                          ),
                        ),
                        if (item.tags.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.tags.first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.categoryName != null)
                              Text(
                                item.categoryName!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${item.averageRating} (${item.feedbackCount})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(item.displayPrice),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (item.priceAfterDiscount != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.format(item.price),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Mô tả món ăn',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Note text field
                  const Text(
                    'Ghi chú cho đầu bếp',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Không hành, sốt để riêng, ít cay...',
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Reviews & Feedback Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đánh giá & Bình luận',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nhận xét từ thực khách đã thưởng thức',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Viết đánh giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          WriteFeedbackSheet.show(
                            context,
                            itemId: item.id,
                            itemName: item.name,
                            onSuccess: () => ref.invalidate(itemFeedbacksProvider(item.id)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Feedbacks List
                  ref.watch(itemFeedbacksProvider(item.id)).when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Không thể tải bình luận lúc này.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        data: (feedbacks) {
                          if (feedbacks.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.rate_review_outlined, size: 36, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Chưa có đánh giá nào cho món này',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hãy là người đầu tiên trải nghiệm và để lại nhận xét!',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Overall Rating Summary Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${item.averageRating}',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < item.averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                              size: 16,
                                              color: AppColors.gold,
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${feedbacks.length} nhận xét',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    const VerticalDivider(width: 1),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Trải nghiệm ẩm thực',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '100% đánh giá xác thực từ thực khách dùng bữa tại CrownDine.',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Review list items
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: feedbacks.length,
                                separatorBuilder: (_, __) => const Divider(height: 20),
                                itemBuilder: (context, i) {
                                  final fb = feedbacks[i];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ClipOval(
                                            child: (fb.avatarUrl != null && fb.avatarUrl!.isNotEmpty)
                                                ? Image.network(
                                                    ImageUtils.getSafeImageUrl(fb.avatarUrl),
                                                    width: 36,
                                                    height: 36,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      width: 36,
                                                      height: 36,
                                                      color: AppColors.primary.withOpacity(0.15),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        fb.fullName.isNotEmpty ? fb.fullName[0].toUpperCase() : 'K',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 36,
                                                    height: 36,
                                                    color: AppColors.primary.withOpacity(0.15),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      fb.fullName.isNotEmpty ? fb.fullName[0].toUpperCase() : 'K',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      fb.fullName,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.gold.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'Thành viên',
                                                        style: TextStyle(color: AppColors.goldDark, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  fb.createdAt,
                                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (starIdx) {
                                              return Icon(
                                                starIdx < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                                size: 15,
                                                color: AppColors.gold,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        fb.comment,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: isDark ? AppColors.textLightPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),


          // Bottom Bar with Quantity & Add to Cart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add Button with calculated price
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(
                            item,
                            quantity: _quantity,
                            note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm $_quantity x ${item.name} vào giỏ!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Thêm • ${CurrencyFormatter.format(total)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
