import '../models/feedback_model.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';
import '../models/voucher_model.dart';
import '../models/work_schedule_model.dart';

class MockData {
  static final List<CategoryModel> categories = [
    CategoryModel(id: 1, name: 'Tất cả'),
    CategoryModel(id: 2, name: 'Khai vị', description: 'Các món khởi đầu tinh tế, tươi mát'),
    CategoryModel(id: 3, name: 'Món chính', description: 'Thịt bò Wagyu, Steak, Hải sản cao cấp'),
    CategoryModel(id: 4, name: 'Món nướng & Lẩu', description: 'Lẩu nấm thượng hạng, hải sản tươi sống'),
    CategoryModel(id: 5, name: 'Đồ uống & Rượu', description: 'Vang Pháp, Cocktail pha chế đặc biệt'),
    CategoryModel(id: 6, name: 'Tráng miệng', description: 'Bánh ngọt phong cách Pháp, kem thủ công'),
    CategoryModel(id: 7, name: 'Set Menu Combo', description: 'Tiết kiệm và đầy đủ cho nhóm từ 2-6 người'),
  ];

  static final List<ItemModel> items = [
    ItemModel(
      id: 101,
      categoryId: 3,
      name: 'Bò Wagyu A5 Áp Chảo',
      description: 'Thịt bò Wagyu Nhật Bản cao cấp nướng trên đá nham thạch, dùng kèm sốt tiêu đen truffle và khoai tây nghiền mịn.',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
      price: 1250000,
      priceAfterDiscount: 1090000,
      status: 'AVAILABLE',
      categoryName: 'Món chính',
      averageRating: 4.9,
      feedbackCount: 58,
      tags: ['Bán chạy', 'Signature', 'Chef Pick'],
    ),
    ItemModel(
      id: 102,
      categoryId: 3,
      name: 'Tôm Hùm Nướng Bơ Tỏi',
      description: 'Tôm hùm Nha Trang tươi sống nướng bơ tỏi thơm lừng, sốt phô mai đút lò béo ngậy.',
      imageUrl: 'https://images.unsplash.com/photo-1559742811-822873691df8?w=800&q=80',
      price: 890000,
      status: 'AVAILABLE',
      categoryName: 'Món chính',
      averageRating: 4.8,
      feedbackCount: 42,
      tags: ['Hải sản tươi', 'Cao cấp'],
    ),
    ItemModel(
      id: 103,
      categoryId: 2,
      name: 'Salad Cá Hồi Xông Khói',
      description: 'Rau xanh hữu cơ Đà Lạt kết hợp cá hồi Nauy xông khói, trứng chần và sốt chanh leo chua ngọt.',
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80',
      price: 245000,
      status: 'AVAILABLE',
      categoryName: 'Khai vị',
      averageRating: 4.7,
      feedbackCount: 30,
      tags: ['Healthy', 'Khai vị'],
    ),
    ItemModel(
      id: 104,
      categoryId: 2,
      name: 'Súp Bào Ngư Hải Sâm',
      description: 'Súp hầm thượng canh 12 tiếng từ xương gà ta cùng bào ngư Nam Phi và hải sâm tươi.',
      imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800&q=80',
      price: 380000,
      status: 'AVAILABLE',
      categoryName: 'Khai vị',
      averageRating: 4.9,
      feedbackCount: 22,
      tags: ['Bổ dưỡng', 'Đặc sắc'],
    ),
    ItemModel(
      id: 105,
      categoryId: 3,
      name: 'Sườn Cừu Nướng Hương Thảo',
      description: 'Sườn cừu New Zealand nướng vừa tới, mềm mọng nước, thoang thoảng hương thảo mộc tự nhiên.',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
      price: 560000,
      status: 'AVAILABLE',
      categoryName: 'Món chính',
      averageRating: 4.8,
      feedbackCount: 35,
      tags: ['Thịt cừu', 'Âu'],
    ),
    ItemModel(
      id: 106,
      categoryId: 5,
      name: 'Vang Đỏ Château Margaux 2015',
      description: 'Rượu vang đỏ thượng hạng vùng Bordeaux, hương vị đậm đà trái cây chín và gỗ sồi.',
      imageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&q=80',
      price: 2850000,
      status: 'AVAILABLE',
      categoryName: 'Đồ uống & Rượu',
      averageRating: 5.0,
      feedbackCount: 18,
      tags: ['Vang cao cấp', 'Pháp'],
    ),
    ItemModel(
      id: 107,
      categoryId: 5,
      name: 'Cocktail Crown Sunset Signature',
      description: 'Sự pha trộn giữa Gin thủ công, nước ép bưởi hồng, siro hoa hồng và một chút champagne.',
      imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80',
      price: 185000,
      status: 'AVAILABLE',
      categoryName: 'Đồ uống & Rượu',
      averageRating: 4.8,
      feedbackCount: 46,
      tags: ['Cocktail', 'Best Seller'],
    ),
    ItemModel(
      id: 108,
      categoryId: 6,
      name: 'Bánh Lava Socola & Kem Vani',
      description: 'Bánh socola Bỉ tan chảy bên trong, kết hợp hoàn hảo cùng viên kem vani Madagascar thủ công.',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=800&q=80',
      price: 165000,
      status: 'AVAILABLE',
      categoryName: 'Tráng miệng',
      averageRating: 4.9,
      feedbackCount: 65,
      tags: ['Ngọt ngào', 'Món yêu thích'],
    ),
    ItemModel(
      id: 109,
      categoryId: 7,
      name: 'Combo Hoàng Gia Crown Royal (4 người)',
      description: 'Bao gồm: Salad Cá hồi xông khói + Súp Bào ngư (4 phần) + Bò Wagyu A5 + Tôm Hùm sốt bơ tỏi + Bánh Lava socola.',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
      price: 3200000,
      priceAfterDiscount: 2790000,
      status: 'AVAILABLE',
      categoryName: 'Set Menu Combo',
      averageRating: 4.95,
      feedbackCount: 78,
      tags: ['Tiết kiệm 15%', 'Combo tiệc', 'Hot'],
      isCombo: true,
    ),
  ];

