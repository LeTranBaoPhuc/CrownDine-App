import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../data/repositories/admin_setup_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/menu_provider.dart';
import '../../../../providers/table_provider.dart';

final adminSetupRepositoryProvider = Provider((ref) => AdminSetupRepository());

extension SetupLabel on SetupKind {
  String get label => switch (this) {
        SetupKind.category => 'Danh mục món',
        SetupKind.combo => 'Combo',
        SetupKind.floor => 'Tầng',
        SetupKind.area => 'Khu vực',
        SetupKind.table => 'Bàn ăn',
        SetupKind.shift => 'Ca làm việc',
      };
  IconData get icon => switch (this) {
        SetupKind.category => Icons.category_outlined,
        SetupKind.combo => Icons.dinner_dining,
        SetupKind.floor => Icons.layers_outlined,
        SetupKind.area => Icons.grid_view,
        SetupKind.table => Icons.table_restaurant,
        SetupKind.shift => Icons.schedule,
      };
}

class AdminSetupScreen extends ConsumerWidget {
  const AdminSetupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authProvider).isAdmin)
      return const Scaffold(
          body: Center(child: Text('Yêu cầu quyền quản trị viên.')));
    return Scaffold(
        appBar: AppBar(title: const Text('Thiết lập nhà hàng')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Quản lý thực đơn, không gian phục vụ và ca làm việc.')),
          for (final kind in [
            SetupKind.category,
            SetupKind.combo,
            SetupKind.floor,
            SetupKind.shift
          ])
            Card(
                child: ListTile(
                    leading: Icon(kind.icon),
                    title: Text(kind == SetupKind.floor
                        ? 'Tầng, khu vực & bàn ăn'
                        : kind.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SetupListScreen(kind: kind))))),
        ]));
  }
}

class SetupListScreen extends ConsumerStatefulWidget {
  final SetupKind kind;
  final int? floorId, parentId;
  final String? parentName;
  const SetupListScreen(
      {super.key,
      required this.kind,
      this.floorId,
      this.parentId,
      this.parentName});
  @override
  ConsumerState<SetupListScreen> createState() => _SetupListState();
}

class _SetupListState extends ConsumerState<SetupListScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(adminSetupRepositoryProvider)
          .list(widget.kind, floorId: widget.floorId, areaId: widget.parentId);
      if (mounted)
        setState(() {
          _rows = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e);
        });
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final items = widget.kind == SetupKind.combo
          ? await ref.read(adminSetupRepositoryProvider).items()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => SetupEditScreen(
                  kind: widget.kind,
                  row: row,
                  items: items,
                  parentId: widget.parentId)));
      if (saved == true && mounted) {
        ref.invalidate(menuProvider);
        ref.invalidate(tableProvider);
        await _load();
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Xóa ${row['name']}?'),
                content: const Text(
                    'Dữ liệu đang được sử dụng có thể không xóa được. Với món/combo hoặc bàn đang phục vụ, hãy đổi sang ngưng phục vụ.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Giữ lại')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminSetupRepositoryProvider)
          .delete(widget.kind, row['id'] as int);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _children(Map<String, dynamic> row) {
    final floor = widget.kind == SetupKind.floor;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SetupListScreen(
                kind: floor ? SetupKind.area : SetupKind.table,
                floorId: floor ? row['id'] as int : widget.floorId,
                parentId: row['id'] as int,
                parentName: row['name'] as String)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.kind.label}${widget.parentName == null ? '' : ' · ${widget.parentName}'}'),
          actions: [
            IconButton(
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.refresh))
          ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy || _loading ? null : () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm mới')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null)
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(children: [
                                Text(_error!),
                                TextButton(
                                    onPressed: _load,
                                    child: const Text('Thử lại'))
                              ]))),
                    if (_rows.isEmpty && _error == null)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'Chưa có dữ liệu. Nhấn Thêm mới để bắt đầu.')),
                    for (final row in _rows)
                      Card(
                          child: ListTile(
                        leading: Icon(widget.kind.icon),
                        title: Text('${row['name']}'),
                        subtitle: Text(widget.kind == SetupKind.shift
                            ? '${row['startTime']} – ${row['endTime']}'
                            : widget.kind == SetupKind.table
                                ? '${row['capacity']} chỗ · ${row['status']}'
                                : '${row['description'] ?? ''}'),
                        onTap: _busy
                            ? null
                            : () => widget.kind == SetupKind.floor ||
                                    widget.kind == SetupKind.area
                                ? _children(row)
                                : _edit(row),
                        trailing: PopupMenuButton<String>(
                            enabled: !_busy,
                            onSelected: (value) =>
                                value == 'edit' ? _edit(row) : _delete(row),
                            itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Chỉnh sửa')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Xóa'))
                                ]),
                      )),
                  ])));
}

