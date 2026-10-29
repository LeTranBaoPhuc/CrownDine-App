class ApiEndpoints {
  // Auth
  static const String login = 'auth/login';
  static const String register = 'auth/register';
  static const String refreshToken = 'auth/refresh-token';
  static const String logout = 'auth/logout';
  static const String googleLogin = 'auth/google-login';
  static const String forgotPasswordSendOtp = 'auth/forgot-password/otp';
  static const String forgotPasswordVerifyOtp = 'auth/forgot-password/verify-otp';
  static const String forgotPasswordResetByOtp = 'auth/forgot-password/reset-by-otp';

  // Users & Profile
  static const String profile = 'users/profile';
  static const String updateProfile = 'users';
  static const String changePassword = 'users/change-password';
  static const String uploadAvatar = 'users/upload-avatar';
  static const String sendEmailOtp = 'users/profile/email-otp/send';
  static const String verifyEmailOtp = 'users/profile/email-otp/verify';
  static const String pointHistory = 'users/profile/point-history';

  // Items & Categories
  static const String items = 'items';
  static const String itemsList = 'items/list';
  static const String categories = 'categories';
  static const String combos = 'combos';

  // Reservations
  static const String reservations = 'reservations';
  static const String reservationHistory = 'reservations/history';
  static const String reservationAll = 'reservations/all';
  static const String reservationCreate = 'reservations/create';
  static const String reservationStaffCreate = 'reservations/staff-create';

  // Tables & Layout
  static const String layoutFloors = 'layout/floors';
  static const String layoutTables = 'layout/tables';
  static const String layoutSummary = 'layout';

  // Orders
  static const String orders = 'orders';
  static const String orderDetails = 'order-details';

  // Vouchers
  static const String vouchers = 'vouchers';
  static const String userVouchers = 'user-vouchers';

  // Feedbacks
  static const String feedbacks = 'feedbacks';
  static String feedbacksByItem(int itemId) => 'feedbacks/items/$itemId';
  static String feedbacksByCombo(int comboId) => 'feedbacks/combos/$comboId';

  // Favorites
  static const String favorites = 'favorites';
  static String favoriteItem(int itemId) => 'favorites/items/$itemId';
  static String favoriteCombo(int comboId) => 'favorites/combos/$comboId';
  static String checkFavoriteItem(int itemId) => 'favorites/items/$itemId/check';
  static String checkFavoriteCombo(int comboId) => 'favorites/combos/$comboId/check';
}

