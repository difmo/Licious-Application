import 'package:dio/dio.dart';
void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.shrimpbite.in/api'));
  try {
    await dio.get('/app/cart');
  } on DioException catch (e) {
    print('Requested URI: \${e.requestOptions.uri}');
  }
}
