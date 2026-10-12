import 'package:dio/dio.dart';

import '../../shared/models/design_model.dart';

/// HTTP client for the InkSight NestJS backend API.
///
/// Handles authentication, token refresh, and all design/sharing endpoints.
class ApiClient {
  final Dio _dio;
  String? _accessToken;

  ApiClient({
    required String baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // TODO: Implement token refresh on 401
        handler.next(error);
      },
    ));
  }

  /// Set the JWT access token for authenticated requests.
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Clear authentication state.
  void clearAuth() {
    _accessToken = null;
  }

  // ── Auth ───────────────────────────────────────────

  /// Register a new user (artist or client).
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'artist' | 'client'
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': role,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// Login and receive JWT tokens.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    _accessToken = authResponse.accessToken;
    return authResponse;
  }

  // ── Designs ────────────────────────────────────────

  /// Fetch a shared design by its share token (client flow).
  Future<SharedDesignResponse> getSharedDesign(String token) async {
    final response = await _dio.get('/designs/shared/$token');
    return SharedDesignResponse.fromJson(response.data);
  }

  /// List all designs for the authenticated artist.
  Future<List<DesignSummary>> listMyDesigns() async {
    final response = await _dio.get('/designs');
    return (response.data as List)
        .map((json) => DesignSummary.fromJson(json))
        .toList();
  }

  // ── Sharing ────────────────────────────────────────

  /// Generate a share token + QR code for a design (artist flow).
  Future<ShareTokenResponse> createShareToken({
    required String designId,
    int maxUses = 1,
    Duration ttl = const Duration(hours: 24),
  }) async {
    final response = await _dio.post('/sharing/create', data: {
      'designId': designId,
      'maxUses': maxUses,
      'ttlSeconds': ttl.inSeconds,
    });
    return ShareTokenResponse.fromJson(response.data);
  }
}

// ── Response DTOs ──────────────────────────────────────

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        role: json['role'] as String,
      );
}

class SharedDesignResponse {
  final String presignedUrl;
  final DesignMetadata metadata;

  SharedDesignResponse({
    required this.presignedUrl,
    required this.metadata,
  });

  factory SharedDesignResponse.fromJson(Map<String, dynamic> json) =>
      SharedDesignResponse(
        presignedUrl: json['presignedUrl'] as String,
        metadata: DesignMetadata.fromJson(json['metadata']),
      );
}

class DesignMetadata {
  final String id;
  final String title;
  final String style;
  final int widthPx;
  final int heightPx;
  final String artistName;

  DesignMetadata({
    required this.id,
    required this.title,
    required this.style,
    required this.widthPx,
    required this.heightPx,
    required this.artistName,
  });

  factory DesignMetadata.fromJson(Map<String, dynamic> json) => DesignMetadata(
        id: json['id'] as String,
        title: json['title'] as String,
        style: json['style'] as String,
        widthPx: json['widthPx'] as int,
        heightPx: json['heightPx'] as int,
        artistName: json['artistName'] as String,
      );
}

class ShareTokenResponse {
  final String token;
  final String qrCodeDataUrl;
  final DateTime expiresAt;
  final int maxUses;

  ShareTokenResponse({
    required this.token,
    required this.qrCodeDataUrl,
    required this.expiresAt,
    required this.maxUses,
  });

  factory ShareTokenResponse.fromJson(Map<String, dynamic> json) =>
      ShareTokenResponse(
        token: json['token'] as String,
        qrCodeDataUrl: json['qrCodeDataUrl'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        maxUses: json['maxUses'] as int,
      );
}
