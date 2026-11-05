import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/candidate.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/photo_repository.dart';

class CandidateState extends ChangeNotifier {
  CandidateState(this._repo, this._photos) {
    _subscription = _repo.watchAll().listen(
          (list) {
        _candidates = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load candidates.';
        notifyListeners();
      },
    );
  }

  final CandidateRepository _repo;
  final PhotoRepository _photos;
  StreamSubscription<List<Candidate>>? _subscription;

  List<Candidate> _candidates = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  List<Candidate> get candidates => _candidates;
  bool get loading => _loading;
  String? get error => _error;
  String get filter => _filter;

  int get totalVotes => _candidates.fold<int>(0, (s, c) => s + c.votes);

  List<Candidate> get visible {
    if (_filter == 'voted') return _candidates.where((c) => c.votes > 0).toList();
    return _candidates;
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  // UPDATED: Now takes a photoUrl
  Future<void> add(String name, String? photoUrl) => _repo.add(name, photoUrl);
  Future<void> delete(String id) => _repo.delete(id);
  Future<void> vote(String id) => _repo.vote(id);

  // NEW: Upload photo method
  Future<String> uploadPhoto(File photo) => _photos.upload(photo);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}