/// API Configuration
/// 
/// Base URL for the backend API
/// 
/// IMPORTANT: Choose the correct URL based on where you're running the Flutter app:
/// 
/// 1. Android Emulator: 'http://10.0.2.2:8080' (default)
///    - 10.0.2.2 is a special IP that maps to your computer's localhost
/// 
/// 2. iOS Simulator: 'http://localhost:8080'
///    - localhost works directly on iOS Simulator
/// 
/// 3. Physical Device (Phone/Tablet): 'http://192.168.1.137:8080'
///    - Find your IP: Windows (ipconfig) or macOS/Linux (ifconfig)
///    - Example: 'http://192.168.1.100:8080'
///    - Device and computer MUST be on same Wi-Fi network
/// 
/// 4. Web Browser: 'http://localhost:8080'
class ApiConfig {
  // ============================================
  // CHANGE THIS BASED ON YOUR DEVICE:
  // ============================================
  
  // Option 1: Android Emulator (uncomment this if using Android Emulator)
  // static const String baseUrl = 'http://10.0.2.2:8080';
  
  // Option 2: iOS Simulator (uncomment this if using iOS Simulator)
  // static const String baseUrl = 'http://localhost:8080';
  
  // Option 3: Physical Device (Commented out)
  // static const String baseUrl = 'http://192.168.1.137:8080';
  
  // Option 4: Web Browser (uncomment this if running in web browser)
  // static const String baseUrl = 'http://localhost:8080';

  // Option 5: Production (Railway)
  static const String baseUrl = 'https://flip-production-118c.up.railway.app';
  
  // API Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh-token';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authVerifyEmail = '/api/auth/verify-email';
  static const String authResendVerification = '/api/auth/resend-verification';
  
  // Business endpoints (CEO)
  static const String businessRegister = '/api/business/register';
  static const String businessBranches = '/api/business/branches';
  static const String businessMyBusiness = '/api/business/my-business';
  
  // Product endpoints (MANAGER)
  static const String productsList = '/api/products';
  static const String productsAdd = '/api/products';
  static const String productsBarcodeLookup = '/api/products/barcode';
  
  // Sales endpoints (CLERK)
  static const String salesScan = '/api/sales/scan';
  
  // Analytics endpoints (MANAGER, CEO)
  static const String analyticsRevenue = '/api/analytics/sales/revenue';
  static const String analyticsTransactions = '/api/analytics/sales/transactions';
  static const String analyticsBestSelling = '/api/analytics/sales/best-selling';
  static const String analyticsLowStock = '/api/analytics/products/low-stock';
  static const String analyticsMostStocked = '/api/analytics/products/most-stocked';
}











