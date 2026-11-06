import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/reward_point_model.dart';
import '../../../../data/repositories/reward_point_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/my_vouchers_provider.dart';

class RewardPointsScreen extends ConsumerStatefulWidget {
  final RewardPointRepository? repository;
  const RewardPointsScreen({super.key, this.repository});

  @override
  ConsumerState<RewardPointsScreen> createState() => _RewardPointsScreenState();
}

class _RewardPointsScreenState extends ConsumerState<RewardPointsScreen> {
  late final RewardPointRepository _repo =
      widget.repository ?? RewardPointRepository();
  List<RewardVoucher> _rewards = const [];
  PointHistoryPage? _history;
  bool _loading = true;
  bool _exchanging = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Không kết nối được máy chủ. Vui lòng thử lại.';
    }
    if (error is FormatException) return error.message;
    if (error is StateError) return error.message;
    return 'Không tải được điểm thưởng. Vui lòng thử lại.';
  }

  Future<void> _load({int historyPage = 1}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rewards = await _repo.rewards();
      final history = await _repo.history(page: historyPage);
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted || request != _request) return;
      setState(() {
        _rewards = rewards;
        _history = history;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  Future<void> _exchange(RewardVoucher reward) async {
    if (_exchanging) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi điểm lấy voucher?'),
        content: Text('Dùng ${reward.pointsRequired} CrownPoints để nhận '
            '${reward.name}. Voucher sẽ xuất hiện trong ví của bạn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận đổi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _exchanging = true);
    try {
      await _repo.exchange(reward.id);
      ref.invalidate(myVouchersProvider);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đổi điểm thành công. Voucher đã có trong ví của bạn.'),
        backgroundColor: AppColors.success,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _exchanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(authProvider).user?.points ?? 0;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('CrownPoints')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Icon(Icons.stars, color: AppColors.gold, size: 36),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Điểm hiện có'),
                        Text('$points CrownPoints',
                            style: Theme.of(context).textTheme.titleLarge),
                      ]),
                ]),
              ),
            ),
          ),
          const TabBar(tabs: [
            Tab(text: 'Đổi voucher'),
            Tab(text: 'Lịch sử điểm'),
          ]),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        OutlinedButton(
                            onPressed: _load, child: const Text('Thử lại')),
                      ]))
                    : TabBarView(children: [
                        RefreshIndicator(
                            onRefresh: _load, child: _rewardList(points)),
                        RefreshIndicator(
                            onRefresh: () =>
                                _load(historyPage: _history?.page ?? 1),
                            child: _historyList()),
                      ]),
          ),
        ]),
      ),
    );
  }

  Widget _rewardList(int points) {
    if (_rewards.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Center(child: Text('Chưa có voucher đổi bằng điểm.')),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        final discount = reward.type == 'PERCENTAGE'
            ? '${reward.discountValue.toStringAsFixed(0)}%'
            : CurrencyFormatter.format(reward.discountValue);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reward.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Giảm $discount · ${reward.pointsRequired} CrownPoints'),
              if (reward.description.isNotEmpty) Text(reward.description),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _exchanging || points < reward.pointsRequired
                      ? null
                      : () => _exchange(reward),
                  child: Text(points < reward.pointsRequired
                      ? 'Chưa đủ điểm'
                      : 'Đổi voucher'),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _historyList() {
    final history = _history;
    if (history == null || history.entries.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Center(child: Text('Chưa có giao dịch điểm.')),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in history.entries)
          Card(
            child: ListTile(
              title: Text(entry.description),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm')
                  .format(entry.createdAt.toLocal())),
              trailing: Text(
                  '${entry.pointsChanged > 0 ? '+' : ''}${entry.pointsChanged}',
                  style: TextStyle(
                      color: entry.pointsChanged >= 0
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        if (history.totalPages > 1)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: history.page <= 1
                    ? null
                    : () => _load(historyPage: history.page - 1),
                icon: const Icon(Icons.chevron_left)),
            Text('Trang ${history.page}/${history.totalPages}'),
            IconButton(
                onPressed: history.page >= history.totalPages
                    ? null
                    : () => _load(historyPage: history.page + 1),
                icon: const Icon(Icons.chevron_right)),
          ]),
      ],
    );
  }
}
