import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<int> _timeouts = <int>[15, 30, 60, 120, 300];

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
                      (s) => DropdownMenuItem<int>(
                        value: s,
                        child: Text('${s}s'),
                      ),
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
