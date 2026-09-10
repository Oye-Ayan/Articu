class HomeState {
  final int selectedIndex;
  final int dailyStreak;
  final int minutesPracticed;
  final String dailyQuote;
  final String dailyAuthor;

  const HomeState({
    this.selectedIndex = 0,
    this.dailyStreak = 5,
    this.minutesPracticed = 12,
    this.dailyQuote = 'Every person you meet knows something valuable you do not.',
    this.dailyAuthor = 'ArticuliCare Daily Inspiration',
  });

  HomeState copyWith({
    int? selectedIndex,
    int? dailyStreak,
    int? minutesPracticed,
    String? dailyQuote,
    String? dailyAuthor,
  }) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      minutesPracticed: minutesPracticed ?? this.minutesPracticed,
      dailyQuote: dailyQuote ?? this.dailyQuote,
      dailyAuthor: dailyAuthor ?? this.dailyAuthor,
    );
  }
}
