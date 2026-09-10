import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/therapist_model.dart';
import 'therapist_state.dart';

class TherapistCubit extends Cubit<TherapistState> {
  TherapistCubit() : super(const TherapistState()) {
    _loadTherapists();
  }

  void _loadTherapists() {
    final mockTherapists = [
      const TherapistModel(
        id: 't-1',
        name: 'Dr. Sarah Jenkins, CCC-SLP',
        title: 'Speech-Language Pathologist',
        specialty: 'Fluency Disorders & Adult Stuttering',
        rating: 4.9,
        reviewsCount: 124,
        hourlyRate: '\$85/session',
        avatarUrl: '',
        availableSlots: ['Today • 4:00 PM', 'Tomorrow • 11:00 AM', 'Thu • 2:30 PM'],
      ),
      const TherapistModel(
        id: 't-2',
        name: 'Marcus Vance, M.S., CCC-SLP',
        title: 'Pediatric & Adult Speech Specialist',
        specialty: 'Articulation, Apraxia & Rate Control',
        rating: 4.8,
        reviewsCount: 98,
        hourlyRate: '\$75/session',
        avatarUrl: '',
        availableSlots: ['Tomorrow • 3:00 PM', 'Wed • 10:00 AM', 'Fri • 1:00 PM'],
      ),
      const TherapistModel(
        id: 't-3',
        name: 'Elena Rostova, Ph.D.',
        title: 'Clinical Speech Director',
        specialty: 'Neurological Articulation & Vocal Resonance',
        rating: 5.0,
        reviewsCount: 162,
        hourlyRate: '\$95/session',
        avatarUrl: '',
        availableSlots: ['Today • 6:30 PM', 'Thu • 9:00 AM', 'Sat • 11:30 AM'],
      ),
    ];

    emit(state.copyWith(
      therapists: mockTherapists,
      selectedTherapist: mockTherapists.first,
    ));
  }

  void selectTherapist(TherapistModel therapist) {
    emit(state.copyWith(selectedTherapist: therapist));
  }

  Future<void> bookSession({
    required String slot,
    required String contactNote,
  }) async {
    emit(state.copyWith(isBooking: true, bookingSuccessMessage: null));
    await Future.delayed(const Duration(milliseconds: 1200));

    emit(state.copyWith(
      isBooking: false,
      bookingSuccessMessage:
          'Consultation booked for $slot with ${state.selectedTherapist?.name ?? "Therapist"}! Confirmation sent to your email.',
    ));
  }
}
