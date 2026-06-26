class Notebook {
  final String id;
  final int slotIndex; // 0-8, fixed position among the 9 books
  final String name;
  final String subject;
  final String school;
  final String regNo;
  final int coverColorIndex;
  final int createdAt;
  final int lastOpenedAt;
  final int lastPageIndex;
  final bool isFavorite;
  final bool isLocked;
  final String? passwordHash;

  Notebook({
    required this.id,
    required this.slotIndex,
    this.name = '',
    this.subject = '',
    this.school = '',
    this.regNo = '',
    this.coverColorIndex = 0,
    required this.createdAt,
    required this.lastOpenedAt,
    this.lastPageIndex = 0,
    this.isFavorite = false,
    this.isLocked = false,
    this.passwordHash,
  });

  bool get isEmpty => name.isEmpty && subject.isEmpty && school.isEmpty && regNo.isEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'slot_index': slotIndex,
        'name': name,
        'subject': subject,
        'school': school,
        'reg_no': regNo,
        'cover_color_index': coverColorIndex,
        'created_at': createdAt,
        'last_opened_at': lastOpenedAt,
        'last_page_index': lastPageIndex,
        'is_favorite': isFavorite ? 1 : 0,
        'is_locked': isLocked ? 1 : 0,
        'password_hash': passwordHash,
      };

  factory Notebook.fromMap(Map<String, dynamic> map) => Notebook(
        id: map['id'] as String,
        slotIndex: map['slot_index'] as int,
        name: map['name'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        school: map['school'] as String? ?? '',
        regNo: map['reg_no'] as String? ?? '',
        coverColorIndex: map['cover_color_index'] as int? ?? 0,
        createdAt: map['created_at'] as int,
        lastOpenedAt: map['last_opened_at'] as int,
        lastPageIndex: map['last_page_index'] as int? ?? 0,
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        isLocked: (map['is_locked'] as int? ?? 0) == 1,
        passwordHash: map['password_hash'] as String?,
      );

  Notebook copyWith({
    String? name,
    String? subject,
    String? school,
    String? regNo,
    int? coverColorIndex,
    int? lastOpenedAt,
    int? lastPageIndex,
    bool? isFavorite,
    bool? isLocked,
    String? passwordHash,
  }) {
    return Notebook(
      id: id,
      slotIndex: slotIndex,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      school: school ?? this.school,
      regNo: regNo ?? this.regNo,
      coverColorIndex: coverColorIndex ?? this.coverColorIndex,
      createdAt: createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastPageIndex: lastPageIndex ?? this.lastPageIndex,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}
