import 'package:dio/dio.dart';
import 'package:absensi/model/register_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: 'https://absensib1.mobileprojp.com')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/api/register')
  Future<RegisterModel> registerUser(@Body() RegisterModel registerData);

  @POST('/api/login')
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST('/api/absen/check-in')
  Future<dynamic> checkIn(@Body() Map<String, dynamic> body);

  @POST('/api/absen/check-out')
  Future<dynamic> checkOut(@Body() Map<String, dynamic> body);

  @GET('/api/absen/history')
  Future<dynamic> getAbsenHistory(
    @Query('start') String start,
    @Query('end') String end,
  );
}
