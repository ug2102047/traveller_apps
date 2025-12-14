import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String hotelId;
  final String hotelName;
  final String name;
  final String phone;
  final String email;
  final DateTime checkIn;
  final DateTime checkOut;
  final int rooms;
  final String status; // pending, confirmed, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? adminId;
  final String? adminNote;

  Booking({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.hotelName,
    required this.name,
    required this.phone,
    required this.email,
    required this.checkIn,
    required this.checkOut,
    required this.rooms,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.adminId,
    this.adminNote,
  });

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return Booking(
      id: doc.id,
      userId: d['userId'] ?? '',
      hotelId: d['hotelId'] ?? '',
      hotelName: d['hotelName'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      checkIn: toDate(d['checkIn']) ?? DateTime.now(),
      checkOut: toDate(d['checkOut']) ?? DateTime.now(),
      rooms: (d['rooms'] is int)
          ? d['rooms'] as int
          : int.tryParse('${d['rooms']}') ?? 1,
      status: d['status'] ?? 'pending',
      createdAt: toDate(d['created_at']),
      updatedAt: toDate(d['updated_at']),
      adminId: d['adminId'],
      adminNote: d['adminNote'],
    );
  }

  Map<String, dynamic> toMapForSave() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'hotelName': hotelName,
      'name': name,
      'phone': phone,
      'email': email,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'rooms': rooms,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
