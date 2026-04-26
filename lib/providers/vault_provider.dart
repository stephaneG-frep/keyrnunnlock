import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../models/password_entry.dart';
import '../services/vault_service.dart';
import '../utils/password_strength.dart';

enum VaultSortMode { updatedDesc, updatedAsc, titleAsc, titleDesc, weakFirst }

class VaultProvider extends ChangeNotifier {
  VaultProvider({required VaultService vaultService})
    : _vaultService = vaultService;

  final VaultService _vaultService;

  final List<PasswordEntry> _entries = <PasswordEntry>[];
  bool _isLoading = false;
  String _query = '';
  VaultSortMode _sortMode = VaultSortMode.updatedDesc;
  bool _showWeakOnly = false;

  List<PasswordEntry> get entries => List<PasswordEntry>.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String get query => _query;
  VaultSortMode get sortMode => _sortMode;
  bool get showWeakOnly => _showWeakOnly;

  int get weakCount {
    return _entries
        .where((e) => PasswordStrength.evaluate(e.password).isWeak)
        .length;
  }

  List<PasswordEntry> get filteredEntries {
    final normalized = _query.trim().toLowerCase();

    var list = entries.where((entry) {
      final bySearch = normalized.isEmpty
          ? true
          : entry.title.toLowerCase().contains(normalized) ||
                entry.category.toLowerCase().contains(normalized) ||
                entry.allTags.any(
                  (tag) => tag.toLowerCase().contains(normalized),
                );

      final byWeak =
          !_showWeakOnly || PasswordStrength.evaluate(entry.password).isWeak;

      return bySearch && byWeak;
    }).toList();

    switch (_sortMode) {
      case VaultSortMode.updatedDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case VaultSortMode.updatedAsc:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case VaultSortMode.titleAsc:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case VaultSortMode.titleDesc:
        list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
      case VaultSortMode.weakFirst:
        list.sort((a, b) {
          final sa = PasswordStrength.evaluate(a.password).score;
          final sb = PasswordStrength.evaluate(b.password).score;
          if (sa != sb) return sa.compareTo(sb);
          return b.updatedAt.compareTo(a.updatedAt);
        });
    }

    return list;
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
    notifyListeners();
    await _vaultService.saveEntries(_entries, key);

    return (added: added, updated: updated, skipped: skipped);
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setSortMode(VaultSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  void toggleWeakOnly() {
    _showWeakOnly = !_showWeakOnly;
    notifyListeners();
  }

  void clearForLock() {
    _entries.clear();
    _query = '';
    _showWeakOnly = false;
    _sortMode = VaultSortMode.updatedDesc;
    notifyListeners();
  }

  String newEntryId() {
    final random = Random.secure().nextInt(1 << 30);
    return '${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}
