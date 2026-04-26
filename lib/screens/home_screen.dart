import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/password_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../widgets/password_card.dart';
import 'edit_entry_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.sessionKey, super.key});

  final SecretKey sessionKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final vault = context.read<VaultProvider>();
      Future<void>.microtask(() {
        vault.load(widget.sessionKey);
      });
    }
  }

  Future<void> _openEditor([PasswordEntry? entry]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EditEntryScreen(sessionKey: widget.sessionKey, initialEntry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(PasswordEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Supprimer cette entrée ?'),
          content: Text('"${entry.title}" sera supprimé définitivement.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await context.read<VaultProvider>().deleteEntry(
        entry.id,
        widget.sessionKey,
      );
    }
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copié dans le presse-papiers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<VaultProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyrnunnlock'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(sessionKey: widget.sessionKey),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Paramètres',
          ),
          IconButton(
            onPressed: () => context.read<AuthProvider>().lock(),
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Verrouiller',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                onChanged: vault.setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Rechercher (titre ou catégorie)',
                ),
              ),
            ),
            Expanded(
              child: vault.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: vault.filteredEntries.isEmpty
                          ? const _EmptyVault()
                          : ListView.builder(
                              key: const ValueKey<String>('vault_list'),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: vault.filteredEntries.length,
                              itemBuilder: (context, index) {
                                final entry = vault.filteredEntries[index];
                                return PasswordCard(
                                  key: ValueKey<String>(entry.id),
                                  entry: entry,
                                  onCopyUsername: () =>
                                      _copyText('Identifiant', entry.username),
                                  onCopyPassword: () =>
                                      _copyText('Mot de passe', entry.password),
                                  onEdit: () => _openEditor(entry),
                                  onDelete: () => _deleteEntry(entry),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.lock_person_rounded,
              size: 58,
              color: Color(0xFF3DEBFF),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune entrée pour le moment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoute ton premier identifiant pour démarrer.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
