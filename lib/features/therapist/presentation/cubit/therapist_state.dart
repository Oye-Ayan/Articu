import '../../domain/therapist_model.dart';

class TherapistState {
  final List<TherapistModel> therapists;
  final TherapistModel? selectedTherapist;
  final bool isBooking;
  final String? bookingSuccessMessage;

  const TherapistState({
    this.therapists = const [],
    this.selectedTherapist,
    this.isBooking = false,
    this.bookingSuccessMessage,
  });

  TherapistState copyWith({
    List<TherapistModel>? therapists,
    TherapistModel? selectedTherapist,
    bool? isBooking,
    String? bookingSuccessMessage,
  }) {
    return TherapistState(
      therapists: therapists ?? this.therapists,
      selectedTherapist: selectedTherapist ?? this.selectedTherapist,
      isBooking: isBooking ?? this.isBooking,
      bookingSuccessMessage: bookingSuccessMessage,
    );
  }
}