class _Field {
  final String key, label, initial;
  final bool required, integer;
  final num? min;
  const _Field(this.key, this.label,
      {this.initial = '',
      this.required = false,
      this.integer = false,
      this.min});
}

class SetupEditScreen extends ConsumerStatefulWidget {
  final SetupKind kind;
  final Map<String, dynamic>? row;
  final List<Map<String, dynamic>> items;
  final int? parentId;
  const SetupEditScreen(
      {super.key,
      required this.kind,
      this.row,
      this.items = const [],
      this.parentId});
  @override
  ConsumerState<SetupEditScreen> createState() => _SetupEditState();
}

class _SetupEditState extends ConsumerState<SetupEditScreen> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  final Map<int, TextEditingController> _quantities = {};
  late List<_Field> _definitions;
  String _status = 'AVAILABLE', _shape = 'RECT';
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _definitions = [
      const _Field('name', 'Tên', required: true),
      if (widget.kind != SetupKind.shift) const _Field('description', 'Mô tả'),
      if (widget.kind == SetupKind.floor)
        const _Field('floorNumber', 'Số tầng',
            initial: '1', integer: true, required: true),
      if (widget.kind == SetupKind.shift) ...[
        const _Field('startTime', 'Giờ bắt đầu (HH:mm)', required: true),
        const _Field('endTime', 'Giờ kết thúc (HH:mm)', required: true)
      ],
      if (widget.kind == SetupKind.combo) ...[
        const _Field('price', 'Giá (đ)', required: true, min: 0),
        const _Field('priceAfterDiscount', 'Giá sau giảm (đ)', min: 0),
        const _Field('imageUrl', 'URL hình ảnh')
      ],
      if (widget.kind == SetupKind.table) ...[
        const _Field('capacity', 'Sức chứa',
            initial: '4', required: true, integer: true, min: 1),
        const _Field('deposit', 'Cọc giữ bàn (đ)',
            initial: '0', required: true, min: 0),
        const _Field('x', 'Vị trí X',
            initial: '0', required: true, integer: true, min: 0),
        const _Field('y', 'Vị trí Y',
            initial: '0', required: true, integer: true, min: 0),
        const _Field('width', 'Chiều rộng',
            initial: '100', required: true, integer: true, min: 20),
        const _Field('height', 'Chiều cao',
            initial: '80', required: true, integer: true, min: 20),
        const _Field('rotation', 'Góc xoay (độ)', initial: '0', integer: true),
        const _Field('imageUrl', 'URL hình ảnh'),
      ]
    ];
    for (final f in _definitions) {
      var value = widget.row?[f.key]?.toString() ?? f.initial;
      if (widget.kind == SetupKind.shift &&
          f.key.endsWith('Time') &&
          value.length >= 5) value = value.substring(0, 5);
      _fields[f.key] = TextEditingController(text: value);
    }
    _status = widget.row?['status'] as String? ?? 'AVAILABLE';
    _shape = widget.row?['shape'] as String? ?? 'RECT';
    for (final line in widget.row?['items'] as List? ?? []) {
      _quantities[line['itemId'] as int] =
          TextEditingController(text: '${line['quantity']}');
    }
  }

  @override
  void dispose() {
    for (final controller in [..._fields.values, ..._quantities.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final data = <String, dynamic>{};
    for (final field in _definitions) {
      final value = _fields[field.key]!.text.trim();
      data[field.key] = value.isEmpty
          ? null
          : field.integer
              ? int.parse(value)
              : field.min != null
                  ? num.parse(value)
                  : value;
    }
    if (widget.kind == SetupKind.shift &&
        (data['startTime'] as String).compareTo(data['endTime'] as String) >=
            0) {
      setState(() => _error = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }
    if (widget.kind == SetupKind.combo) {
      if (_quantities.isEmpty) {
        setState(() => _error = 'Combo cần ít nhất một món.');
        return;
      }
      if (data['priceAfterDiscount'] != null &&
          data['priceAfterDiscount'] > data['price']) {
        setState(() => _error = 'Giá sau giảm không được lớn hơn giá gốc.');
        return;
      }
      data['status'] = _status;
      data['items'] = _quantities.entries
          .map((e) => {'itemId': e.key, 'quantity': int.parse(e.value.text)})
          .toList();
    }
    if (widget.kind == SetupKind.table) data['shape'] = _shape;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminSetupRepositoryProvider).save(widget.kind, data,
          id: widget.row?['id'] as int?, parentId: widget.parentId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: Scaffold(
          appBar: AppBar(
              title: Text(
                  '${widget.row == null ? 'Thêm' : 'Sửa'} ${widget.kind.label.toLowerCase()}')),
          body: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                if (_saving) const LinearProgressIndicator(),
                for (final field in _definitions)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                          controller: _fields[field.key],
                          enabled: !_saving,
                          decoration: InputDecoration(labelText: field.label),
                          keyboardType: field.min != null || field.integer
                              ? const TextInputType.numberWithOptions(
                                  decimal: true, signed: true)
                              : TextInputType.text,
                          validator: (raw) {
                            final value = raw?.trim() ?? '';
                            if (value.isEmpty)
                              return field.required
                                  ? 'Vui lòng nhập ${field.label.toLowerCase()}.'
                                  : null;
                            if (field.integer || field.min != null) {
                              final number = field.integer
                                  ? int.tryParse(value)
                                  : num.tryParse(value);
                              if (number == null ||
                                  !number.isFinite ||
                                  (field.min != null && number < field.min!))
                                return 'Giá trị không hợp lệ.';
                            }
                            if (field.key.endsWith('Time') &&
                                !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                                    .hasMatch(value))
                              return 'Dùng định dạng HH:mm.';
                            return null;
                          })),
                if (widget.kind == SetupKind.table)
                  DropdownButtonFormField<String>(
                      initialValue: _shape,
                      decoration:
                          const InputDecoration(labelText: 'Hình dạng bàn'),
                      items: const [
                        DropdownMenuItem(
                            value: 'RECT', child: Text('Chữ nhật')),
                        DropdownMenuItem(value: 'CIRCLE', child: Text('Tròn')),
                        DropdownMenuItem(value: 'SQUARE', child: Text('Vuông'))
                      ],
                      onChanged: _saving ? null : (v) => _shape = v!),
                if (widget.kind == SetupKind.combo) ...[
                  DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration:
                          const InputDecoration(labelText: 'Trạng thái'),
                      items: const [
                        DropdownMenuItem(
                            value: 'AVAILABLE', child: Text('Đang phục vụ')),
                        DropdownMenuItem(
                            value: 'UNAVAILABLE', child: Text('Ngưng phục vụ'))
                      ],
                      onChanged: _saving ? null : (v) => _status = v!),
                  const SizedBox(height: 20),
                  Text('Món trong combo',
                      style: Theme.of(context).textTheme.titleMedium),
                  for (final entry in _quantities.entries)
                    Row(children: [
                      Expanded(
                          child: Text(widget.items
                                  .where((i) => i['id'] == entry.key)
                                  .firstOrNull?['name']
                                  ?.toString() ??
                              'Món #${entry.key}')),
                      SizedBox(
                          width: 80,
                          child: TextFormField(
                              controller: entry.value,
                              enabled: !_saving,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'SL'),
                              validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                                  ? null
                                  : 'SL > 0')),
                      IconButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  final c = _quantities.remove(entry.key);
                                  setState(() {});
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => c?.dispose());
                                },
                          icon: const Icon(Icons.remove_circle_outline))
                    ]),
                  DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Thêm món vào combo'),
                      items: widget.items
                          .where((i) => !_quantities.containsKey(i['id']))
                          .map((i) => DropdownMenuItem(
                              value: i['id'] as int,
                              child: Text('${i['name']}')))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (id) {
                              if (id != null)
                                setState(() => _quantities[id] =
                                    TextEditingController(text: '1'));
                            }),
                ],
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Đang lưu…' : 'Lưu thay đổi')),
              ]))));
}
