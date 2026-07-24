import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';

class AdminShell extends StatelessWidget {
  AdminShell({required this.title, required this.child, super.key})
    : _authRepository = FirebaseAuthRepository();

  final String title;
  final Widget child;
  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('Journal Trend Admin')),
            _NavTile(
              label: 'Dashboard',
              routeName: AdminRoutes.dashboard,
              icon: Icons.dashboard_outlined,
            ),
            _NavTile(
              label: 'Users',
              routeName: AdminRoutes.users,
              icon: Icons.people_alt_outlined,
            ),
            _NavTile(
              label: 'Firestore',
              routeName: AdminRoutes.firestoreCollections,
              icon: Icons.storage_outlined,
            ),
            _NavTile(
              label: 'Storage',
              routeName: AdminRoutes.storage,
              icon: Icons.folder_outlined,
            ),
            _NavTile(
              label: 'Config',
              routeName: AdminRoutes.appConfig,
              icon: Icons.tune_outlined,
            ),
            _NavTile(
              label: 'Analytics',
              routeName: AdminRoutes.analytics,
              icon: Icons.analytics_outlined,
            ),
            _NavTile(
              label: 'Messaging',
              routeName: AdminRoutes.messaging,
              icon: Icons.campaign_outlined,
            ),
            _NavTile(
              label: 'Audit Logs',
              routeName: AdminRoutes.auditLogs,
              icon: Icons.history_outlined,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(title),
        actions: [
          StreamBuilder(
            stream: _authRepository.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  await _authRepository.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AdminRoutes.login,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
              );
            },
          ),
        ],
      ),
      body: child,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.routeName,
    required this.icon,
  });

  final String label;
  final String routeName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(routeName);
      },
    );
  }
}
