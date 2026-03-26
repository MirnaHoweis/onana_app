import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class OutlookStatus {
  const OutlookStatus({required this.connected, this.email});
  final bool connected;
  final String? email;
}

final outlookStatusProvider = FutureProvider<OutlookStatus>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.outlookStatus);
  final data = response.data as Map<String, dynamic>;
  return OutlookStatus(
    connected: data['connected'] as bool? ?? false,
    email: data['email'] as String?,
  );
});

final outlookAuthUrlProvider = FutureProvider.autoDispose<String>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.outlookAuthUrl);
  final data = response.data as Map<String, dynamic>;
  return data['auth_url'] as String;
});
