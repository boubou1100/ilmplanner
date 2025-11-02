import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ilmplanner/screens/home.dart';
import 'package:ilmplanner/screens/pdfreader.dart';
import 'package:ilmplanner/screens/planning.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/planning',
        builder: (context, state) => const PlanningScreen(),
      ),
      GoRoute(
        path: '/reader/:day',
        builder: (context, state) {
          final day = int.parse(state.pathParameters['day']!);
          return PdfReaderScreen(day: day);
        },
      ),
    ],
  );
});
