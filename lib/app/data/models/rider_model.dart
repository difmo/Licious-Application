import 'package:freezed_annotation/freezed_annotation.dart';

part 'rider_model.freezed.dart';
part 'rider_model.g.dart';

@freezed
class RiderModel with _$RiderModel {
  const factory RiderModel({
    required String id,
    required String name,
    String? email,
    String? phone,
    @Default(false) bool isActive,
    String? profileImage,
    @Default(0.0) double rating,
  }) = _RiderModel;

  factory RiderModel.fromJson(Map<String, dynamic> json) =>
      _$RiderModelFromJson(json);
}
