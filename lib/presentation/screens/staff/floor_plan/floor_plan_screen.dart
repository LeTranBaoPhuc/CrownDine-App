import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/table_model.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/table_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/table_widget.dart';
import '../reservations/staff_reservation_screen.dart';
import 'table_items_sheet.dart';

class FloorPlanScreen extends ConsumerStatefulWidget {
  const FloorPlanScreen({super.key});
  @override
  ConsumerState<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends ConsumerState<FloorPlanScreen> {
  bool _busy = false;
  bool _mapView = false;
  String? _area;

  Future<void> _refresh() async {
    await ref.read(tableProvider.notifier).loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableProvider);
    final notifier = ref.read(tableProvider.notifier);
    final floorTables =
        state.allTables.where((t) => t.floorId == state.selectedFloorId);
    final areas =
        floorTables.map((t) => t.areaName ?? 'Khu chung').toSet().toList();
    final tables = state.floorTables
        .where((t) => _area == null || (t.areaName ?? 'Khu chung') == _area)
        .toList();
    final blocked = _busy ||
        state.isLoading ||
        state.isUpdating ||
        state.errorMessage != null;
    return Scaffold(
      appBar:
          CrownAppBar(title: 'Sơ đồ bàn & Phục vụ', showCart: false, actions: [
        IconButton(
            tooltip: _mapView ? 'Xem danh sách bàn' : 'Xem vị trí bàn',
            onPressed: () => setState(() => _mapView = !_mapView),
            icon: Icon(_mapView ? Icons.grid_view : Icons.map_outlined)),
        IconButton(
            tooltip: 'Tải lại bàn',
            onPressed: _busy || state.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        if (state.isLoading || _busy || state.isUpdating)
          const LinearProgressIndicator(),
        if (state.errorMessage != null)
          MaterialBanner(content: Text(state.errorMessage!), actions: [
            TextButton(onPressed: _refresh, child: const Text('Thử lại'))
          ]),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final floor in state.floors)
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(floor.name),
                              selected: floor.id == state.selectedFloorId,
                              onSelected: blocked
                                  ? null
                                  : (_) {
                                      notifier.selectFloor(floor.id);
                                      setState(() => _area = null);
                                    })),
                  ])),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    FilterChip(
                        label: const Text('Tất cả bàn'),
                        selected: state.statusFilter == null,
                        onSelected: (_) => notifier.filterByStatus(null)),
                    for (final status in TableStatus.values)
                      Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: FilterChip(
                              label: Text(status.displayName),
                              selected: state.statusFilter == status,
                              onSelected: (_) =>
                                  notifier.filterByStatus(status))),
                  ])),
              if (areas.length > 1)
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      ChoiceChip(
                          label: const Text('Tất cả khu'),
                          selected: _area == null,
                          onSelected: (_) => setState(() => _area = null)),
                      for (final area in areas)
                        Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                                label: Text(area),
                                selected: _area == area,
                                onSelected: (_) =>
                                    setState(() => _area = area))),
                    ])),
            ])),
        Expanded(
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: tables.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                          const SizedBox(height: 90),
                          Center(
                              child: Text(state.isLoading
                                  ? 'Đang tải bàn…'
                                  : state.errorMessage != null
                                      ? 'Chưa tải được dữ liệu bàn.'
                                      : 'Không có bàn phù hợp bộ lọc')),
                        ])
                  : _mapView
                      ? _maps(tables, blocked)
                      : LayoutBuilder(
                          builder: (context, constraints) => GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: math.max(1,
                                          (constraints.maxWidth / 210).floor()),
                                      mainAxisExtent: 180,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12),
                              itemCount: tables.length,
                              itemBuilder: (_, index) => TableWidget(
                                  table: tables[index],
                                  onTap: blocked
                                      ? null
                                      : () => _actions(tables[index]))))),
        ),
      ]),
    );
  }

  Widget _maps(List<TableModel> tables, bool blocked) {
    final areas = tables.map((t) => t.areaName ?? 'Khu chung').toSet();
    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      for (final area in areas)
        Builder(builder: (context) {
          final group =
              tables.where((t) => (t.areaName ?? 'Khu chung') == area).toList();
          final width = group.fold<double>(
              400, (v, t) => math.max(v, t.x + math.max(t.width, 90) + 40));
          final height = group.fold<double>(
              250, (v, t) => math.max(v, t.y + math.max(t.height, 70) + 40));
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('$area • Kéo/chụm để xem sơ đồ')),
                SizedBox(
                    height: 300,
                    child: InteractiveViewer(
                        constrained: false,
                        minScale: 0.3,
                        maxScale: 3,
                        child: SizedBox(
                            width: width,
                            height: height,
                            child: Stack(children: [
                              for (final table in group)
                                Positioned(
                                  left: math.max(0, table.x),
                                  top: math.max(0, table.y),
                                  child: Transform.rotate(
                                      angle: table.rotation * math.pi / 180,
                                      child: SizedBox(
                                          width: math.max(table.width, 90),
                                          height: math.max(table.height, 70),
                                          child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                  backgroundColor: switch (
                                                      table.status) {
                                                    TableStatus.available =>
                                                      Colors.green.withValues(
                                                          alpha: 0.12),
                                                    TableStatus.occupied =>
                                                      Colors.red.withValues(
                                                          alpha: 0.12),
                                                    TableStatus.reserved =>
                                                      Colors.orange.withValues(
                                                          alpha: 0.12),
                                                    TableStatus.unavailable =>
                                                      Colors.grey.withValues(
                                                          alpha: 0.2),
                                                  },
                                                  shape: table.shape == 'ROUND'
                                                      ? const CircleBorder()
                                                      : RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8)),
                                                  padding:
                                                      const EdgeInsets.all(4)),
                                              onPressed: blocked
                                                  ? null
                                                  : () => _actions(table),
                                              child: Text(
                                                  '${table.name}\n${table.status.displayName}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 11))))),
                                ),
                            ])))),
              ]);
        }),
    ]);
  }

  Future<void> _actions(TableModel table) async {
    final action = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: Text(table.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${table.status.displayName} • ${table.capacity} khách\nCọc bàn: ${CurrencyFormatter.format(table.deposit)}')),
              if (table.status == TableStatus.available ||
                  table.status == TableStatus.occupied ||
                  table.status == TableStatus.reserved)
                ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text(table.status == TableStatus.available
                        ? 'Mở bàn & gọi món'
                        : 'Gọi thêm món cho bàn'),
                    onTap: () => Navigator.pop(context, 'items')),
              if (table.status == TableStatus.occupied ||
                  table.status == TableStatus.reserved)
                ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Xem đơn & hóa đơn tạm tính'),
                    onTap: () => Navigator.pop(context, 'bill')),
              ListTile(
                  leading: const Icon(Icons.event_seat),
                  title: const Text('Đặt chỗ & check-in'),
                  subtitle:
                      const Text('Nhận/hủy đặt chỗ qua đúng hồ sơ đặt bàn'),
                  onTap: () => Navigator.pop(context, 'reservations')),
              if (table.status == TableStatus.available)
                ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: const Text('Giữ bàn thủ công'),
                    onTap: () => Navigator.pop(context, 'RESERVED')),
              if (table.status != TableStatus.available)
                ListTile(
                    leading: const Icon(Icons.clean_hands_outlined),
                    title: const Text('Trả bàn trống'),
                    subtitle: const Text(
                        'Chỉ khi không còn đơn/đặt chỗ đang phục vụ'),
                    onTap: () => Navigator.pop(context, 'AVAILABLE')),
              if (table.status == TableStatus.available)
                ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Ngưng phục vụ bàn'),
                    onTap: () => Navigator.pop(context, 'UNAVAILABLE')),
            ]))));
    if (!mounted || action == null) return;
    if (action == 'items') {
      final order = await showModalBottomSheet<OrderModel>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          showDragHandle: false,
          builder: (_) => TableItemsSheet(table: table));
      if (!mounted) return;
      if (order != null) {
        _message('Đã gửi món vào đơn ${order.code}.');
        await _refresh();
        if (mounted) await ref.read(orderProvider.notifier).loadOrders();
      }
    } else if (action == 'reservations') {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StaffReservationScreen()));
      if (mounted) await _refresh();
    } else if (action == 'bill') {
      await _bill(table);
    } else {
      final status = TableStatus.fromString(action);
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text('${table.name}: ${status.displayName}?'),
                  content: const Text(
                      'Máy chủ sẽ kiểm tra đơn và đặt chỗ trước khi cập nhật.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xác nhận'))
                  ]));
      if (!mounted || confirmed != true) return;
      setState(() => _busy = true);
      final ok = await ref
          .read(tableProvider.notifier)
          .updateTableStatus(table.id, status);
      if (!mounted) return;
      setState(() => _busy = false);
      _message(ok
          ? 'Đã cập nhật ${table.name}: ${status.displayName}.'
          : ref.read(tableProvider).errorMessage ?? 'Không cập nhật được bàn.');
    }
  }

  Future<void> _bill(TableModel table) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.getActiveTableOrder(table.id);
      if (!mounted) return;
      if (order == null) {
        _message('Bàn chưa có đơn đang phục vụ.');
        return;
      }
      final quote = await repo.getCheckout(order.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text('${table.name} • ${order.code}'),
                  content: SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            for (final line in order.details)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                      '${line.quantity} × ${line.itemName} • ${line.status.displayName}\n${CurrencyFormatter.format(line.totalPrice)}')),
                            const Divider(),
                            Text(
                                'Tiền món: ${CurrencyFormatter.format(quote['totalAmount'])}'),
                            Text(
                                'Giảm voucher: ${CurrencyFormatter.format(quote['voucherDiscount'])}'),
                            Text(
                                'Cọc món đã trả: ${CurrencyFormatter.format(quote['orderDepositPaidAmount'])}'),
                            Text(
                                'Còn thanh toán: ${CurrencyFormatter.format(quote['finalAmount'])}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Text(
                                'Hóa đơn tạm tính. Thu ngân xác nhận thanh toán trước khi hoàn tất đơn/trả bàn.'),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'))
                  ]));
    } catch (error) {
      if (mounted) _message(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
