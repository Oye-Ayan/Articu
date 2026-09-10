import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void setTabIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void incrementPracticeMinutes(int minutes) {
    emit(state.copyWith(minutesPracticed: state.minutesPracticed + minutes));
  }
}
