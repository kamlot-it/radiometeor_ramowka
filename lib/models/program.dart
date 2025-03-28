class Program {
  final String day;
  final String hour;
  final String title;
  final String? host;

  Program({
    required this.day,
    required this.hour,
    required this.title,
    this.host,
  });
}