  static final List<FloorModel> floors = [
    FloorModel(id: 1, name: 'Tầng 1 - Đại sảnh & Quầy Bar'),
    FloorModel(id: 2, name: 'Tầng 2 - Phòng VIP & Ban công'),
  ];

  static final List<TableModel> tables = [
    // Floor 1
    TableModel(id: 1, name: 'Bàn T1-01', capacity: 2, deposit: 100000, status: TableStatus.available, floorId: 1, areaName: 'Gần cửa sổ', shape: 'ROUND'),
    TableModel(id: 2, name: 'Bàn T1-02', capacity: 2, deposit: 100000, status: TableStatus.occupied, floorId: 1, areaName: 'Gần cửa sổ', shape: 'ROUND'),
    TableModel(id: 3, name: 'Bàn T1-03', capacity: 4, deposit: 150000, status: TableStatus.available, floorId: 1, areaName: 'Khu vực trung tâm', shape: 'RECTANGLE'),
    TableModel(id: 4, name: 'Bàn T1-04', capacity: 4, deposit: 150000, status: TableStatus.reserved, floorId: 1, areaName: 'Khu vực trung tâm', shape: 'RECTANGLE'),
    TableModel(id: 5, name: 'Bàn T1-05', capacity: 6, deposit: 200000, status: TableStatus.available, floorId: 1, areaName: 'Gia đình', shape: 'RECTANGLE'),
    TableModel(id: 6, name: 'Bàn T1-06', capacity: 8, deposit: 300000, status: TableStatus.available, floorId: 1, areaName: 'Khu vực nhóm lớn', shape: 'RECTANGLE'),

    // Floor 2
    TableModel(id: 7, name: 'Phòng VIP Hoàng Gia 01', capacity: 10, deposit: 500000, status: TableStatus.available, floorId: 2, areaName: 'Phòng VIP', shape: 'RECTANGLE'),
    TableModel(id: 8, name: 'Phòng VIP Hoàng Gia 02', capacity: 8, deposit: 400000, status: TableStatus.occupied, floorId: 2, areaName: 'Phòng VIP', shape: 'RECTANGLE'),
    TableModel(id: 9, name: 'Bàn T2-01 (Ban công)', capacity: 2, deposit: 150000, status: TableStatus.available, floorId: 2, areaName: 'Ban công ngắm phố', shape: 'ROUND'),
    TableModel(id: 10, name: 'Bàn T2-02 (Ban công)', capacity: 4, deposit: 200000, status: TableStatus.reserved, floorId: 2, areaName: 'Ban công ngắm phố', shape: 'RECTANGLE'),
  ];

