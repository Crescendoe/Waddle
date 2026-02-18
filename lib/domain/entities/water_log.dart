import 'package:equatable/equatable.dart';

/// A single water/drink log entry
class WaterLog extends Equatable {
  final String? id;
  final String drinkName;
  final double amountOz;
  final double waterContentOz;
  final DateTime entryTime;

  const WaterLog({
    this.id,
    required this.drinkName,
    required this.amountOz,
    required this.waterContentOz,
    required this.entryTime,
  });

  WaterLog copyWith({
    String? id,
    String? drinkName,
    double? amountOz,
    double? waterContentOz,
    DateTime? entryTime,
  }) {
    return WaterLog(
      id: id ?? this.id,
      drinkName: drinkName ?? this.drinkName,
      amountOz: amountOz ?? this.amountOz,
      waterContentOz: waterContentOz ?? this.waterContentOz,
      entryTime: entryTime ?? this.entryTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drinkName': drinkName,
      'amount': amountOz,
      'waterContent': waterContentOz,
      'entryTime': entryTime.toIso8601String(),
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map, {String? id}) {
    return WaterLog(
      id: id,
      drinkName: map['drinkName'] as String? ?? 'Water',
      amountOz: (map['amount'] as num?)?.toDouble() ?? 0.0,
      waterContentOz: (map['waterContent'] as num?)?.toDouble() ?? 0.0,
      entryTime: map['entryTime'] != null
          ? DateTime.parse(map['entryTime'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, drinkName, amountOz, waterContentOz, entryTime];
}
