import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/feedback_model.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/user_avatar.dart';

class CustomerReviewsScreen extends ConsumerStatefulWidget {
  const CustomerReviewsScreen({super.key});

  @override
  ConsumerState<CustomerReviewsScreen> createState() => _CustomerReviewsScreenState();
}

class _CustomerReviewsScreenState extends ConsumerState<CustomerReviewsScreen> {
  int? _selectedStarFilter; // null = Tất cả, 5, 4, 3, 2, 1
  bool _onlyFeatured = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feedbacksAsync = ref.watch(allFeedbacksProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100E0C) : const Color(0xFFF9FAFB),
      appBar: const CrownAppBar(
        title: 'Đánh giá & Trải nghiệm',
        showCart: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(allFeedbacksProvider);
        },
        child: feedbacksAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 14),
                Text('Đang tải đánh giá từ thực khách...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải danh sách đánh giá',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(allFeedbacksProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (allFeedbacks) {
            // Apply star filter
            var displayList = allFeedbacks;
            if (_selectedStarFilter != null) {
              displayList = displayList.where((f) => f.rating == _selectedStarFilter).toList();
            }
            if (_onlyFeatured) {
              displayList = displayList.where((f) => f.isFeatured).toList();
            }

            // Calculate statistics
            final totalCount = allFeedbacks.length;
            final double avgRating = totalCount > 0
                ? (allFeedbacks.map((e) => e.rating).reduce((a, b) => a + b) / totalCount)
                : 5.0;

            final starCounts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
            for (var f in allFeedbacks) {
              starCounts[f.rating] = (starCounts[f.rating] ?? 0) + 1;
            }

            return CustomScrollView(
              slivers: [
                // 1. Rating Summary Scoreboard Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildRatingScoreboard(
                      avgRating: avgRating,
                      totalCount: totalCount,
                      starCounts: starCounts,
                      isDark: isDark,
                    ),
                  ),
                ),

                // 2. Star Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả (${allFeedbacks.length})',
                          isSelected: _selectedStarFilter == null && !_onlyFeatured,
                          onTap: () => setState(() {
                            _selectedStarFilter = null;
                            _onlyFeatured = false;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '5 ★ (${starCounts[5] ?? 0})',
                          isSelected: _selectedStarFilter == 5 && !_onlyFeatured,
                          onTap: () => setState(() {
                            _selectedStarFilter = 5;
                            _onlyFeatured = false;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '4 ★ (${starCounts[4] ?? 0})',
                          isSelected: _selectedStarFilter == 4 && !_onlyFeatured,
                          onTap: () => setState(() {
                            _selectedStarFilter = 4;
                            _onlyFeatured = false;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: '3 ★ (${starCounts[3] ?? 0})',
                          isSelected: _selectedStarFilter == 3 && !_onlyFeatured,
                          onTap: () => setState(() {
                            _selectedStarFilter = 3;
                            _onlyFeatured = false;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Đặc sắc / Nổi bật',
                          isSelected: _onlyFeatured,
                          onTap: () => setState(() {
                            _onlyFeatured = !_onlyFeatured;
                            _selectedStarFilter = null;
                          }),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Feedback list or Empty state
                if (displayList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có đánh giá nào phù hợp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hãy thử chọn bộ lọc khác để xem thêm cảm nhận từ thực khách',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = displayList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFeedbackCard(item, isDark),
                          );
                        },
                        childCount: displayList.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingScoreboard({
    required double avgRating,
    required int totalCount,
    required Map<int, int> starCounts,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Big Score
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalCount lượt đánh giá',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(width: 20),
          Container(
            width: 1,
            height: 90,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(width: 20),

          // Right: Star breakdown progress bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = starCounts[star] ?? 0;
                final double ratio = totalCount > 0 ? (count / totalCount) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text(
                        '$star★',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: isDark ? const Color(0xFF2B2623) : const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isFeatured
              ? AppColors.gold.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: item.isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Stars, Date
          Row(
            children: [
              UserAvatar(
                avatarUrl: item.avatarUrl,
                name: item.fullName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isFeatured) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 10, color: AppColors.gold),
                                SizedBox(width: 2),
                                Text(
                                  'Nổi bật',
                                  style: TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.shortDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (star) => Icon(
                    star < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment body
          Text(
            item.comment,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? AppColors.textLight : const Color(0xFF374151),
            ),
          ),

          // Target tag (if reviewed for specific item or combo)
          if (item.itemId != null || item.comboId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26201B) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    item.itemId != null ? 'Đánh giá món ăn #${item.itemId}' : 'Đánh giá Combo #${item.comboId}',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
