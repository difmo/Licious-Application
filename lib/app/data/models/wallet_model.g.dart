// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletModelImpl _$$WalletModelImplFromJson(Map<String, dynamic> json) =>
    _$WalletModelImpl(
      userId: json['userId'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map(
                  (e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currency: json['currency'] as String?,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$WalletModelImplToJson(_$WalletModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'balance': instance.balance,
      'transactions': instance.transactions,
      'currency': instance.currency,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

_$WalletTransactionImpl _$$WalletTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletTransactionImpl(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$WalletTransactionImplToJson(
        _$WalletTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'type': instance.type,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'description': instance.description,
    };
