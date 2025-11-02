// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:ilmplanner/providers/providers.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class PdfReaderScreen extends ConsumerStatefulWidget {
//   final int day;

//   const PdfReaderScreen({super.key, required this.day});

//   @override
//   ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
// }

// class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
//   final PdfViewerController _pdfViewerController = PdfViewerController();
//   bool _isInitialized = false;

//   @override
//   void dispose() {
//     _pdfViewerController.dispose();
//     super.dispose();
//   }

//   void _initializePage() {
//     if (_isInitialized) return;
    
//     final readingPlan = ref.read(readingPlanProvider);
//     if (readingPlan != null) {
//       final dayPlan = readingPlan.dayPlans.firstWhere(
//         (plan) => plan.day == widget.day,
//       );
      
//       // Attendre que le viewer soit prêt
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _pdfViewerController.jumpToPage(dayPlan.startPage);
//           setState(() {
//             _isInitialized = true;
//           });
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final document = ref.watch(pdfDocumentProvider);
//     final readingPlan = ref.watch(readingPlanProvider);
//     final completedDays = ref.watch(completedDaysProvider);

//     if (document == null || readingPlan == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         context.go('/');
//       });
//       return const SizedBox.shrink();
//     }

//     final dayPlan = readingPlan.dayPlans.firstWhere(
//       (plan) => plan.day == widget.day,
//     );

//     final isCompleted = completedDays.contains(widget.day);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Jour ${widget.day} - Lecture'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go('/planning'),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               isCompleted ? Icons.check_circle : Icons.check_circle_outline,
//               color: isCompleted ? Colors.green : null,
//             ),
//             onPressed: () {
//               final newCompleted = Set<int>.from(completedDays);
//               if (isCompleted) {
//                 newCompleted.remove(widget.day);
//               } else {
//                 newCompleted.add(widget.day);
//               }
//               ref.read(completedDaysProvider.notifier).state = newCompleted;
//             },
//             tooltip: isCompleted ? 'Marquer comme non lu' : 'Marquer comme lu',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Info du jour
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             color: Theme.of(context).colorScheme.primaryContainer,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Pages ${dayPlan.startPage} à ${dayPlan.endPage}',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     Text(
//                       '${dayPlan.totalPages} pages à lire aujourd\'hui',
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                   ],
//                 ),
//                 Chip(
//                   label: Text('Jour ${widget.day}'),
//                   backgroundColor: Theme.of(context).colorScheme.primary,
//                   labelStyle: const TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//           ),

//           // Contrôles de navigation
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     _pdfViewerController.jumpToPage(dayPlan.startPage);
//                   },
//                   icon: const Icon(Icons.first_page, size: 18),
//                   label: const Text('Début'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   ),
//                 ),
//                 Text(
//                   'Page ${_pdfViewerController.pageNumber} / ${document.totalPages}',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     _pdfViewerController.jumpToPage(dayPlan.endPage);
//                   },
//                   icon: const Icon(Icons.last_page, size: 18),
//                   label: const Text('Fin'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const Divider(height: 1),

//           // Viewer PDF
//           Expanded(
//             child: SfPdfViewer.file(
//               File(document.path),
//               controller: _pdfViewerController,
//               initialPageNumber: dayPlan.startPage,
//               onDocumentLoaded: (details) {
//                 _initializePage();
//               },
//               pageLayoutMode: PdfPageLayoutMode.single,
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (_pdfViewerController.pageNumber < dayPlan.endPage)
//             FloatingActionButton(
//               heroTag: 'complete',
//               onPressed: () {
//                 final newCompleted = Set<int>.from(completedDays);
//                 newCompleted.add(widget.day);
//                 ref.read(completedDaysProvider.notifier).state = newCompleted;
                
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Jour ${widget.day} marqué comme lu !'),
//                     backgroundColor: Colors.green,
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               },
//               backgroundColor: Colors.green,
//               child: const Icon(Icons.check),
//             ),
//         ],
//       ),
//     );
//   }
// }

