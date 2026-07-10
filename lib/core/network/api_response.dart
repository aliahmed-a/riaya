/// Standardized API response wrapper matching the ASP.NET Core backend envelope.
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  /// Factory constructor to parse raw maps with a dynamic custom type decoder function.
  /// [fromJsonT] parses the nested generic `data` property if it exists.
  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json)? fromJsonT,
      ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}