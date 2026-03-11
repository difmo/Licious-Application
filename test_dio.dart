import 'package:dio/dio.dart';
void main() {
  final dio = Dio(BaseOptions(baseUrl: 'https://shrimpbite-backend.vercel.app/api'));
  final req = dio.options.compose(
    dio.options,
    '/app/cart',
  );
  print(req.uri.toString());
}
