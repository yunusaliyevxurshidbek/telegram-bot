part of 'birthday_bloc.dart';

class BirthdayState extends Equatable {
  final List<Birthday> birthdays;
  final bool loading;
  final String? error;


  const BirthdayState({
    this.birthdays = const [],
    this.loading = false,
    this.error,
  });

  BirthdayState copyWith({
    List<Birthday>? birthdays,
    bool? loading,
    String? error,
  }) {
    return BirthdayState(
      birthdays: birthdays ?? this.birthdays,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [birthdays, loading, error];

}
