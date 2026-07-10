import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'api_response.dart';

class LookupResource {
  final int id;
  final String name;

  LookupResource({required this.id, required this.name});

  factory LookupResource.fromJson(Map<String, dynamic> json) {
    return LookupResource(
      id: json['id'] as int,
      name: (json['name'] ?? json['fullName'] ?? '') as String,
    );
  }
}

final dynamicDoctorsProvider = FutureProvider<List<LookupResource>>((ref) async {
  final dioClient = ref.watch(dioClientProvider);

  // Doctors is a paginated endpoint (backed by PagedResponse<DoctorDto>),
  // so we must explicitly ask for a page big enough to cover all doctors.
  // 50 is the backend's hard max page size (see PaginationParams.MaxPageSize).
  final response = await dioClient.dio.get(
    'Doctors',
    queryParameters: {'PageNumber': 1, 'PageSize': 50},
  );

  final apiResponse = ApiResponse<dynamic>.fromJson(
    response.data as Map<String, dynamic>,
        (json) => json,
  );

  if (apiResponse.success && apiResponse.data != null) {
    // The Doctors endpoint wraps its list in a PagedResponse envelope:
    // { "items": [...], "pageNumber": 1, "pageSize": 50, "totalCount": .. }
    // so the list lives under "items", not at the top level of "data".
    final data = apiResponse.data;
    final List<dynamic> rawList = data is Map<String, dynamic>
        ? (data['items'] as List<dynamic>? ?? [])
        : data as List<dynamic>;

    return rawList.map((item) => LookupResource.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Failed to parse doctors list');
  }
});

final dynamicRoomsProvider = FutureProvider<List<LookupResource>>((ref) async {
  final dioClient = ref.watch(dioClientProvider);
  final response = await dioClient.dio.get('ClinicRooms');

  final apiResponse = ApiResponse<dynamic>.fromJson(
    response.data as Map<String, dynamic>,
        (json) => json,
  );

  if (apiResponse.success && apiResponse.data != null) {
    // ClinicRoomsController returns Task<List<ClinicRoomDto>> — no pagination —
    // so this stays a bare array under "data". No change needed here.
    final List<dynamic> rawList = apiResponse.data as List<dynamic>;
    return rawList.map((item) => LookupResource.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception(apiResponse.message.isNotEmpty ? apiResponse.message : 'Failed to parse clinic rooms list');
  }
});