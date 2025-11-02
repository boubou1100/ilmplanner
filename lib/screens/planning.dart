import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ilmplanner/providers/providers.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  Future<void> _showNotificationSettings(BuildContext context, WidgetRef ref) async {
    final currentTime = ref.read(notificationTimeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heure actuelle: ${currentTime.hour}h${currentTime.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Testez les notifications ou configurez l\'heure de rappel quotidien.',
            ),
          ],
        ),
        actions: [
          // Bouton de test commenté
          /* TextButton.icon(
            icon: const Icon(Icons.science),
            label: const Text('Tester'),
            onPressed: () async {
              Navigator.of(context).pop();
              final notificationService = ref.read(notificationServiceProvider);

              try {
                await notificationService.showNotification(
                  title: '📚 Test de notification',
                  body: 'Les notifications fonctionnent correctement ! 🎉',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification de test envoyée !'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ), */
          TextButton.icon(
            icon: const Icon(Icons.list),
            label: const Text('Voir les notifications'),
            onPressed: () async {
              Navigator.of(context).pop();
              final notificationService = ref.read(notificationServiceProvider);

              try {
                final pending = await notificationService.getPendingNotifications();

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('📋 Notifications programmées'),
                      content: pending.isEmpty
                          ? const Text('Aucune notification programmée.')
                          : SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: pending.length,
                                itemBuilder: (context, index) {
                                  final notif = pending[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${notif.id}'),
                                    ),
                                    title: Text(notif.title ?? 'Sans titre'),
                                    subtitle: Text(notif.body ?? ''),
                                    dense: true,
                                  );
                                },
                              ),
                            ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text('Configurer'),
            onPressed: () async {
              Navigator.of(context).pop();

              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: currentTime,
              );

              if (pickedTime != null && context.mounted) {
                final newTime = TimeOfDay(hour: pickedTime.hour, minute: pickedTime.minute);
                ref.read(notificationTimeProvider.notifier).state = newTime;

                // Sauvegarder l'heure
                final storage = ref.read(storageServiceProvider);
                await storage.saveNotificationTime(newTime);

                // Programmer les notifications
                final readingPlan = ref.read(readingPlanProvider);
                if (readingPlan != null) {
                  final notificationService = ref.read(notificationServiceProvider);
                  final dayPlansData = readingPlan.dayPlans.map((plan) => {
                    'day': plan.day,
                    'startPage': plan.startPage,
                    'endPage': plan.endPage,
                  }).toList();

                  await notificationService.scheduleAllNotifications(
                    hour: newTime.hour,
                    minute: newTime.minute,
                    dayPlans: dayPlansData,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notifications programmées à ${newTime.hour}h${newTime.minute.toString().padLeft(2, '0')}'
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmer la suppression'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce planning ?\n\n'
          'Cette action supprimera :\n'
          '• Le document PDF\n'
          '• Votre progression\n'
          '• Toutes les notifications programmées\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // Effectuer la suppression
      final storage = ref.read(storageServiceProvider);
      final notification = ref.read(notificationServiceProvider);

      await storage.clearAll();
      await notification.cancelAllNotifications();

      ref.read(pdfDocumentProvider.notifier).state = null;
      ref.read(completedDaysProvider.notifier).state = {};
      ref.read(isPlanningConfirmedProvider.notifier).state = false;

      if (context.mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(pdfDocumentProvider);
    final numberOfDays = ref.watch(numberOfDaysProvider);
    final readingPlan = ref.watch(readingPlanProvider);
    final completedDays = ref.watch(completedDaysProvider);
    final notificationTime = ref.watch(notificationTimeProvider);
    final isPlanningConfirmed = ref.watch(isPlanningConfirmedProvider);

    if (document == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Planning'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationSettings(context, ref),
            tooltip: 'Configurer les notifications',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _showDeleteConfirmation(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer le planning'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${document.totalPages} pages au total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(Icons.notifications_active, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${notificationTime.hour}h${notificationTime.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Slider nombre de jours
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Nombre de jours :', style: Theme.of(context).textTheme.titleMedium),
                    if (isPlanningConfirmed)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.lock, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: numberOfDays.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: numberOfDays.toString(),
                        onChanged: isPlanningConfirmed ? null : (value) async {
                          ref.read(numberOfDaysProvider.notifier).state = value.toInt();
                          ref.read(completedDaysProvider.notifier).state = {};

                          final storage = ref.read(storageServiceProvider);
                          await storage.saveNumberOfDays(value.toInt());
                          await storage.saveCompletedDays({});
                        },
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        numberOfDays.toString(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton Enregistrer le planning (visible seulement si non confirmé)
          if (!isPlanningConfirmed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    // Demander le nom du planning
                    final TextEditingController nameController = TextEditingController();
                    final planningName = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Nom du planning'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Donnez un nom à votre planning de lecture :',
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom du planning',
                                hintText: 'Ex: Coran Ramadan 2024',
                                border: OutlineInputBorder(),
                              ),
                              autofocus: true,
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  Navigator.of(context).pop(value.trim());
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isNotEmpty) {
                                Navigator.of(context).pop(name);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez entrer un nom'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                    );

                    if (planningName != null && context.mounted) {
                      final storage = ref.read(storageServiceProvider);
                      await storage.savePlanningConfirmed(true);
                      await storage.savePlanningName(planningName);
                      ref.read(isPlanningConfirmedProvider.notifier).state = true;
                      ref.read(planningNameProvider.notifier).state = planningName;

                      if (context.mounted) {
                        // Retourner au home avec notification
                        context.go('/');

                        // Afficher la notification après le changement de route
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Planning "$planningName" enregistré avec succès ! 🎉'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer le planning'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ),

          const Divider(),

          // Stats
          if (readingPlan != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(icon: Icons.calendar_today, label: 'Jours',
                    value: readingPlan.dayPlans.length.toString(),
                  ),
                  _StatCard(icon: Icons.menu_book, label: 'Pages/jour',
                    value: readingPlan.dayPlans.isNotEmpty
                      ? (document.totalPages / readingPlan.dayPlans.length).ceil().toString()
                      : '0',
                  ),
                  _StatCard(icon: Icons.check_circle, label: 'Complétés',
                    value: '${completedDays.length}/${readingPlan.dayPlans.length}',
                  ),
                ],
              ),
            ),

          const Divider(),

          // Liste des jours
          Expanded(
            child: readingPlan == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: readingPlan.dayPlans.length,
                itemBuilder: (context, index) {
                  final dayPlan = readingPlan.dayPlans[index];
                  final isCompleted = completedDays.contains(dayPlan.day);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: isPlanningConfirmed
                          ? () => context.go('/reader/${dayPlan.day}')
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez d\'abord enregistrer le planning pour accéder à la lecture'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Opacity(
                        opacity: isPlanningConfirmed ? 1.0 : 0.6,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            child: isCompleted
                                ? const Icon(Icons.check, color: Colors.white)
                                : Text('${dayPlan.day}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text('Jour ${dayPlan.day}'),
                          subtitle: Text(
                            'Pages ${dayPlan.startPage} - ${dayPlan.endPage} (${dayPlan.totalPages} pages)',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isCompleted,
                                onChanged: isPlanningConfirmed ? (value) async {
                                  final newCompleted = Set<int>.from(completedDays);
                                  value == true ? newCompleted.add(dayPlan.day) : newCompleted.remove(dayPlan.day);

                                  ref.read(completedDaysProvider.notifier).state = newCompleted;

                                  final storage = ref.read(storageServiceProvider);
                                  await storage.saveCompletedDays(newCompleted);
                                } : null,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isPlanningConfirmed ? null : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
