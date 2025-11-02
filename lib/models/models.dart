class PdfDocument {
  final String path;
  final String name;
  final int totalPages;

  PdfDocument({
    required this.path,
    required this.name,
    required this.totalPages,
  });
}

class ReadingPlan {
  final PdfDocument document;
  final int numberOfDays;
  final List<DayPlan> dayPlans;

  ReadingPlan({
    required this.document,
    required this.numberOfDays,
    required this.dayPlans,
  });
}

class DayPlan {
  final int day;
  final int startPage;
  final int endPage;
  final bool isCompleted;

  DayPlan({
    required this.day,
    required this.startPage,
    required this.endPage,
    this.isCompleted = false,
  });

  DayPlan copyWith({bool? isCompleted}) {
    return DayPlan(
      day: day,
      startPage: startPage,
      endPage: endPage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  int get totalPages => endPage - startPage + 1;
}