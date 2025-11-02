import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;
import 'package:ilmplanner/models/models.dart';
import 'package:ilmplanner/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickPdfFile(WidgetRef ref, BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;

        // Charger le PDF pour obtenir le nombre de pages
        final file = File(path);
        final bytes = await file.readAsBytes();
        
        // Utiliser PdfDocumentLoader de syncfusion
        final pdfDoc = syncfusion_pdf.PdfDocument(inputBytes: bytes);
        final totalPages = pdfDoc.pages.count;
        pdfDoc.dispose();

        ref.read(pdfDocumentProvider.notifier).state = PdfDocument(
          path: path,
          name: name,
          totalPages: totalPages,
        );

        if (context.mounted) {
          context.go('/planning');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du PDF: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndCreateNewPlanning(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau planning'),
        content: const Text(
          'Êtes-vous sûr de vouloir créer un nouveau planning ?\n\nCela remplacera votre planning actuel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _pickPdfFile(ref, context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfDocument = ref.watch(pdfDocumentProvider);
    final numberOfDays = ref.watch(numberOfDaysProvider);
    final completedDays = ref.watch(completedDaysProvider);
    final planningName = ref.watch(planningNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilm Planner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: pdfDocument != null
              ? _buildExistingPlanningView(
                  context,
                  ref,
                  pdfDocument,
                  numberOfDays,
                  completedDays,
                  planningName,
                )
              : _buildNewPlanningView(context, ref),
        ),
      ),
    );
  }

  Widget _buildNewPlanningView(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: 120,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Créez votre planning de lecture',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Chargez un PDF et définissez le nombre de jours pour créer un planning personnalisé',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () => _pickPdfFile(ref, context),
          icon: const Icon(Icons.upload_file),
          label: const Text('Charger un PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingPlanningView(
    BuildContext context,
    WidgetRef ref,
    PdfDocument document,
    int numberOfDays,
    Set<int> completedDays,
    String? planningName,
  ) {
    final progress = completedDays.length / numberOfDays;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Planning en cours',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Card avec les informations du planning
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              planningName ?? document.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      if (planningName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 36),
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.grey[600],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                document.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 24),

                  _buildInfoRow(
                    context,
                    Icons.description,
                    'Pages totales',
                    '${document.totalPages}',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    'Nombre de jours',
                    '$numberOfDays',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context,
                    Icons.check_circle,
                    'Progression',
                    '${completedDays.length} / $numberOfDays jours',
                  ),
                  const SizedBox(height: 16),

                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 20,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}% complété',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bouton principal: Voir mon planning
          ElevatedButton.icon(
            onPressed: () => context.go('/planning'),
            icon: const Icon(Icons.visibility),
            label: const Text('Voir mon planning'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton secondaire: Créer un nouveau planning
          OutlinedButton.icon(
            onPressed: () => _confirmAndCreateNewPlanning(ref, context),
            icon: const Icon(Icons.add),
            label: const Text('Créer un nouveau planning'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
