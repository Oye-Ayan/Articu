import '../../domain/therapist_model.dart';

class TherapistState {
  final List<TherapistModel> therapists;
  final TherapistModel? selectedTherapist;
  final bool isLoading;
  final bool isBooking;
  final bool isRegisteringTherapist;
  final String? bookingSuccessMessage;
  final String? errorMessage;

  const TherapistState({
    this.therapists = const [],
    this.selectedTherapist,
    this.isLoading = false,
    this.isBooking = false,
    this.isRegisteringTherapist = false,
    this.bookingSuccessMessage,
    this.errorMessage,
  });

  TherapistState copyWith({
    List<TherapistModel>? therapists,
    TherapistModel? selectedTherapist,
    bool? isLoading,
    bool? isBooking,
    bool? isRegisteringTherapist,
    String? bookingSuccessMessage,
    String? errorMessage,
  }) {
    return TherapistState(
      therapists: therapists ?? this.therapists,
      selectedTherapist: selectedTherapist ?? this.selectedTherapist,
      isLoading: isLoading ?? this.isLoading,
      isBooking: isBooking ?? this.isBooking,
      isRegisteringTherapist:
          isRegisteringTherapist ?? this.isRegisteringTherapist,
      bookingSuccessMessage: bookingSuccessMessage,
      errorMessage: errorMessage,
    );
  }
}
