import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚀 ENHANCED CONTACT ENTITY WITH SERIALIZATION
/// Supports caching with GetStorage
class ContactEntityV2 {
  String? id;
  String? user_token;
  String? contact_token;
  String? user_name;
  String? user_avatar;
  int? user_online;
  String? contact_name;
  String? contact_avatar;
  int? contact_online;
  String? status;
  String? requested_by;
  Timestamp? requested_at;
  Timestamp? accepted_at;
  Timestamp? blocked_at;
  
  ContactEntityV2({
    this.id,
    this.user_token,
    this.contact_token,
    this.user_name,
    this.user_avatar,
    this.user_online,
    this.contact_name,
    this.contact_avatar,
    this.contact_online,
    this.status,
    this.requested_by,
    this.requested_at,
    this.accepted_at,
    this.blocked_at,
  });
  
  /// Serialize to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_token': user_token,
      'contact_token': contact_token,
      'user_name': user_name,
      'user_avatar': user_avatar,
      'user_online': user_online,
      'contact_name': contact_name,
      'contact_avatar': contact_avatar,
      'contact_online': contact_online,
      'status': status,
      'requested_by': requested_by,
      'requested_at': requested_at?.millisecondsSinceEpoch,
      'accepted_at': accepted_at?.millisecondsSinceEpoch,
      'blocked_at': blocked_at?.millisecondsSinceEpoch,
    };
  }
  
  /// Deserialize from JSON (for cache retrieval)
  factory ContactEntityV2.fromJson(Map<String, dynamic> json) {
    return ContactEntityV2(
      id: json['id'],
      user_token: json['user_token'],
      contact_token: json['contact_token'],
      user_name: json['user_name'],
      user_avatar: json['user_avatar'],
      user_online: json['user_online'],
      contact_name: json['contact_name'],
      contact_avatar: json['contact_avatar'],
      contact_online: json['contact_online'],
      status: json['status'],
      requested_by: json['requested_by'],
      requested_at: json['requested_at'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['requested_at'])
          : null,
      accepted_at: json['accepted_at'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['accepted_at'])
          : null,
      blocked_at: json['blocked_at'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['blocked_at'])
          : null,
    );
  }
  
  /// Create from Firestore document
  factory ContactEntityV2.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactEntityV2(
      id: doc.id,
      user_token: data['user_token'],
      contact_token: data['contact_token'],
      user_name: data['user_name'],
      user_avatar: data['user_avatar'],
      user_online: data['user_online'],
      contact_name: data['contact_name'],
      contact_avatar: data['contact_avatar'],
      contact_online: data['contact_online'],
      status: data['status'],
      requested_by: data['requested_by'],
      requested_at: data['requested_at'],
      accepted_at: data['accepted_at'],
      blocked_at: data['blocked_at'],
    );
  }
}