  static final List<VoucherModel> vouchers = [
    VoucherModel(
      id: 1,
      code: 'CROWNDINE50',
      name: 'Giảm 50.000₫ cho khách hàng mới',
      description: 'Áp dụng cho hóa đơn từ 500.000₫',
      discountPercent: 10,
      maxDiscount: 50000,
      minOrderValue: 500000,
    ),
    VoucherModel(
      id: 2,
      code: 'VIPGOLD10',
      name: 'Ưu đãi thành viên Gold 10%',
      description: 'Giảm tối đa 200.000₫ cho đơn đặt bàn',
      discountPercent: 10,
      maxDiscount: 200000,
      minOrderValue: 1000000,
    ),
    VoucherModel(
      id: 3,
      code: 'PARTY2026',
      name: 'Ưu đãi đặt tiệc liên hoan',
      description: 'Giảm ngay 15% cho hóa đơn từ 3.000.000₫',
      discountPercent: 15,
      maxDiscount: 500000,
      minOrderValue: 3000000,
    ),
  ];

  static final List<UserModel> staffList = [
    UserModel(
      id: 201,
      username: 'bao_tq',
      email: 'bao.tran@crowndine.vn',
      firstName: 'Trần',
      lastName: 'Quốc Bảo',
      phone: '0912345678',
      role: UserRole.staff,
      membershipTier: 'Trưởng ca phục vụ',
      avatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&q=80',
    ),
    UserModel(
      id: 202,
      username: 'huong_chef',
      email: 'huong.mai@crowndine.vn',
      firstName: 'Mai',
      lastName: 'Thu Hương',
      phone: '0923456789',
      role: UserRole.staff,
      membershipTier: 'Lễ tân / Tiếp đón',
      avatar: 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&q=80',
    ),
    UserModel(
      id: 203,
      username: 'nguyenkhoa',
      email: 'khoa.nguyen@crowndine.vn',
      firstName: 'Nguyễn',
      lastName: 'Đăng Khoa',
      phone: '0934567890',
      role: UserRole.staff,
      membershipTier: 'Nhân viên phục vụ',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    ),
    UserModel(
      id: 204,
      username: 'hang_barista',
      email: 'hang.pham@crowndine.vn',
      firstName: 'Phạm',
      lastName: 'Thúy Hằng',
      phone: '0945678901',
      role: UserRole.staff,
      membershipTier: 'Barista / Pha chế',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80',
    ),
    UserModel(
      id: 205,
      username: 'quan_cashier',
      email: 'quan.le@crowndine.vn',
      firstName: 'Lê',
      lastName: 'Minh Quân',
      phone: '0956789012',
      role: UserRole.staff,
      membershipTier: 'Thu ngân',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80',
    ),
  ];

  static List<UserModel> get sampleStaffs => staffList;

