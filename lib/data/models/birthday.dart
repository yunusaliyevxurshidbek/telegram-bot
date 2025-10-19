import 'package:equatable/equatable.dart';

class Birthday extends Equatable {
  final int? id;
  final String name;
  final String date;

  const Birthday({this.id, required this.name, required this.date});

  factory Birthday.fromJson(Map<String, dynamic> json) => Birthday(
    id: json["id"],
    name: json["name"],
    date: json["date"],
  );

  Map<String, dynamic> toJson() => {"name": name, "date": date};

  @override
  List<Object?> get props => [id, name, date];
}