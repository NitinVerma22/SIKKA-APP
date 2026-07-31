import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';

class ConfigService {
  static final String _baseUrl = AuthService.baseUrl.replaceAll('/auth', '/config');

  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Failed to fetch config: $e');
    }
    return null;
  }
}

class AppConfigState {
  final Map<String, dynamic>? config;
  final bool hasChanged;
  final String? initialUpdatedAt;

  AppConfigState({
    this.config,
    this.hasChanged = false,
    this.initialUpdatedAt,
  });

  AppConfigState copyWith({
    Map<String, dynamic>? config,
    bool? hasChanged,
    String? initialUpdatedAt,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      hasChanged: hasChanged ?? this.hasChanged,
      initialUpdatedAt: initialUpdatedAt ?? this.initialUpdatedAt,
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  final ConfigService _configService;
  
  AppConfigNotifier(this._configService) : super(AppConfigState()) {
    fetchConfig(isStartup: true);
  }

  Future<void> fetchConfig({bool isStartup = false}) async {
    final conf = await _configService.getAppConfig();
    if (conf != null) {
      final updatedAt = conf['updatedAt'] as String?;
      if (isStartup) {
        state = AppConfigState(
          config: conf,
          initialUpdatedAt: updatedAt,
          hasChanged: false,
        );
      } else {
        final previousUpdatedAt = state.initialUpdatedAt ?? state.config?['updatedAt'] as String?;
        final changed = previousUpdatedAt != null && updatedAt != null && previousUpdatedAt != updatedAt;
        state = state.copyWith(
          config: conf,
          hasChanged: state.hasChanged || changed,
        );
      }
    }
  }
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
  final configService = ref.watch(configServiceProvider);
  return AppConfigNotifier(configService);
});
