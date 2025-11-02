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
          TextButton.icon(
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
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(pdfDocumentProvider);
    final numberOfDays = ref.watch(numberOfDaysProvider);
    final readingPlan = ref.watch(readingPlanProvider);
    final completedDays = ref.watch(completedDaysProvider);
    final notificationTime = ref.watch(notificationTimeProvider);

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
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer le planning'),
                  ],
                ),
                onTap: () async {
                  final storage = ref.read(storageServiceProvider);
                  final notification = ref.read(notificationServiceProvider);

                  await storage.clearAll();
                  await notification.cancelAllNotifications();

                  ref.read(pdfDocumentProvider.notifier).state = null;
                  ref.read(completedDaysProvider.notifier).state = {};

                  if (context.mounted) {
                    context.go('/');
                  }
                },
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
                Text('Nombre de jours :', style: Theme.of(context).textTheme.titleMedium),
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
                        onChanged: (value) async {
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
                      onTap: () => context.go('/reader/${dayPlan.day}'),
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
                              onChanged: (value) async {
                                final newCompleted = Set<int>.from(completedDays);
                                value == true ? newCompleted.add(dayPlan.day) : newCompleted.remove(dayPlan.day);

                                ref.read(completedDaysProvider.notifier).state = newCompleted;

                                final storage = ref.read(storageServiceProvider);
                                await storage.saveCompletedDays(newCompleted);
                              },
                            ),
                            const Icon(Icons.chevron_right),
                          ],
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
