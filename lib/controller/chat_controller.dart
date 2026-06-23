import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection("chatsData")
          .add(data);

      print("✅ Message sent successfully");

    } catch (e) {
      print("❌ Firestore Send Error: $e");
    }
  }

  Future<void> deleteMessage({
    required String id,
  }) async {
    await _firestore.collection("chatsData").doc(id).delete();
  }

  Future<void> updateMessage({
    required String id,
    required Map<String, dynamic> updatedData,
  }) async {
    await _firestore.collection("chatsData").doc(id).update(updatedData);
  }

  // ✅ Delete all messages (Delete chat)
  Future<void> deleteAllMessages() async {
    final snapshot = await _firestore.collection("chatsData").get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ✅ Delete messages only for user
  Future<void> deleteMessagesByUserId(String userId) async {
    final snapshot = await _firestore
        .collection("chatsData")
        .where("userId", isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
