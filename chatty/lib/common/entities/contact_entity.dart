import 'package:cloud_firestore/cloud_firestore.dart';

// Contact entity for managing contact relationships
class ContactEntity {
  String? id;
  String? user_token;
  String? contact_token;
  String? user_name;
  String? user_avatar;
  int? user_online;
  String? contact_name;
  String? contact_avatar;
  int? contact_online;
  String? status; // pending, accepted, blocked
  String? requested_by;
  Timestamp? requested_at;
  Timestamp? accepted_at;
  Timestamp? blocked_at;

  ContactEntity({
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

  factory ContactEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ContactEntity(
      id: snapshot.id,
      user_token: data?['user_token'],
      contact_token: data?['contact_token'],
      user_name: data?['user_name'],
      user_avatar: data?['user_avatar'],
      user_online: data?['user_online'],
      contact_name: data?['contact_name'],
      contact_avatar: data?['contact_avatar'],
      contact_online: data?['contact_online'],
      status: data?['status'],
      requested_by: data?['requested_by'],
      requested_at: data?['requested_at'],
      accepted_at: data?['accepted_at'],
      blocked_at: data?['blocked_at'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (user_token != null) "user_token": user_token,
      if (contact_token != null) "contact_token": contact_token,
      if (user_name != null) "user_name": user_name,
      if (user_avatar != null) "user_avatar": user_avatar,
      if (user_online != null) "user_online": user_online,
      if (contact_name != null) "contact_name": contact_name,
      if (contact_avatar != null) "contact_avatar": contact_avatar,
      if (contact_online != null) "contact_online": contact_online,
      if (status != null) "status": status,
      if (requested_by != null) "requested_by": requested_by,
      if (requested_at != null) "requested_at": requested_at,
      if (accepted_at != null) "accepted_at": accepted_at,
      if (blocked_at != null) "blocked_at": blocked_at,
    };
  }
}

// User profile entity for search functionality
class UserProfile {
  String? token;
  String? name;
  String? avatar;
  String? email;
  int? online;
  String? search_name;

  UserProfile({
    this.token,
    this.name,
    this.avatar,
    this.email,
    this.online,
    this.search_name,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserProfile(
      token: data?['token'],
      name: data?['name'],
      avatar: data?['avatar'],
      email: data?['email'],
      online: _toInt(data?['online']),
      search_name: data?['search_name'],
    );
  }

  // Helper to convert bool/int to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (token != null) "token": token,
      if (name != null) "name": name,
      if (avatar != null) "avatar": avatar,
      if (email != null) "email": email,
      if (online != null) "online": online,
      if (search_name != null) "search_name": search_name,
    };
  }
}
