import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate.dart';

class CandidateRepository {
  CandidateRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _candidates =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('candidates');

  Stream<List<Candidate>> watchAll() => _candidates
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Candidate.fromDoc).toList());

  // UPDATED: Now takes a photoUrl
  Future<void> add(String name, String? photoUrl) => _candidates.add({
    'name': name,
    'votes': 0,
    'photoUrl': photoUrl,
  });

  Future<void> delete(String id) => _candidates.doc(id).delete();

  Future<void> vote(String id) => _candidates.doc(id).update({
    'votes': FieldValue.increment(1),
  });

  Future<void> addSamples() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final name in ['Keza', 'Mutoni', 'Gisa']) {
      batch.set(_candidates.doc(), {'name': name, 'votes': 0, 'photoUrl': null});
    }
    await batch.commit();
  }
}