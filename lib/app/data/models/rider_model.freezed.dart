// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rider_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RiderModel _$RiderModelFromJson(Map<String, dynamic> json) {
  return _RiderModel.fromJson(json);
}

/// @nodoc
mixin _$RiderModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get profileImage => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;

  /// Serializes this RiderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RiderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RiderModelCopyWith<RiderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RiderModelCopyWith<$Res> {
  factory $RiderModelCopyWith(
          RiderModel value, $Res Function(RiderModel) then) =
      _$RiderModelCopyWithImpl<$Res, RiderModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? email,
      String? phone,
      bool isActive,
      String? profileImage,
      double rating});
}

/// @nodoc
class _$RiderModelCopyWithImpl<$Res, $Val extends RiderModel>
    implements $RiderModelCopyWith<$Res> {
  _$RiderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RiderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? isActive = null,
    Object? profileImage = freezed,
    Object? rating = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RiderModelImplCopyWith<$Res>
    implements $RiderModelCopyWith<$Res> {
  factory _$$RiderModelImplCopyWith(
          _$RiderModelImpl value, $Res Function(_$RiderModelImpl) then) =
      __$$RiderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? email,
      String? phone,
      bool isActive,
      String? profileImage,
      double rating});
}

/// @nodoc
class __$$RiderModelImplCopyWithImpl<$Res>
    extends _$RiderModelCopyWithImpl<$Res, _$RiderModelImpl>
    implements _$$RiderModelImplCopyWith<$Res> {
  __$$RiderModelImplCopyWithImpl(
      _$RiderModelImpl _value, $Res Function(_$RiderModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RiderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? isActive = null,
    Object? profileImage = freezed,
    Object? rating = null,
  }) {
    return _then(_$RiderModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RiderModelImpl implements _RiderModel {
  const _$RiderModelImpl(
      {required this.id,
      required this.name,
      this.email,
      this.phone,
      this.isActive = false,
      this.profileImage,
      this.rating = 0.0});

  factory _$RiderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RiderModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? profileImage;
  @override
  @JsonKey()
  final double rating;

  @override
  String toString() {
    return 'RiderModel(id: $id, name: $name, email: $email, phone: $phone, isActive: $isActive, profileImage: $profileImage, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RiderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.rating, rating) || other.rating == rating));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, email, phone, isActive, profileImage, rating);

  /// Create a copy of RiderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RiderModelImplCopyWith<_$RiderModelImpl> get copyWith =>
      __$$RiderModelImplCopyWithImpl<_$RiderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RiderModelImplToJson(
      this,
    );
  }
}

abstract class _RiderModel implements RiderModel {
  const factory _RiderModel(
      {required final String id,
      required final String name,
      final String? email,
      final String? phone,
      final bool isActive,
      final String? profileImage,
      final double rating}) = _$RiderModelImpl;

  factory _RiderModel.fromJson(Map<String, dynamic> json) =
      _$RiderModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get email;
  @override
  String? get phone;
  @override
  bool get isActive;
  @override
  String? get profileImage;
  @override
  double get rating;

  /// Create a copy of RiderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RiderModelImplCopyWith<_$RiderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