// Version alternative avec flutter_pdfview
// Plus stable et moins de problèmes de plugin

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:ilmplanner/providers/providers.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final int day;

  const PdfReaderScreen({super.key, required this.day});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(pdfDocumentProvider);
    final readingPlan = ref.watch(readingPlanProvider);
    final completedDays = ref.watch(completedDaysProvider);

    if (document == null || readingPlan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    final dayPlan = readingPlan.dayPlans.firstWhere(
      (plan) => plan.day == widget.day,
    );

    final isCompleted = completedDays.contains(widget.day);

    return Scaffold(
      appBar: AppBar(
        title: Text('Jour ${widget.day} - Lecture'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/planning'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: isCompleted ? Colors.green : null,
            ),
            onPressed: () {
              final newCompleted = Set<int>.from(completedDays);
              if (isCompleted) {
                newCompleted.remove(widget.day);
              } else {
                newCompleted.add(widget.day);
              }
              ref.read(completedDaysProvider.notifier).state = newCompleted;
            },
            tooltip: isCompleted ? 'Marquer comme non lu' : 'Marquer comme lu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info du jour
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pages ${dayPlan.startPage} à ${dayPlan.endPage}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${dayPlan.totalPages} pages à lire aujourd\'hui',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Chip(
                  label: Text('Jour ${widget.day}'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // Contrôles de navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _isReady && _pdfViewController != null
                      ? () {
                          _pdfViewController!.setPage(dayPlan.startPage - 1);
                        }
                      : null,
                  icon: const Icon(Icons.first_page, size: 18),
                  label: const Text('Début'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                Text(
                  _isReady
                      ? 'Page ${_currentPage + 1} / $_totalPages'
                      : 'Chargement...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _isReady && _pdfViewController != null
                      ? () {
                          _pdfViewController!.setPage(dayPlan.endPage - 1);
                        }
                      : null,
                  icon: const Icon(Icons.last_page, size: 18),
                  label: const Text('Fin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Indicateur de progression dans la lecture du jour
          if (_isReady && _currentPage >= dayPlan.startPage - 1 && _currentPage <= dayPlan.endPage - 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progression du jour',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${(((_currentPage - dayPlan.startPage + 2) / dayPlan.totalPages) * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (_currentPage - dayPlan.startPage + 2) / dayPlan.totalPages,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          if (_isReady && (_currentPage < dayPlan.startPage - 1 || _currentPage > dayPlan.endPage - 1))
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous êtes hors des pages du jour ${widget.day}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Viewer PDF
          Expanded(
            child: Stack(
              children: [
                PDFView(
                  filePath: document.path,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: dayPlan.startPage - 1,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false,
                  onRender: (pages) {
                    setState(() {
                      _totalPages = pages!;
                      _isReady = true;
                    });
                  },
                  onViewCreated: (PDFViewController controller) {
                    _pdfViewController = controller;
                  },
                  onPageChanged: (page, total) {
                    // Restreindre la navigation aux pages du jour uniquement
                    if (page! < dayPlan.startPage - 1) {
                      _pdfViewController?.setPage(dayPlan.startPage - 1);
                      return;
                    }
                    if (page > dayPlan.endPage - 1) {
                      _pdfViewController?.setPage(dayPlan.endPage - 1);
                      return;
                    }
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur de chargement: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
                if (!_isReady)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPage >= dayPlan.startPage - 1 && 
                            _currentPage >= dayPlan.endPage - 1 &&
                            !isCompleted
          ? FloatingActionButton.extended(
              onPressed: () {
                final newCompleted = Set<int>.from(completedDays);
                newCompleted.add(widget.day);
                ref.read(completedDaysProvider.notifier).state = newCompleted;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Jour ${widget.day} marqué comme lu ! 🎉'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check),
              label: const Text('Terminer'),
            )
          : null,
    );
  }
}