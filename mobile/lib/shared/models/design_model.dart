/// Simple design model for the mobile client.
/// Mirrors the backend DesignSummary DTO.
class DesignSummary {
  final String id;
  final String title;
  final String style;
  final String? thumbnailUrl;
  final int widthPx;
  final int heightPx;
  final DateTime createdAt;

  DesignSummary({
    required this.id,
    required this.title,
    required this.style,
    this.thumbnailUrl,
    required this.widthPx,
    required this.heightPx,
    required this.createdAt,
  });

  factory DesignSummary.fromJson(Map<String, dynamic> json) => DesignSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        style: json['style'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        widthPx: json['widthPx'] as int,
        heightPx: json['heightPx'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
