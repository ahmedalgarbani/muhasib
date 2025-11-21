abstract class DatabaseService {
  Future<void> addData({required String path,required Map<String, String> data,String? documentId});
  Future<dynamic> getData({ 
    required String path,
    String? documentId,
    Map<String, dynamic>? query
    });
}
