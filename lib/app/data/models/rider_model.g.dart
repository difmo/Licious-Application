// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rider_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RiderModelImpl _$$RiderModelImplFromJson(Map<String, dynamic> json) =>
    _$RiderModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      profileImage: json['profileImage'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$RiderModelImplToJson(_$RiderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'isActive': instance.isActive,
      'profileImage': instance.profileImage,
      'rating': instance.rating,
    };
