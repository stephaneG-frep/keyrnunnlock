import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/password_entry.dart';
import '../providers/vault_provider.dart';
import '../utils/password_generator.dart';
import '../utils/password_strength.dart';
import '../utils/validators.dart';

class EditEntryScreen extends StatefulWidget {
  const EditEntryScreen({
    required this.sessionKey,
    this.initialEntry,
    super.key,
  });

  final SecretKey sessionKey;
  final PasswordEntry? initialEntry;

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _noteCtrl;

  bool _obscurePassword = true;

  bool get _isEdit => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialEntry?.title ?? '');
    _usernameCtrl = TextEditingController(
      text: widget.initialEntry?.username ?? '',
    );
    _passwordCtrl = TextEditingController(
      text: widget.initialEntry?.password ?? '',
    );
    _urlCtrl = TextEditingController(text: widget.initialEntry?.url ?? '');
    _categoryCtrl = TextEditingController(
      text: widget.initialEntry?.category ?? '',
    );
    _tagsCtrl = TextEditingController(
      text: widget.initialEntry?.tags.join(', ') ?? '',
    );
    _noteCtrl = TextEditingController(text: widget.initialEntry?.note ?? '');

    _passwordCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _titleCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _categoryCtrl.dispose();
    _tagsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vault = context.read<VaultProvider>();
    final now = DateTime.now();
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    final category = _categoryCtrl.text.trim();
    final normalizedTags = tags.where((t) => t != category).toList();

    final entry = PasswordEntry(
      id: widget.initialEntry?.id ?? vault.newEntryId(),
      title: _titleCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      url: _urlCtrl.text.trim(),
      category: category,
      tags: normalizedTags,
      note: _noteCtrl.text.trim(),
      createdAt: widget.initialEntry?.createdAt ?? now,
      updatedAt: now,
    );

    await vault.addOrUpdateEntry(entry, widget.sessionKey);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _generatePassword() {
    setState(() {
      _passwordCtrl.text = PasswordGenerator.generate();
      _obscurePassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrength.evaluate(_passwordCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier entrée' : 'Nouvelle entrée'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _titleCtrl,
                  validator: (value) =>
                      Validators.requiredField(value, 'Titre'),
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameCtrl,
                  validator: (value) =>
                      Validators.requiredField(value, 'Identifiant'),
                  decoration: const InputDecoration(labelText: 'Identifiant'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  validator: (value) =>
                      Validators.requiredField(value, 'Mot de passe'),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: Wrap(
                      spacing: 2,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          tooltip: 'Générer',
                          onPressed: _generatePassword,
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          tooltip: _obscurePassword ? 'Afficher' : 'Masquer',
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: <Widget>[
                      const Text('Force: '),
                      Text(
                        strength.label,
                        style: TextStyle(
                          color: strength.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL (optionnel)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie principale (optionnel)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (optionnel, séparés par virgule)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnel)',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      _isEdit ? 'Enregistrer les modifications' : 'Ajouter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
