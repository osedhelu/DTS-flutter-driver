import 'package:dio/dio.dart';

import '../../../../core/utils/pagination.dart';
import '../models/store_dto.dart';

class StoresRemoteDataSource {
  const StoresRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<StoreDto>> fetchStores({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    final response = await _dio.get<dynamic>(
      '/stores/',
      queryParameters: query.isEmpty ? null : query,
    );
    return parsePaginatedList(response.data, StoreDto.fromJson);
  }
}
