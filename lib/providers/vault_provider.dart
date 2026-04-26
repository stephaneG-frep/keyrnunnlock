import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../models/password_entry.dart';
import '../services/vault_service.dart';

class VaultProvider extends ChangeNotifier {
  VaultProvider({required VaultService vaultService})
    : _vaultService = vaultService;

  final VaultService _vaultService;

  final List<PasswordEntry> _entries = <PasswordEntry>[];
  bool _isLoading = false;
  String _query = '';

  List<PasswordEntry> get entries => List<PasswordEntry>.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String get query => _query;

  List<PasswordEntry> get filteredEntries {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return entries;
    return entries.where((entry) {
      return entry.title.toLowerCase().contains(normalized) ||
          entry.category.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<void> load(SecretKey key) async {
    _isLoading = true;
    notifyListeners();

    final loaded = await _vaultService.loadEntries(key);
    _entries
      ..clear()
      ..addAll(loaded);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addOrUpdateEntry(PasswordEntry entry, SecretKey key) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _entries.insert(0, entry);
    } else {
      _entries[index] = entry;
    }

    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _vaultService.saveEntries(_entries, key);
  }

  Future<void> deleteEntry(String id, SecretKey key) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _vaultService.saveEntries(_entries, key);
  }

  Future<({int added, int updated, int skipped})> importEntries(
    List<PasswordEntry> importedEntries,
    SecretKey key, {
    required bool replaceExisting,
  }) async {
    if (replaceExisting) {
      _entries
        ..clear()
        ..addAll(importedEntries);
      _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
      await _vaultService.saveEntries(_entries, key);
      return (added: importedEntries.length, updated: 0, skipped: 0);
    }

    var added = 0;
    var updated = 0;
    var skipped = 0;

    final byId = <String, PasswordEntry>{
      for (final entry in _entries) entry.id: entry,
    };

    for (final imported in importedEntries) {
      final current = byId[imported.id];
      if (current == null) {
        byId[imported.id] = imported;
        added++;
      } else if (imported.updatedAt.isAfter(current.updatedAt)) {
        byId[imported.id] = imported;
        updated++;
      } else {
        skipped++;
      }
    }

    _entries
      ..clear()
      ..addAll(byId.values);
    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _vaultService.saveEntries(_entries, key);

    return (added: added, updated: updated, skipped: skipped);
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void clearForLock() {
    _entries.clear();
    _query = '';
    notifyListeners();
  }

  String newEntryId() {
    final random = Random.secure().nextInt(1 << 30);
    return '${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}
