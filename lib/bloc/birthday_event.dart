part of 'birthday_bloc.dart';

abstract class BirthdayEvent extends Equatable {

  const BirthdayEvent();

  @override
  List<Object?> get props => [];
}

class LoadBirthdays extends BirthdayEvent {}

class AddBirthday extends BirthdayEvent {
  final String name;
  final String date;
  const AddBirthday(this.name, this.date);
}

class DeleteBirthday extends BirthdayEvent {
  final int id;
  const DeleteBirthday(this.id);
}