  static final List<ReservationModel> sampleReservations = [
    ReservationModel(
      id: 1001,
      code: 'CR-8892',
      customerName: 'Nguyễn Văn An',
      guestName: 'Nguyễn Văn An',
      guestPhone: '0901234567',
      email: 'nguyenvanan@gmail.com',
      date: '2026-10-29',
      startTime: '18:30',
      endTime: '20:30',
      guestNumber: 4,
      tableId: 3,
      tableName: 'Bàn T1-03',
      floorName: 'Tầng 1',
      areaName: 'Khu vực trung tâm',
      tableDeposit: 150000,
      itemsTotal: 1450000,
      finalAmount: 1600000,
      status: ReservationStatus.confirmed,
      note: 'Chuẩn bị nến và hoa kỷ niệm ngày cưới',
      orderDetails: [
        ReservationOrderDetailModel(id: 1, name: 'Bò Wagyu A5 Áp Chảo', quantity: 1, unitPrice: 1090000),
        ReservationOrderDetailModel(id: 2, name: 'Tôm Hùm Nướng Bơ Tỏi', quantity: 1, unitPrice: 245000),
        ReservationOrderDetailModel(id: 3, name: 'Salad Hoàng Gia Crown', quantity: 1, unitPrice: 115000),
      ],
      items: [
        CartItemModel(item: items[0], quantity: 1),
        CartItemModel(item: items[2], quantity: 1),
      ],
      createdAt: DateTime(2026, 10, 29, 9, 30),
    ),
    ReservationModel(
      id: 1002,
      code: 'CR-9043',
      customerName: 'Trần Thị Mai',
      guestName: 'Trần Thị Mai',
      guestPhone: '0988776655',
      email: 'thimai.tran@gmail.com',
      date: '2026-10-29',
      startTime: '11:30',
      endTime: '13:30',
      guestNumber: 2,
      tableId: 1,
      tableName: 'Bàn T1-01',
      floorName: 'Tầng 1',
      areaName: 'Gần cửa sổ',
      tableDeposit: 100000,
      itemsTotal: 560000,
      finalAmount: 660000,
      status: ReservationStatus.checkedIn,
      note: 'Khách VIP thân thiết, phục vụ nước ấm',
      orderDetails: [
        ReservationOrderDetailModel(id: 4, name: 'Súp Bào Ngư Vi Cá', quantity: 2, unitPrice: 280000),
      ],
      createdAt: DateTime(2026, 10, 29, 8, 15),
    ),
    ReservationModel(
      id: 1003,
      code: 'CR-5120',
      customerName: 'Lê Hoàng Long',
      guestName: 'Lê Hoàng Long',
      guestPhone: '0912345999',
      email: 'long.le@holding.vn',
      date: '2026-10-29',
      startTime: '19:00',
      endTime: '21:30',
      guestNumber: 8,
      tableId: 7,
      tableName: 'Phòng VIP Hoàng Gia 01',
      floorName: 'Tầng 2',
      areaName: 'Phòng VIP',
      tableDeposit: 500000,
      itemsTotal: 5030000,
      finalAmount: 5530000,
      status: ReservationStatus.confirmed,
      note: 'Tiếp đối tác quan trọng, chuẩn bị rượu vang trước 15p',
      orderDetails: [
        ReservationOrderDetailModel(id: 5, name: 'Rượu Vang Đỏ Chateau Margaux 2015', quantity: 1, unitPrice: 2850000),
        ReservationOrderDetailModel(id: 6, name: 'Bò Wagyu A5 Áp Chảo', quantity: 2, unitPrice: 1090000),
      ],
      createdAt: DateTime(2026, 10, 29, 10, 0),
    ),
    ReservationModel(
      id: 1004,
      code: 'CR-3312',
      customerName: 'Phạm Minh Tuấn',
      guestName: 'Phạm Minh Tuấn',
      guestPhone: '0933221100',
      date: '2026-10-29',
      startTime: '12:00',
      endTime: '14:00',
      guestNumber: 4,
      tableId: 5,
      tableName: 'Bàn T1-05',
      floorName: 'Tầng 1',
      areaName: 'Gia đình',
      tableDeposit: 200000,
      itemsTotal: 890000,
      finalAmount: 1090000,
      status: ReservationStatus.completed,
      note: 'Có 1 ghế trẻ em',
      orderDetails: [
        ReservationOrderDetailModel(id: 7, name: 'Cua Hoàng Đế Hấp Rượu Vang', quantity: 1, unitPrice: 890000),
      ],
      createdAt: DateTime(2026, 10, 29, 7, 45),
    ),
    ReservationModel(
      id: 1005,
      code: 'CR-6621',
      customerName: 'Đỗ Thanh Hằng',
      guestName: 'Đỗ Thanh Hằng',
      guestPhone: '0977112233',
      date: '2026-10-29',
      startTime: '20:00',
      endTime: '22:00',
      guestNumber: 2,
      tableId: 9,
      tableName: 'Bàn T2-01 (Ban công)',
      floorName: 'Tầng 2',
      areaName: 'Ban công ngắm phố',
      tableDeposit: 150000,
      itemsTotal: 0,
      finalAmount: 150000,
      status: ReservationStatus.pending,
      note: 'Hẹn hò lãng mạn, vị trí bàn thoáng mát view đẹp',
      createdAt: DateTime(2026, 10, 29, 14, 20),
    ),
    ReservationModel(
      id: 1006,
      code: 'CR-1109',
      customerName: 'Hoàng Gia Bảo',
      guestName: 'Hoàng Gia Bảo',
      guestPhone: '0944556677',
      date: '2026-10-29',
      startTime: '17:30',
      endTime: '19:00',
      guestNumber: 4,
      tableId: 4,
      tableName: 'Bàn T1-04',
      floorName: 'Tầng 1',
      areaName: 'Khu vực trung tâm',
      tableDeposit: 150000,
      itemsTotal: 0,
      finalAmount: 150000,
      status: ReservationStatus.cancelled,
      note: 'Khách bận đột xuất báo hủy trước 2 tiếng',
      createdAt: DateTime(2026, 10, 29, 11, 0),
    ),
    ReservationModel(
      id: 1007,
      code: 'CR-2204',
      customerName: 'Vũ Phương Thảo',
      guestName: 'Vũ Phương Thảo',
      guestPhone: '0966889900',
      date: '2026-10-29',
      startTime: '10:00',
      endTime: '11:30',
      guestNumber: 2,
      tableId: 2,
      tableName: 'Bàn T1-02',
      floorName: 'Tầng 1',
      areaName: 'Gần cửa sổ',
      tableDeposit: 100000,
      itemsTotal: 0,
      finalAmount: 100000,
      status: ReservationStatus.noShow,
      note: 'Quá 30 phút liên hệ 3 lần không nhấc máy',
      createdAt: DateTime(2026, 10, 29, 8, 30),
    ),
    ReservationModel(
      id: 1008,
      code: 'CR-7788',
      customerName: 'Bùi Đức Thịnh',
      guestName: 'Bùi Đức Thịnh',
      guestPhone: '0911224466',
      date: '2026-10-30',
      startTime: '19:30',
      endTime: '21:30',
      guestNumber: 6,
      tableId: 8,
      tableName: 'Phòng VIP Hoàng Gia 02',
      floorName: 'Tầng 2',
      areaName: 'Phòng VIP',
      tableDeposit: 400000,
      itemsTotal: 2790000,
      finalAmount: 3190000,
      status: ReservationStatus.confirmed,
      note: 'Sinh nhật sếp công ty, cần chuẩn bị bánh kem',
      orderDetails: [
        ReservationOrderDetailModel(id: 8, name: 'Set Menu Hoàng Gia 6 Món', quantity: 1, unitPrice: 2790000),
      ],
      createdAt: DateTime(2026, 10, 29, 16, 0),
    ),
  ];

