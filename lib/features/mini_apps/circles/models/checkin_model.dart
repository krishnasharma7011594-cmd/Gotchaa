import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInModel {

  CheckInModel({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.circleId,
    required this.checkInTime,
    required this.method,
    required this.isVerified,
  });

  factory CheckInModel.fromMap(Map<String, dynamic> map) => CheckInModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userAvatar: map['userAvatar'] ?? '',
      circleId: map['circleId'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: map['method'] ?? 'proximity',
      isVerified: map['isVerified'] ?? false,
    );
  final String userId;
  final String userName;
  final String userAvatar;
  final String circleId;
  final DateTime checkInTime;
  final String method; // 'qr' | 'proximity'
  final bool isVerified;

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'circleId': circleId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'method': method,
      'isVerified': isVerified,
    };
}
