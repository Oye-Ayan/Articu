class TherapistModel {
  final String id;
  final String name;
  final String title;
  final String specialty;
  final double rating;
  final int reviewsCount;
  final String hourlyRate;
  final String avatarUrl;
  final List<String> availableSlots;

  const TherapistModel({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.rating,
    required this.reviewsCount,
    required this.hourlyRate,
    required this.avatarUrl,
    required this.availableSlots,
  });
}