  static final List<OrderModel> sampleOrders = [
    OrderModel(
      id: 201,
      code: 'ORD-001',
      guestName: 'Bàn T1-02 (Khách Anh Tuấn)',
      tableName: 'Bàn T1-02',
      status: OrderStatus.inProgress,
      totalPrice: 1630000,
      finalPrice: 1630000,
      details: [
        OrderDetailModel(
          id: 1,
          item: items[0],
          itemName: 'Bò Wagyu A5 Áp Chảo',
          quantity: 1,
          totalPrice: 1090000,
          status: DishCookingStatus.cooking,
          note: 'Chín vừa (Medium Rare)',
        ),
        OrderDetailModel(
          id: 2,
          item: items[2],
          itemName: 'Salad Cá Hồi Xông Khói',
          quantity: 1,
          totalPrice: 245000,
          status: DishCookingStatus.ready,
          note: 'Để sốt riêng',
        ),
        OrderDetailModel(
          id: 3,
          item: items[6],
          itemName: 'Cocktail Crown Sunset Signature',
          quantity: 2,
          totalPrice: 370000,
          status: DishCookingStatus.served,
        ),
      ],
    ),
    OrderModel(
      id: 202,
      code: 'ORD-002',
      guestName: 'Phòng VIP 02 (Đoàn Doanh nghiệp)',
      tableName: 'Phòng VIP 02',
      status: OrderStatus.inProgress,
      totalPrice: 3850000,
      finalPrice: 3850000,
      details: [
        OrderDetailModel(
          id: 4,
          item: items[8],
          itemName: 'Combo Hoàng Gia Crown Royal (4 người)',
          quantity: 1,
          totalPrice: 2790000,
          status: DishCookingStatus.cooking,
          note: 'Ra súp và salad trước',
        ),
        OrderDetailModel(
          id: 5,
          item: items[5],
          itemName: 'Vang Đỏ Château Margaux 2015',
          quantity: 1,
          totalPrice: 2850000,
          status: DishCookingStatus.served,
          note: 'Ướp lạnh trước khi khui',
        ),
      ],
    ),
  ];

