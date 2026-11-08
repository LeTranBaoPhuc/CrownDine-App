import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_error.dart';
import '../data/models/table_model.dart';
import '../data/repositories/table_repository.dart';

final tableRepositoryProvider =
    Provider<TableRepository>((ref) => TableRepository());

class TableState {
  final List<FloorModel> floors;
  final List<TableModel> allTables;
  final int selectedFloorId;
  final TableStatus? statusFilter;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;

  TableState(
      {this.floors = const [],
      this.allTables = const [],
      this.selectedFloorId = 1,
      this.statusFilter,
      this.isLoading = false,
      this.isUpdating = false,
      this.errorMessage});

  List<TableModel> get floorTables => allTables
      .where((t) =>
          t.floorId == selectedFloorId &&
          (statusFilter == null || t.status == statusFilter))
      .toList();

  TableState copyWith(
          {List<FloorModel>? floors,
          List<TableModel>? allTables,
          int? selectedFloorId,
          TableStatus? Function()? statusFilter,
          bool? isLoading,
          bool? isUpdating,
          String? errorMessage}) =>
      TableState(
          floors: floors ?? this.floors,
          allTables: allTables ?? this.allTables,
          selectedFloorId: selectedFloorId ?? this.selectedFloorId,
          statusFilter:
              statusFilter != null ? statusFilter() : this.statusFilter,
          isLoading: isLoading ?? this.isLoading,
          isUpdating: isUpdating ?? this.isUpdating,
          errorMessage: errorMessage);
}

class TableNotifier extends StateNotifier<TableState> {
  final TableRepository _repo;
  TableNotifier(this._repo) : super(TableState()) {
    loadLayout();
  }

  Future<void> loadLayout() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final floors = await _repo.getFloors();
      final tables = await _repo.getTables();
      if (!mounted) return;
      final selected = floors.any((f) => f.id == state.selectedFloorId)
          ? state.selectedFloorId
          : (floors.isEmpty ? 1 : floors.first.id);
      state = state.copyWith(
          floors: floors,
          allTables: tables,
          selectedFloorId: selected,
          isLoading: false);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false, errorMessage: apiErrorMessage(error));
      }
    }
  }

  void selectFloor(int floorId) =>
      state = state.copyWith(selectedFloorId: floorId);
  void filterByStatus(TableStatus? status) =>
      state = state.copyWith(statusFilter: () => status);

  Future<bool> updateTableStatus(int tableId, TableStatus status) async {
    if (state.isUpdating || state.isLoading) return false;
    state = state.copyWith(isUpdating: true);
    try {
      final updated = await _repo.updateStatus(tableId, status);
      if (!mounted) return false;
      state = state.copyWith(isUpdating: false, allTables: [
        for (final table in state.allTables)
          table.id == tableId ? updated : table,
      ]);
      return true;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
            isUpdating: false, errorMessage: apiErrorMessage(error));
      }
      return false;
    }
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, TableState>(
    (ref) => TableNotifier(ref.watch(tableRepositoryProvider)));
