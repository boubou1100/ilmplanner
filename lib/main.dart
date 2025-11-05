import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilmplanner/app_router.dart';
import 'package:ilmplanner/providers/providers.dart';

// Importer les services
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(seconds: 3));

  // Initialiser les services
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Charger automatiquement les données sauvegardées au démarrage
    final autoLoad = ref.watch(autoLoadProvider);
    final router = ref.watch(routerProvider);

    // Afficher un écran de chargement pendant que les données sont chargées
    return autoLoad.when(
      data: (_) => MaterialApp.router(
        title: 'Ilm Planner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
      loading: () => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Chargement...'),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erreur: $error'),
          ),
        ),
      ),
    );
  }
}