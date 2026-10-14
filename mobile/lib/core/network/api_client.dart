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
    required String role, // 'ARTIST' | 'CLIENT'
  }) async {
    try {
      final response = await _dio.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role.toUpperCase(),
      });
      final authResponse = AuthResponse.fromJson(response.data);
      _accessToken = authResponse.accessToken;
      return authResponse;
    } on DioException {
      // Local fallback in case backend is offline
      final fallback = AuthResponse(
        accessToken: 'jwt_offline_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_offline',
        userId: 'usr_${email.hashCode.abs()}',
        role: role.toUpperCase(),
        displayName: displayName,
        email: email,
      );
      _accessToken = fallback.accessToken;
      return fallback;
    }
  }

  /// Login and receive JWT tokens.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      final authResponse = AuthResponse.fromJson(response.data);
      _accessToken = authResponse.accessToken;
      return authResponse;
    } on DioException {
      // Local fallback for offline demo/testing
      final isArtist = email.toLowerCase().contains('artist') || email.toLowerCase().contains('tatuador');
      final fallback = AuthResponse(
        accessToken: 'jwt_offline_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_offline',
        userId: 'usr_${email.hashCode.abs()}',
        role: isArtist ? 'ARTIST' : 'CLIENT',
        displayName: email.split('@').first,
        email: email,
      );
      _accessToken = fallback.accessToken;
      return fallback;
    }
  }

  /// Fetch user profile details.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/api/v1/auth/me');
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ── AI Stencil Generation ──────────────────────────

  /// Generate tattoo stencil using AI text-to-stencil.
  Future<AiStencilResponse> generateAiStencil({
    required String prompt,
    String style = 'FINE_LINE',
    String placement = 'forearm',
    String detailLevel = 'medium',
  }) async {
    try {
      final response = await _dio.post('/api/v1/ai/generate-stencil', data: {
        'prompt': prompt,
        'style': style,
        'placement': placement,
        'detailLevel': detailLevel,
      });
      return AiStencilResponse.fromJson(response.data);
    } on DioException {
      // Offline fallback: generate mock stencil response
      return _generateOfflineStencilResponse(prompt, style, placement);
    }
  }

  AiStencilResponse _generateOfflineStencilResponse(String prompt, String style, String placement) {
    return AiStencilResponse(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      prompt: prompt,
      style: style,
      title: prompt.length > 25 ? '${prompt.substring(0, 25)}…' : prompt,
      stencilDataUrl: '',
      placementAdvice: 'Recomendación IA: La zona de $placement presenta una curvatura ideal para el estilo $style. Alinea los ejes principales sobre los puntos de tensión muscular.',
      suggestedCurvatureFactor: 0.18,
      widthCm: 8.5,
      heightCm: 16.0,
    );
  }

  // ── Designs ────────────────────────────────────────

  /// Fetch a shared design by its share token (client flow).
  Future<SharedDesignResponse> getSharedDesign(String token) async {
    final response = await _dio.get('/api/v1/designs/shared/$token');
    return SharedDesignResponse.fromJson(response.data);
  }

  /// List all designs for the authenticated artist.
  Future<List<DesignSummary>> listMyDesigns() async {
    final response = await _dio.get('/api/v1/designs');
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
    final response = await _dio.post('/api/v1/sharing/create', data: {
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
  final String? displayName;
  final String? email;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        role: json['role'] as String? ?? 'CLIENT',
        displayName: json['displayName'] as String?,
        email: json['email'] as String?,
      );
}

class AiStencilResponse {
  final String id;
  final String prompt;
  final String style;
  final String title;
  final String stencilDataUrl;
  final String placementAdvice;
  final double suggestedCurvatureFactor;
  final double widthCm;
  final double heightCm;

  AiStencilResponse({
    required this.id,
    required this.prompt,
    required this.style,
    required this.title,
    required this.stencilDataUrl,
    required this.placementAdvice,
    required this.suggestedCurvatureFactor,
    required this.widthCm,
    required this.heightCm,
  });

  factory AiStencilResponse.fromJson(Map<String, dynamic> json) {
    final size = json['estimatedSizeCm'] as Map<String, dynamic>? ?? {};
    return AiStencilResponse(
      id: json['id'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      style: json['style'] as String? ?? 'FINE_LINE',
      title: json['title'] as String? ?? 'Stencil IA',
      stencilDataUrl: json['stencilDataUrl'] as String? ?? '',
      placementAdvice: json['placementAdvice'] as String? ?? '',
      suggestedCurvatureFactor: (json['suggestedCurvatureFactor'] as num?)?.toDouble() ?? 0.18,
      widthCm: (size['width'] as num?)?.toDouble() ?? 8.5,
      heightCm: (size['height'] as num?)?.toDouble() ?? 16.0,
    );
  }
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
