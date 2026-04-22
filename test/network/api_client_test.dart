import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licius_application/app/data/network/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ApiClient apiClient;
  late MockDio mockDio;

  setUpAll(() async {
    // Setup dotenv with dummy value if needed
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.example.com');
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    // In our ApiClient, we pass Dio to the constructor
    apiClient = ApiClient(mockDio);
  });

  group('ApiClient Tests', () {
    test('GET request returning 404 should throw ApiException with 404 status code', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/test');
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
            data: {'message': 'Not Found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.get('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
   group('Error Handling', () {
      test('Connection timeout should throw ApiException with appropriate message', () async {
        when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => apiClient.get('/timeout'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('timed out'))),
        );
      });
    });
  });
}
