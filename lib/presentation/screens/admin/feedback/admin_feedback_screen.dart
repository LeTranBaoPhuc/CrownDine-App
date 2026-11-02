import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/feedback_model.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../widgets/crown_app_bar.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedRatingFilter;
  bool _onlyFeatured = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feedbacksAsync = ref.watch(allFeedbacksProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100E0C) : const Color(0xFFF9FAFB),
      appBar: const CrownAppBar(
        title: 'Quản lý Đánh giá & Phản hồi',
        showCart: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(allFeedbacksProvider);
        },
        child: feedbacksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  const Text('Không thể tải dữ liệu đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('$err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(allFeedbacksProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (allList) {
            final query = _searchController.text.toLowerCase().trim();

            // Filter
            final filtered = allList.where((f) {
              if (_selectedRatingFilter != null && f.rating != _selectedRatingFilter) {
                return false;
              }
              if (_onlyFeatured && !f.isFeatured) {
                return false;
              }
              if (query.isNotEmpty) {
                final matchName = f.fullName.toLowerCase().contains(query);
                final matchComment = f.comment.toLowerCase().contains(query);
                return matchName || matchComment;
              }
              return true;
            }).toList();

            // KPI calculations
            final total = allList.length;
            final avgScore = total > 0
                ? (allList.map((e) => e.rating).reduce((a, b) => a + b) / total)
                : 5.0;
            final positiveCount = allList.where((f) => f.rating >= 4).length;
            final positiveRate = total > 0 ? ((positiveCount / total) * 100).round() : 100;
            final attentionCount = allList.where((f) => f.rating <= 2).length;

            return CustomScrollView(
              slivers: [
                // 1. KPI Cards Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Tổng đánh giá',
                            value: '$total',
                            icon: Icons.reviews_outlined,
                            iconColor: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Điểm trung bình',
                            value: '${avgScore.toStringAsFixed(1)} ★',
                            icon: Icons.star_rounded,
                            iconColor: AppColors.gold,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Tỷ lệ hài lòng',
                            value: '$positiveRate%',
                            icon: Icons.thumb_up_outlined,
                            iconColor: AppColors.success,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Cần chú ý',
                            value: '$attentionCount',
                            icon: Icons.priority_high_rounded,
                            iconColor: attentionCount > 0 ? AppColors.warning : AppColors.textSecondary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên khách, từ khóa nhận xét...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Tất cả ($total)', _selectedRatingFilter == null && !_onlyFeatured, () {
                                setState(() {
                                  _selectedRatingFilter = null;
                                  _onlyFeatured = false;
                                });
                              }, isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip('5 ★ (${allList.where((f) => f.rating == 5).length})', _selectedRatingFilter == 5, () {
                                setState(() {
                                  _selectedRatingFilter = 5;
                                  _onlyFeatured = false;
                                });
                              }, isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip('4 ★ (${allList.where((f) => f.rating == 4).length})', _selectedRatingFilter == 4, () {
                                setState(() {
                                  _selectedRatingFilter = 4;
                                  _onlyFeatured = false;
                                });
                              }, isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip('3 ★ (${allList.where((f) => f.rating == 3).length})', _selectedRatingFilter == 3, () {
                                setState(() {
                                  _selectedRatingFilter = 3;
                                  _onlyFeatured = false;
                                });
                              }, isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip('1-2 ★ (${allList.where((f) => f.rating <= 2).length})', _selectedRatingFilter == 2, () {
                                setState(() {
                                  _selectedRatingFilter = 2;
                                  _onlyFeatured = false;
                                });
                              }, isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip('Được ghim nổi bật', _onlyFeatured, () {
                                setState(() {
                                  _onlyFeatured = !_onlyFeatured;
                                  _selectedRatingFilter = null;
                                });
                              }, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Feedback list
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('Không có phản hồi nào phù hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAdminFeedbackCard(item, isDark),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminFeedbackCard(FeedbackModel item, bool isDark) {
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: User Avatar, Name, Rating Stars, Date
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                    ? NetworkImage(item.avatarUrl!)
                    : null,
                child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                    ? Text(
                        item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'K',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
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
                            child: const Text('Ghim', style: TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.formattedDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (item.rating >= 4 ? AppColors.success : (item.rating == 3 ? AppColors.warning : AppColors.error))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: item.rating >= 4 ? AppColors.success : (item.rating == 3 ? AppColors.warning : AppColors.error)),
                    const SizedBox(width: 2),
                    Text(
                      '${item.rating}.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.rating >= 4 ? AppColors.success : (item.rating == 3 ? AppColors.warning : AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment content
          Text(
            item.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? AppColors.textLight : const Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Bottom Tags & Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (item.itemId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF26201B) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Món #${item.itemId}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  if (item.comboId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF26201B) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Combo #${item.comboId}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  if (item.orderId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF26201B) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Đơn #${item.orderId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                ],
              ),
              if (item.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status!,
                    style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