  static final List<FeedbackModel> feedbacks = [
    FeedbackModel(
      id: 1,
      rating: 5,
      comment: 'Thịt bò Wagyu áp chảo mềm tan trong miệng, sốt nấm Truffle thơm lừng. Rất xứng đáng với trải nghiệm ẩm thực cao cấp!',
      fullName: 'Hoàng Nam',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
      createdAt: '2 ngày trước',
      itemId: 101,
    ),
    FeedbackModel(
      id: 2,
      rating: 5,
      comment: 'Tôm hùm Nha Trang tươi ngon, sốt bơ tỏi thơm nức mũi. Nhân viên phục vụ nhiệt tình và rất chu đáo.',
      fullName: 'Thu Hằng',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
      createdAt: '3 ngày trước',
      itemId: 102,
    ),
    FeedbackModel(
      id: 3,
      rating: 5,
      comment: 'Không gian nhà hàng sang trọng, rượu vang Margaux ướp đúng nhiệt độ. Một bữa tối hoàn hảo cho lễ kỷ niệm!',
      fullName: 'Minh Quân',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      createdAt: '1 tuần trước',
      itemId: 106,
    ),
    FeedbackModel(
      id: 4,
      rating: 4,
      comment: 'Salad cá hồi tươi giòn, sốt chua ngọt thanh mát. Trình bày món ăn rất đẹp mắt và nghệ thuật.',
      fullName: 'Bích Phương',
      avatarUrl: 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&q=80',
      createdAt: '1 tuần trước',
      itemId: 103,
    ),
  ];

  static final List<ShiftModel> sampleShifts = [
    const ShiftModel(
      id: 1,
      name: 'Ca Sáng',
      startTime: '08:00:00',
      endTime: '16:00:00',
      colorHex: '#10B981',
    ),
    const ShiftModel(
      id: 2,
      name: 'Ca Chiều',
      startTime: '14:00:00',
      endTime: '22:00:00',
      colorHex: '#3B82F6',
    ),
    const ShiftModel(
      id: 3,
      name: 'Ca Tối',
      startTime: '17:00:00',
      endTime: '23:00:00',
      colorHex: '#8B5CF6',
    ),
    const ShiftModel(
      id: 4,
      name: 'Ca Gãy',
      startTime: '10:00:00',
      endTime: '14:00:00',
      colorHex: '#F59E0B',
    ),
    const ShiftModel(
      id: 5,
      name: 'Ca Full',
      startTime: '08:00:00',
      endTime: '22:00:00',
      colorHex: '#EC4899',
    ),
  ];

