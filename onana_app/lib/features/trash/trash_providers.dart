import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final trashProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/trash');
  return response.data!;
});

Future<void> restoreTrashItem(String type, String id) async {
  await ApiClient.instance.post<dynamic>('/trash/$type/$id/restore');
}

Future<void> permanentlyDelete(String type, String id) async {
  await ApiClient.instance.delete<dynamic>('/trash/$type/$id');
}
