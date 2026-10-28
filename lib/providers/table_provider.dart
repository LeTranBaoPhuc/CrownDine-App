import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_data.dart';
import '../data/models/table_model.dart';
import '../data/repositories/table_repository.dart';

final tableRepositoryProvider = Provider<TableRepository>((ref) => TableRepository());

class TableState {
  final List<FloorModel> floors;
  final List<TableModel> allTables;
  final int selectedFloorId;
  final TableStatus? statusFilter;
  final bool isLoading;
  final String? errorMessage;

  TableState({
    List<FloorModel>? floors,
    List<TableModel>? allTables,
    this.selectedFloorId = 1,
    this.statusFilter,
    this.isLoading = false,
    this.errorMessage,
  })  : floors = floors ?? MockData.floors,
        allTables = allTables ?? MockData.tables;

  List<TableModel> get floorTables {
    var list = allTables.where((t) => t.floorId == selectedFloorId).toList();
    if (statusFilter != null) {
      list = list.where((t) => t.status == statusFilter).toList();
    }
    return list;
  }

  TableState copyWith({
    List<FloorModel>? floors,
    List<TableModel>? allTables,
    int? selectedFloorId,
    TableStatus? Function()? statusFilter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TableState(
      floors: floors ?? this.floors,
      allTables: allTables ?? this.allTables,
      selectedFloorId: selectedFloorId ?? this.selectedFloorId,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TableNotifier extends StateNotifier<TableState> {
  final TableRepository _repo;

  TableNotifier(this._repo) : super(TableState()) {
    loadLayout();
  }

  Future<void> loadLayout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final floors = await _repo.getFloors();
      final tables = await _repo.getTables();
      state = state.copyWith(
        floors: floors,
        allTables: tables,
        selectedFloorId: floors.isNotEmpty ? floors.first.id : 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải danh sách bàn: ${e.toString()}',
      );
    }
  }

  void selectFloor(int floorId) {
    state = state.copyWith(selectedFloorId: floorId);
  }

  void filterByStatus(TableStatus? status) {
    state = state.copyWith(statusFilter: () => status);
  }

  void updateTableStatus(int tableId, TableStatus newStatus) {
    final list = List<TableModel>.from(state.allTables);
    final idx = list.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = TableModel(
        id: old.id,
        name: old.name,
        capacity: old.capacity,
        deposit: old.deposit,
        status: newStatus,
        shape: old.shape,
        floorId: old.floorId,
        floorName: old.floorName,
        areaName: old.areaName,
        x: old.x,
        y: old.y,
      );
      state = state.copyWith(allTables: list);
    }
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return TableNotifier(repo);
});