  static final List<WorkScheduleModel> sampleWorkSchedules = [
    // 1. Nguyễn Đăng Khoa (ID: 203 - Logged in staff)
    WorkScheduleModel(
      id: 301,
      workDate: '2026-10-26',
      status: WorkScheduleStatus.approved,
      note: 'Trực tầng 1',
      user: staffList[2],
      shift: sampleShifts[0], // Ca Sáng (08:00 - 16:00)
    ),
    WorkScheduleModel(
      id: 302,
      workDate: '2026-10-27',
      status: WorkScheduleStatus.approved,
      note: 'Phục vụ bàn VIP',
      user: staffList[2],
      shift: sampleShifts[0], // Ca Sáng (08:00 - 16:00)
    ),
    WorkScheduleModel(
      id: 303,
      workDate: '2026-10-28',
      status: WorkScheduleStatus.approved,
      note: 'Trực sảnh chính',
      user: staffList[2],
      shift: sampleShifts[1], // Ca Chiều (14:00 - 22:00)
    ),
    WorkScheduleModel(
      id: 304,
      workDate: '2026-10-29',
      status: WorkScheduleStatus.approved,
      note: 'Trực khu vực Ban công & Sảnh chính',
      user: staffList[2],
      shift: sampleShifts[1], // Ca Chiều (14:00 - 22:00)
    ),
    WorkScheduleModel(
      id: 305,
      workDate: '2026-10-30',
      status: WorkScheduleStatus.pending,
      note: 'Đăng ký thêm ca tiệc tối',
      user: staffList[2],
      shift: sampleShifts[2], // Ca Tối (17:00 - 23:00)
    ),
    WorkScheduleModel(
      id: 306,
      workDate: '2026-10-31',
      status: WorkScheduleStatus.approved,
      note: 'Ngày cao điểm cuối tuần',
      user: staffList[2],
      shift: sampleShifts[4], // Ca Full (08:00 - 22:00)
    ),

    // 2. Trần Quốc Bảo (ID: 201 - Trưởng ca)
    WorkScheduleModel(
      id: 307,
      workDate: '2026-10-26',
      status: WorkScheduleStatus.approved,
      note: 'Giám sát vận hành ca chiều',
      user: staffList[0],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 308,
      workDate: '2026-10-27',
      status: WorkScheduleStatus.approved,
      user: staffList[0],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 309,
      workDate: '2026-10-28',
      status: WorkScheduleStatus.approved,
      user: staffList[0],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 310,
      workDate: '2026-10-29',
      status: WorkScheduleStatus.approved,
      note: 'Điều phối ca sáng',
      user: staffList[0],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 311,
      workDate: '2026-10-30',
      status: WorkScheduleStatus.approved,
      user: staffList[0],
      shift: sampleShifts[4], // Ca Full
    ),
    WorkScheduleModel(
      id: 312,
      workDate: '2026-10-31',
      status: WorkScheduleStatus.approved,
      user: staffList[0],
      shift: sampleShifts[2], // Ca Tối
    ),
    WorkScheduleModel(
      id: 313,
      workDate: '2026-11-01',
      status: WorkScheduleStatus.approved,
      user: staffList[0],
      shift: sampleShifts[0], // Ca Sáng
    ),

    // 3. Mai Thu Hương (ID: 202 - Lễ tân)
    WorkScheduleModel(
      id: 314,
      workDate: '2026-10-26',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 315,
      workDate: '2026-10-27',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[3], // Ca Gãy
    ),
    WorkScheduleModel(
      id: 316,
      workDate: '2026-10-28',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 317,
      workDate: '2026-10-29',
      status: WorkScheduleStatus.approved,
      note: 'Check-in đón khách VIP',
      user: staffList[1],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 318,
      workDate: '2026-10-30',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 319,
      workDate: '2026-10-31',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[4], // Ca Full
    ),
    WorkScheduleModel(
      id: 320,
      workDate: '2026-11-01',
      status: WorkScheduleStatus.approved,
      user: staffList[1],
      shift: sampleShifts[1], // Ca Chiều
    ),

    // 4. Phạm Thúy Hằng (ID: 204 - Barista)
    WorkScheduleModel(
      id: 321,
      workDate: '2026-10-26',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[3], // Ca Gãy
    ),
    WorkScheduleModel(
      id: 322,
      workDate: '2026-10-27',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 323,
      workDate: '2026-10-28',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[2], // Ca Tối
    ),
    WorkScheduleModel(
      id: 324,
      workDate: '2026-10-29',
      status: WorkScheduleStatus.approved,
      note: 'Quầy bar tầng 1 & pha chế cocktail',
      user: staffList[3],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 325,
      workDate: '2026-10-30',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[2], // Ca Tối
    ),
    WorkScheduleModel(
      id: 326,
      workDate: '2026-10-31',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 327,
      workDate: '2026-11-01',
      status: WorkScheduleStatus.approved,
      user: staffList[3],
      shift: sampleShifts[4], // Ca Full
    ),

    // 5. Lê Minh Quân (ID: 205 - Thu ngân)
    WorkScheduleModel(
      id: 328,
      workDate: '2026-10-26',
      status: WorkScheduleStatus.approved,
      user: staffList[4],
      shift: sampleShifts[2], // Ca Tối
    ),
    WorkScheduleModel(
      id: 329,
      workDate: '2026-10-27',
      status: WorkScheduleStatus.approved,
      user: staffList[4],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 330,
      workDate: '2026-10-28',
      status: WorkScheduleStatus.approved,
      user: staffList[4],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 331,
      workDate: '2026-10-29',
      status: WorkScheduleStatus.approved,
      note: 'Đối soát kết ca tối',
      user: staffList[4],
      shift: sampleShifts[2], // Ca Tối
    ),
    WorkScheduleModel(
      id: 332,
      workDate: '2026-10-30',
      status: WorkScheduleStatus.approved,
      user: staffList[4],
      shift: sampleShifts[0], // Ca Sáng
    ),
    WorkScheduleModel(
      id: 333,
      workDate: '2026-10-31',
      status: WorkScheduleStatus.approved,
      user: staffList[4],
      shift: sampleShifts[1], // Ca Chiều
    ),
    WorkScheduleModel(
      id: 334,
      workDate: '2026-11-01',
      status: WorkScheduleStatus.pending,
      note: 'Đổi ca với Thu Hương',
      user: staffList[4],
      shift: sampleShifts[1], // Ca Chiều
    ),
  ];

