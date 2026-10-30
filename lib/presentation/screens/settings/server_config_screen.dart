import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _urlController = TextEditingController();
  final _googleClientIdController = TextEditingController();
  bool _mockFallback = true;
  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _googleClientIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final url = await ApiConfig.getBaseUrl();
    final fallback = await ApiConfig.isMockFallbackEnabled();
    final googleClientId = await ApiConfig.getGoogleClientId();
    setState(() {
      _urlController.text = url;
      _mockFallback = fallback;
      _googleClientIdController.text = googleClientId;
    });
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ApiClient.instance.updateBaseUrl(url);
      await ApiConfig.setMockFallbackEnabled(_mockFallback);
      await ApiConfig.setGoogleClientId(_googleClientIdController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cấu hình máy chủ thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    try {
      final res = await ApiClient.instance.dio.get(
        'categories',
        queryParameters: {},
      );
      setState(() {
        _isTesting = false;
        _testSuccess = res.statusCode == 200;
        _testMessage = 'Kết nối thành công tới Backend Spring Boot! (${res.statusCode})';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testMessage = 'Không thể kết nối máy chủ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình kết nối Backend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'CrownDine Mobile kết nối với Backend Spring Boot API. Nếu bạn chạy trên máy ảo Android, hãy dùng IP 10.0.2.2 thay cho localhost.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'API Base URL',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://localhost:8080/api/',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Preset Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Localhost (iOS/Web)'),
                  onPressed: () {
                    _urlController.text = 'http://localhost:8080/api/';
                  },
                ),
                ActionChip(
                  label: const Text('Android Emulator (10.0.2.2)'),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:8080/api/';
                  },
                ),
                ActionChip(
                  label: const Text('CrownDine Server'),
                  onPressed: () {
                    _urlController.text = 'http://192.168.1.10:8080/api/';
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tự động dùng Mock Data khi offline', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Giữ ứng dụng luôn hoạt động mượt mà ngay cả khi backend Spring Boot chưa bật.'),
                value: _mockFallback,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _mockFallback = val);
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Google OAuth Client ID',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lưu trữ bảo mật cục bộ trên máy, hoàn toàn không đẩy lên Git.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _googleClientIdController,
              decoration: InputDecoration(
                hintText: 'xxx.apps.googleusercontent.com',
                prefixIcon: const Icon(Icons.security),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _googleClientIdController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ping test button
            AppButton(
              text: 'Kiểm tra kết nối tới Server',
              isOutlined: true,
              isLoading: _isTesting,
              icon: Icons.wifi_find,
              onPressed: _testConnection,
            ),

            if (_testMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppColors.successContainer : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _testSuccess ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            AppButton(
              text: 'Lưu cấu hình',
              icon: Icons.save,
              onPressed: _saveConfig,
            ),
          ],
        ),
      ),
    );
  }
}
