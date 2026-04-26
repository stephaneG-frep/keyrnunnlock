import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/password_entry.dart';
import '../providers/vault_provider.dart';
import '../utils/password_generator.dart';
import '../utils/password_strength.dart';
import 'edit_entry_screen.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({required this.sessionKey, super.key});

  final SecretKey sessionKey;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final Set<String> _busyEntryIds = <String>{};

  Future<void> _openEditor(PasswordEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EditEntryScreen(sessionKey: widget.sessionKey, initialEntry: entry),
      ),
    );
  }

  Future<void> _generateAndReplace(PasswordEntry entry) async {
    if (_busyEntryIds.contains(entry.id)) return;

    setState(() {
      _busyEntryIds.add(entry.id);
    });

    final newPassword = PasswordGenerator.generate(
      length: 20,
      withSymbols: true,
    );
    final updated = entry.copyWith(
      password: newPassword,
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<VaultProvider>().addOrUpdateEntry(
        updated,
        widget.sessionKey,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Mot de passe régénéré'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Entrée: ${entry.title}'),
                const SizedBox(height: 8),
                SelectableText(newPassword),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: newPassword));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nouveau mot de passe copié')),
                  );
                },
                child: const Text('Copier'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyEntryIds.remove(entry.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<VaultProvider>();

    final weakEntries =
        vault.entries
            .where((entry) => PasswordStrength.evaluate(entry.password).isWeak)
            .toList()
          ..sort((a, b) {
            final scoreA = PasswordStrength.evaluate(a.password).score;
            final scoreB = PasswordStrength.evaluate(b.password).score;
            if (scoreA != scoreB) return scoreA.compareTo(scoreB);
            return b.updatedAt.compareTo(a.updatedAt);
          });

    return Scaffold(
      appBar: AppBar(title: const Text('Audit sécurité')),
      body: weakEntries.isEmpty
          ? const _NoWeakPassword()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: weakEntries.length,
              itemBuilder: (context, index) {
                final entry = weakEntries[index];
                final strength = PasswordStrength.evaluate(entry.password);
                final isBusy = _busyEntryIds.contains(entry.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                entry.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: strength.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: strength.color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                strength.label,
                                style: TextStyle(
                                  color: strength.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Identifiant: ${entry.username}'),
                        if (entry.allTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.allTags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF243575),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => _openEditor(entry),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Modifier'),
                            ),
                            FilledButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => _generateAndReplace(entry),
                              icon: isBusy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_fix_high_rounded),
                              label: const Text('Corriger'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NoWeakPassword extends StatelessWidget {
  const _NoWeakPassword();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF70D6A1),
              size: 58,
            ),
            SizedBox(height: 10),
            Text('Aucun mot de passe faible détecté.'),
          ],
        ),
      ),
    );
  }
}
