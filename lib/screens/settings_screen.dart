import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/backup_file_info.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.sessionKey, super.key});

  final SecretKey sessionKey;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _timeouts = <int>[15, 30, 60, 120, 300];
  final BackupService _backupService = BackupService();

  bool _busy = false;

  Future<void> _exportBackup() async {
    final exportPassword = await _askExportPassword();
    if (exportPassword == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final entries = context.read<VaultProvider>().entries;
      final path = await _backupService.exportEncryptedBackup(
        entries: entries,
        exportPassword: exportPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sauvegarde chiffrée créée: $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur export: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final vault = context.read<VaultProvider>();
    final backup = await _pickBackupFile();
    if (backup == null || !mounted) return;

    final options = await _askImportOptions();
    if (options == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final importedEntries = await _backupService.importEncryptedBackup(
        backupPath: backup.path,
        exportPassword: options.password,
      );

      final result = await vault.importEntries(
        importedEntries,
        widget.sessionKey,
        replaceExisting: options.replaceExisting,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import terminé - ajoutés: ${result.added}, mis à jour: ${result.updated}, ignorés: ${result.skipped}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur import: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackupFromExternalFile() async {
    final vault = context.read<VaultProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['kbl'],
      allowMultiple: false,
      withData: false,
    );

    if (!mounted) return;
    if (picked == null ||
        picked.files.isEmpty ||
        picked.files.single.path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Aucun fichier sélectionné.')),
      );
      return;
    }

    final backupPath = picked.files.single.path!;
    final options = await _askImportOptions();
    if (options == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final importedEntries = await _backupService.importEncryptedBackup(
        backupPath: backupPath,
        exportPassword: options.password,
      );

      final result = await vault.importEntries(
        importedEntries,
        widget.sessionKey,
        replaceExisting: options.replaceExisting,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import externe terminé - ajoutés: ${result.added}, mis à jour: ${result.updated}, ignorés: ${result.skipped}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur import externe: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final backup = await _pickBackupFile();
    if (backup == null || !mounted) return;

    try {
      await Share.shareXFiles(
        <XFile>[XFile(backup.path)],
        text: 'Sauvegarde chiffrée Keyrnunnlock',
        subject: 'Backup Keyrnunnlock',
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible de partager: $error')),
      );
    }
  }

  Future<String?> _askExportPassword() async {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var obscure = true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mot de passe d\'export'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe export',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 8) {
                          return 'Minimum 8 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: const InputDecoration(labelText: 'Confirmer'),
                      validator: (value) {
                        if (value != passwordCtrl.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop(passwordCtrl.text);
                    }
                  },
                  child: const Text('Exporter'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<_ImportOptions?> _askImportOptions() async {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    var replaceExisting = false;
    var obscure = true;

    final result = await showDialog<_ImportOptions>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Importer une sauvegarde'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe export',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mot de passe requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remplacer le coffre actuel'),
                      subtitle: const Text(
                        'Sinon, fusion intelligente des entrées',
                      ),
                      value: replaceExisting,
                      onChanged: (value) =>
                          setState(() => replaceExisting = value),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop(
                        _ImportOptions(
                          password: passwordCtrl.text,
                          replaceExisting: replaceExisting,
                        ),
                      );
                    }
                  },
                  child: const Text('Importer'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<BackupFileInfo?> _pickBackupFile() async {
    final backups = await _backupService.listBackups();
    if (backups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune sauvegarde locale trouvée.')),
        );
      }
      return null;
    }
    if (!mounted) return null;

    return showModalBottomSheet<BackupFileInfo>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: backups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final backup = backups[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: Text(backup.name),
                subtitle: Text(
                  '${backup.createdAt.toLocal()} • ${(backup.sizeBytes / 1024).toStringAsFixed(1)} KB',
                ),
                onTap: () => Navigator.of(context).pop(backup),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: SwitchListTile(
              title: const Text('Déverrouillage biométrique'),
              subtitle: Text(
                auth.biometricsAvailable
                    ? 'Utiliser empreinte ou Face ID si disponible'
                    : 'Biométrie non disponible sur cet appareil',
              ),
              value: auth.biometricsAvailable && auth.biometricsEnabled,
              onChanged: auth.biometricsAvailable
                  ? (value) => auth.setBiometricEnabled(value)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: const Text('Verrouillage automatique'),
              subtitle: const Text('Temps d\'inactivité avant verrouillage'),
              trailing: DropdownButton<int>(
                value: auth.lockTimeoutSeconds,
                items: _timeouts
                    .map(
                      (s) =>
                          DropdownMenuItem<int>(value: s, child: Text('${s}s')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    auth.setLockTimeoutSeconds(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Exporter sauvegarde chiffrée'),
              subtitle: const Text(
                'Créer un backup local protégé par mot de passe',
              ),
              enabled: !_busy,
              onTap: _busy ? null : _exportBackup,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_for_offline_rounded),
              title: const Text('Importer sauvegarde chiffrée'),
              subtitle: const Text(
                'Restaurer via fusion ou remplacement du coffre',
              ),
              enabled: !_busy,
              onTap: _busy ? null : _importBackup,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_open_rounded),
              title: const Text('Importer depuis un fichier'),
              subtitle: const Text('Sélectionner un fichier .kbl externe'),
              enabled: !_busy,
              onTap: _busy ? null : _importBackupFromExternalFile,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Partager une sauvegarde'),
              subtitle: const Text('Ouvrir la feuille de partage système'),
              enabled: !_busy,
              onTap: _busy ? null : _shareBackup,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_rounded),
              title: const Text('Verrouiller maintenant'),
              onTap: () {
                auth.lock();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportOptions {
  const _ImportOptions({required this.password, required this.replaceExisting});

  final String password;
  final bool replaceExisting;
}
