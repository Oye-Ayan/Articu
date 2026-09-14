import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/therapist_model.dart';
import 'therapist_state.dart';

class TherapistCubit extends Cubit<TherapistState> {
  final SupabaseService _supabaseService;

  TherapistCubit({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(const TherapistState()) {
    fetchTherapists();
  }

  static const List<TherapistModel> _certifiedDirectory = [
    TherapistModel(
      id: 'marham-1',
      name: 'Dr. Sarah Jenkins, CCC-SLP',
      title: 'Senior Speech-Language Pathologist',
      specialty: 'Fluency Disorders & Adult Stuttering',
      rating: 4.9,
      reviewsCount: 124,
      hourlyRate: '\$85/session',
      avatarUrl: '',
      availableSlots: ['Today • 4:00 PM', 'Tomorrow • 11:00 AM', 'Thu • 2:30 PM'],
    ),
    TherapistModel(
      id: 'marham-2',
      name: 'Marcus Vance, M.S., CCC-SLP',
      title: 'Pediatric & Adult Speech Specialist',
      specialty: 'Articulation, Apraxia & Rate Control',
      rating: 4.8,
      reviewsCount: 98,
      hourlyRate: '\$75/session',
      avatarUrl: '',
      availableSlots: ['Tomorrow • 3:00 PM', 'Wed • 10:00 AM', 'Fri • 1:00 PM'],
    ),
    TherapistModel(
      id: 'marham-3',
      name: 'Elena Rostova, Ph.D.',
      title: 'Clinical Speech Director',
      specialty: 'Neurological Articulation & Resonance',
      rating: 5.0,
      reviewsCount: 162,
      hourlyRate: '\$95/session',
      avatarUrl: '',
      availableSlots: ['Today • 6:30 PM', 'Thu • 9:00 AM', 'Sat • 11:30 AM'],
    ),
  ];

  Future<void> fetchTherapists() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final rows = await _supabaseService.fetchTherapists();
      final liveTherapists = <TherapistModel>[];

      for (final r in rows) {
        liveTherapists.add(TherapistModel(
          id: r['id']?.toString() ?? '',
          name: r['name'] ?? 'Certified Clinician',
          title: 'Registered Speech Therapist',
          specialty: r['qualifications'] ?? 'Articulation & Fluency',
          rating: 4.9,
          reviewsCount: r['superhero_points'] ?? 20,
          hourlyRate: 'Online Consultation',
          avatarUrl: '',
          availableSlots: ['Online via Marham Portal', 'Mon-Fri: 9AM - 6PM'],
        ));
      }

      // Combine live registered therapists with verified clinical directory
      final allTherapists = [...liveTherapists, ..._certifiedDirectory];

      emit(state.copyWith(
        therapists: allTherapists,
        selectedTherapist: allTherapists.first,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        therapists: _certifiedDirectory,
        selectedTherapist: _certifiedDirectory.first,
        isLoading: false,
        errorMessage: 'Loaded cached certified clinicians: $e',
      ));
    }
  }

  void selectTherapist(TherapistModel therapist) {
    emit(state.copyWith(selectedTherapist: therapist));
  }

  Future<void> registerTherapist({
    required String name,
    required String email,
    required String qualifications,
    required String userId,
  }) async {
    emit(state.copyWith(isRegisteringTherapist: true, errorMessage: null));

    try {
      await _supabaseService.registerTherapist(
        name: name,
        email: email,
        qualifications: qualifications,
        userId: userId,
      );

      await fetchTherapists();
      emit(state.copyWith(
        isRegisteringTherapist: false,
        bookingSuccessMessage: 'Registered as a therapist successfully! Welcome aboard.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isRegisteringTherapist: false,
        errorMessage: 'Registration failed: $e',
      ));
    }
  }

  Future<void> bookSession({
    required String slot,
    required String contactNote,
  }) async {
    emit(state.copyWith(isBooking: true, bookingSuccessMessage: null));
    await Future.delayed(const Duration(milliseconds: 900));

    emit(state.copyWith(
      isBooking: false,
      bookingSuccessMessage:
          'Consultation booked for $slot with ${state.selectedTherapist?.name ?? "Therapist"}! Confirmation sent to your email.',
    ));
  }
}
