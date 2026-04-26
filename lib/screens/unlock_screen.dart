import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/aurora_background.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final ok = await context.read<AuthProvider>().unlockWithPassword(_passwordCtrl.text);

    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe maître incorrect.')),
      );
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() => _busy = true);
    final ok = await context.read<AuthProvider>().unlockWithBiometrics();

    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déverrouillage biométrique indisponible pour cette session.'),
        ),
      );
    }
  }

  Future<void> _confirmResetVault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Réinitialiser le coffre ?'),
          content: const Text(
            'Cette action supprime toutes les données locales (mots de passe inclus) et te permettra de recréer un mot de passe maître.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Tout effacer'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    await context.read<AuthProvider>().resetVault();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Icon(Icons.shield_moon_rounded, size: 52, color: Color(0xFF7759FF)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onLongPress: _busy ? null : _confirmResetVault,
                            child: Text(
                              'Coffre verrouillé',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Entre ton mot de passe maître pour continuer.'),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.visiblePassword,
                            validator: Validators.masterPassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe maître',
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _unlockWithPassword(),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _busy ? null : _unlockWithPassword,
                            icon: const Icon(Icons.lock_open_rounded),
                            label: const Text('Déverrouiller'),
                          ),
                          if (auth.biometricsAvailable && auth.biometricsEnabled) ...<Widget>[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _unlockWithBiometrics,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Utiliser la biométrie'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
