import 'package:dio/dio.dart';

abstract class HttpStrategy {
  void init(Dio dio, int timeOut);

  Future<Response> post(
      {Dio dio,
      int timeOut,
      String path,
      Map data,
      CancelToken cancelToken,
      Options options});
}
