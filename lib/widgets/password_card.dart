import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../utils/password_strength.dart';

class PasswordCard extends StatefulWidget {
  const PasswordCard({
    required this.entry,
    required this.onCopyUsername,
    required this.onCopyPassword,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final PasswordEntry entry;
  final VoidCallback onCopyUsername;
  final VoidCallback onCopyPassword;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  bool _revealPassword = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = PasswordStrength.evaluate(widget.entry.password);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.entry.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _strengthTag(strength),
              ],
            ),
            if (widget.entry.allTags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.entry.allTags.map(_tag).toList(),
              ),
            ],
            const SizedBox(height: 12),
            _infoRow(
              label: 'Identifiant',
              value: widget.entry.username,
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: widget.onCopyUsername,
                tooltip: 'Copier identifiant',
              ),
            ),
            _infoRow(
              label: 'Mot de passe',
              value: _revealPassword
                  ? widget.entry.password
                  : '•' * (widget.entry.password.length.clamp(8, 18)),
              trailing: Wrap(
                spacing: 2,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      _revealPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() => _revealPassword = !_revealPassword);
                    },
                    tooltip: _revealPassword ? 'Masquer' : 'Afficher',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all_rounded),
                    onPressed: widget.onCopyPassword,
                    tooltip: 'Copier mot de passe',
                  ),
                ],
              ),
            ),
            if (widget.entry.url.trim().isNotEmpty)
              _smallText('URL: ${widget.entry.url}'),
            if (widget.entry.note.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _smallText('Note: ${widget.entry.note}'),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _tag(String category) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF243575),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _strengthTag(PasswordStrengthResult strength) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: strength.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: strength.color.withValues(alpha: 0.6)),
      ),
      child: Text(
        strength.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: strength.color,
        ),
      ),
    );
  }

  Widget _smallText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFFB4C2F1), fontSize: 12.5),
    );
  }
}
