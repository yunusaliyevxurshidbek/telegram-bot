import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/birthday.dart';
import '../data/services/birthday_api_service.dart';
part 'birthday_event.dart';
part 'birthday_state.dart';

class BirthdayBloc extends Bloc<BirthdayEvent, BirthdayState> {
  final BirthdayApiService api;

  BirthdayBloc(this.api) : super(const BirthdayState()) {
    on<LoadBirthdays>(_onLoad);
    on<AddBirthday>(_onAdd);
    on<DeleteBirthday>(_onDelete);
  }

  Future<void> _onLoad(LoadBirthdays event, Emitter<BirthdayState> emit) async {
    emit(state.copyWith(loading: true));

    try {
      final birthdays = await api.getBirthdays();
      emit(state.copyWith(birthdays: birthdays, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onAdd(AddBirthday event, Emitter<BirthdayState> emit) async {
    try {
      await api.addBirthday(event.name, event.date);
      add(LoadBirthdays());
    } catch(e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteBirthday event, Emitter<BirthdayState> emit) async {
    try {
      await api.deleteBirthday(event.id);
      add(LoadBirthdays());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
