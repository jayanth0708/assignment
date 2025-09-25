class Patient {
  final String id;
  final String name;

  Patient({required this.id, required this.name});

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
    );
  }
}