  /// Sinh lịch làm việc mẫu cho tuần bất kỳ (Thứ 2 -> Chủ nhật)
  static List<WorkScheduleModel> _generateSchedulesForWeek(DateTime monday) {
    final list = <WorkScheduleModel>[];
    final shiftIndices = [
      [0, 0, 1, 1, 2, 4, -1], // Staff 203 (Khoa)
      [1, 1, 0, 0, 4, 2, 0],  // Staff 201 (Bảo)
      [0, 3, 1, 0, 1, 4, 1],  // Staff 202 (Hương)
      [3, 1, 2, 1, 2, 0, 4],  // Staff 204 (Hằng)
      [2, 0, 0, 2, 0, 1, 1],  // Staff 205 (Quân)
    ];

    for (int sIdx = 0; sIdx < staffList.length; sIdx++) {
      final staff = staffList[sIdx];
      final pattern = shiftIndices[sIdx % shiftIndices.length];

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final shiftIndex = pattern[dayOffset];
        if (shiftIndex < 0 || shiftIndex >= sampleShifts.length) continue;

        final targetDate = monday.add(Duration(days: dayOffset));
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

        list.add(
          WorkScheduleModel(
            id: targetDate.millisecondsSinceEpoch ~/ 100000 + (staff.id * 10) + dayOffset,
            workDate: dateStr,
            status: dayOffset == 4 && staff.id == 203 ? WorkScheduleStatus.pending : WorkScheduleStatus.approved,
            note: dayOffset == 3 && staff.id == 203 ? 'Trực tầng 1 & tiếp đón khách' : null,
            user: staff,
            shift: sampleShifts[shiftIndex],
          ),
        );
      }
    }
    return list;
  }

  /// Lọc lịch làm việc mẫu theo tiêu chí
  static List<WorkScheduleModel> getWorkSchedules({
    String? fromDate,
    String? toDate,
    int? userId,
    String? status,
    int? shiftId,
  }) {
    DateTime? from = fromDate != null ? DateTime.tryParse(fromDate) : null;
    DateTime? to = toDate != null ? DateTime.tryParse(toDate) : null;

    List<WorkScheduleModel> source = sampleWorkSchedules;

    if (from != null && to != null) {
      final hasOverlap = source.any((s) {
        final d = s.parsedDate;
        return d != null && !d.isBefore(from) && !d.isAfter(to);
      });

      if (!hasOverlap) {
        // Tự động sinh lịch cho tuần được yêu cầu nếu không có sẵn
        source = _generateSchedulesForWeek(from);
      }
    }

    return source.where((s) {
      if (from != null && s.parsedDate != null && s.parsedDate!.isBefore(from)) return false;
      if (to != null && s.parsedDate != null && s.parsedDate!.isAfter(to)) return false;
      if (userId != null && s.user.id != userId) return false;
      if (shiftId != null && s.shift.id != shiftId) return false;
      if (status != null && status.isNotEmpty && status != 'ALL' && status != 'Tất cả') {
        if (s.status.code.toUpperCase() != status.toUpperCase() &&
            s.status.displayName.toLowerCase() != status.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
