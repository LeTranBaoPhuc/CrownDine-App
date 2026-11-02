import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/feedback_model.dart';
import '../../../../widgets/user_avatar.dart';
import '../../feedback/customer_reviews_screen.dart';

class AutoScrollReviewsBanner extends StatefulWidget {
  final List<FeedbackModel> feedbacks;
  final bool isDark;

  const AutoScrollReviewsBanner({
    super.key,
    required this.feedbacks,
    required this.isDark,
  });

  @override
  State<AutoScrollReviewsBanner> createState() => _AutoScrollReviewsBannerState();
}

class _AutoScrollReviewsBannerState extends State<AutoScrollReviewsBanner>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;

  static const double _cardWidth = 300.0;
  static const double _separatorWidth = 14.0;
  static const double _stepWidth = _cardWidth + _separatorWidth; // 314.0 px per card

  // Speed in pixels per second (silk smooth, visible continuous glide)
  static const double _speedPixelsPerSecond = 36.0;

  List<FeedbackModel> get _cycleItems {
    if (widget.feedbacks.isEmpty) return [];
    final list = <FeedbackModel>[];
    // Ensure we have at least 6 items in a single cycle so cycle is wide enough
    while (list.length < 6) {
      list.addAll(widget.feedbacks);
    }
    return list;
  }

  double get _singleCycleWidth => _cycleItems.length * _stepWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _ticker = createTicker((Duration elapsed) {
      if (!mounted || !_scrollController.hasClients || _isUserInteracting) {
        _lastElapsed = elapsed;
        return;
      }

      final deltaSeconds = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      // Skip huge delta frames (e.g. background tab or lag spike)
      if (deltaSeconds <= 0.0 || deltaSeconds > 0.1) return;

      final currentOffset = _scrollController.offset;
      final cycleWidth = _singleCycleWidth;
      final newOffset = currentOffset + (_speedPixelsPerSecond * deltaSeconds);

      if (cycleWidth > 0 && newOffset >= cycleWidth) {
        // Seamlessly reset back by one cycle width
        _scrollController.jumpTo(newOffset - cycleWidth);
      } else {
        _scrollController.jumpTo(newOffset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.feedbacks.isNotEmpty) {
        _ticker.start();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AutoScrollReviewsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedbacks != oldWidget.feedbacks) {
      if (!_ticker.isActive && widget.feedbacks.isNotEmpty) {
        _ticker.start();
      }
    }
  }

  void _onPointerDown() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _onPointerUp() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feedbacks.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đánh giá nào',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    final cycle = _cycleItems;
    // Repeat cycle 3 times to ensure infinite smooth scroll without empty boundaries
    final totalItems = cycle.length * 3;
    final isDark = widget.isDark;

    return Listener(
      onPointerDown: (_) => _onPointerDown(),
      onPointerUp: (_) => _onPointerUp(),
      onPointerCancel: (_) => _onPointerUp(),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.02, 0.98, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: totalItems,
          separatorBuilder: (_, __) => const SizedBox(width: _separatorWidth),
          itemBuilder: (context, index) {
            final fb = cycle[index % cycle.length];
            return _buildFeedbackCard(fb, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel fb, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerReviewsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: _cardWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fb.isFeatured
                ? AppColors.gold.withValues(alpha: 0.6)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: fb.isFeatured ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Rating Stars, Date
            Row(
              children: [
                UserAvatar(
                  avatarUrl: fb.avatarUrl,
                  name: fb.fullName,
                  radius: 17,
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
                              fb.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fb.isFeatured) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 13, color: AppColors.gold),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            fb.shortDate,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (fb.itemId != null || fb.comboId != null)
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (fb.itemName != null && fb.itemName!.isNotEmpty)
                                    ? fb.itemName!
                                    : (fb.comboName != null && fb.comboName!.isNotEmpty)
                                        ? fb.comboName!
                                        : 'Dịch vụ nhà hàng',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: (fb.itemId != null || fb.comboId != null)
                                      ? AppColors.primary
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    fb.rating,
                    (_) => const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Comment Text
            Expanded(
              child: Text(
                '"${fb.comment}"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textLightSecondary : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
