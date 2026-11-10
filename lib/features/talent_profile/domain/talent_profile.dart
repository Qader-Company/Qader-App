enum TalentProfileStatus { accepted, rejected, restricted }

class TalentProfile {
  const TalentProfile({
    required this.name,
    required this.title,
    required this.email,
    this.phone = '',
    this.whatsapp = '',
    this.summary = '',
    this.status = TalentProfileStatus.accepted,
    this.reviewAvailableAt,
    this.avatarUrl,
  });
  final String name, title, email, phone, whatsapp, summary;
  final String? avatarUrl;
  final TalentProfileStatus status;
  final DateTime? reviewAvailableAt;
  TalentProfile copyWith({
    String? name,
    String? title,
    String? email,
    String? phone,
    String? whatsapp,
    String? summary,
    TalentProfileStatus? status,
    DateTime? reviewAvailableAt,
  }) => TalentProfile(
    name: name ?? this.name,
    title: title ?? this.title,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    summary: summary ?? this.summary,
    avatarUrl: avatarUrl,
    status: status ?? this.status,
    reviewAvailableAt: reviewAvailableAt ?? this.reviewAvailableAt,
  );
}
