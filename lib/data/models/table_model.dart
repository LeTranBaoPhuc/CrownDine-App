enum TableStatus {
  available,
  occupied,
  reserved,
  unavailable;

  static TableStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'OCCUPIED':
      case 'SERVING':
        return TableStatus.occupied;
      case 'RESERVED':
      case 'BOOKED':
        return TableStatus.reserved;
      case 'AVAILABLE':
        return TableStatus.available;
      case 'UNAVAILABLE':
      default:
        return TableStatus.unavailable;
    }
  }

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Bàn trống';
      case TableStatus.occupied:
        return 'Đang phục vụ';
      case TableStatus.reserved:
        return 'Đã đặt trước';
      case TableStatus.unavailable:
        return 'Ngưng phục vụ';
    }
  }
}

class FloorModel {
  final int id;
  final String name;

  FloorModel({required this.id, required this.name});

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class TableModel {
  final int id;
  final String name;
  final int capacity;
  final double deposit;
  final TableStatus status;
  final String shape; // 'ROUND' | 'RECTANGLE' | 'SQUARE'
  final int floorId;
  final String? floorName;
  final String? areaName;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.deposit,
    required this.status,
    this.shape = 'RECTANGLE',
    this.floorId = 1,
    this.floorName,
    this.areaName,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 80,
    this.rotation = 0,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'] is int
          ? json['capacity']
          : int.tryParse('${json['capacity']}') ?? 4,
      deposit: (json['deposit'] is num)
          ? (json['deposit'] as num).toDouble()
          : double.tryParse('${json['deposit']}') ?? 0,
      status: TableStatus.fromString(json['status']),
      shape: json['shape'] ?? 'RECTANGLE',
      floorId: json['floorId'] is int ? json['floorId'] : 1,
      floorName: json['floorName'],
      areaName: json['areaName'],
      x: (json['x'] is num) ? (json['x'] as num).toDouble() : 0.0,
      y: (json['y'] is num) ? (json['y'] as num).toDouble() : 0.0,
      width: (json['width'] is num) ? (json['width'] as num).toDouble() : 100,
      height: (json['height'] is num) ? (json['height'] as num).toDouble() : 80,
      rotation:
          (json['rotation'] is num) ? (json['rotation'] as num).toDouble() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'deposit': deposit,
        'status': status.name.toUpperCase(),
        'shape': shape,
        'floorId': floorId,
        'floorName': floorName,
        'areaName': areaName,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
      };
}
