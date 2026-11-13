class WasteModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String status;
  final String userEmail;
  final String? imageUrl;
  final DateTime createdAt;

  WasteModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.userEmail,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'status': status,
      'user_email': userEmail,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WasteModel.fromMap(Map<String, dynamic> map) {
    return WasteModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'Pending',
      userEmail: map['user_email'] ?? '',
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
