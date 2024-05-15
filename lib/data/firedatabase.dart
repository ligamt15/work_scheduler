import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker.dart';

class MyDatabaseService {
  final CollectionReference workerCollection =
      FirebaseFirestore.instance.collection('workers');

  Future<void> saveWorker(String id, Map<String, dynamic> data) {
    return workerCollection.doc(id).set(data);
  }

  Stream<QuerySnapshot> loadWorkers() {
    return workerCollection.snapshots();
  }

  Future<List<Worker>> getWorkers() async {
    var snapshot = await workerCollection.get();
    return snapshot.docs
        .map((doc) => Worker.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteWorker(String email) async {
    try {
      var snapshot =
          await workerCollection.where('email', isEqualTo: email).get();
      if (snapshot.docs.isNotEmpty) {
        var docId = snapshot.docs.first.id;
        await workerCollection.doc(docId).delete();
      } else {
        print('Worker not found in Firestore!');
      }
    } catch (e) {
      print('Error deleting worker: $e');
    }
  }
}
