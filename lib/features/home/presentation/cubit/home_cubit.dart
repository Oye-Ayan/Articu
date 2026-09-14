import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    fetchDailyQuote();
  }

  void setTabIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void incrementPracticeMinutes(int minutes) {
    emit(state.copyWith(minutesPracticed: state.minutesPracticed + minutes));
  }

  /// Resets home tab and session stats on logout
  void reset() {
    emit(state.copyWith(
      selectedIndex: 0,
      minutesPracticed: 0,
    ));
  }

  Future<void> fetchDailyQuote() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request =
          await client.getUrl(Uri.parse('https://zenquotes.io/api/today'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List<dynamic> jsonList = jsonDecode(body);
        if (jsonList.isNotEmpty && jsonList.first is Map) {
          final data = jsonList.first as Map<String, dynamic>;
          final quoteText = data['q']?.toString().trim();
          final authorText = data['a']?.toString().trim();

          if (quoteText != null && quoteText.isNotEmpty) {
            emit(state.copyWith(
              dailyQuote: quoteText,
              dailyAuthor: (authorText != null && authorText.isNotEmpty)
                  ? authorText
                  : 'ArticuliCare Daily Inspiration',
            ));
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint('Error fetching daily quote from ZenQuotes: $e');
      // Gracefully retains existing default quote
    }
  }
}
