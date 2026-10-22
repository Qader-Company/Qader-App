enum TalentProfileStatus { accepted, rejected, restricted }

class TalentProfile {
  const TalentProfile({
    this.name = 'Muhamed Bayomee',
    this.status = TalentProfileStatus.accepted,
    this.reviewAvailableAt,
    this.title = 'Senior Full Stack Developer',
    this.email = 'muhamedbayomee@gmail.com',
    this.phone = '+20 102 234 5678',
    this.whatsapp = '+20 102 234 5678',
    this.avatarUrl,
    this.summary =
        'Experienced Senior Full Stack Developer with 7 years of expertise in building scalable web applications. Proficient in React, Node.js, TypeScript, and cloud services. Passionate about clean code architecture and delivering high-quality user experiences.',
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
  }) => TalentProfile(
    name: name ?? this.name,
    title: title ?? this.title,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    summary: summary ?? this.summary,
    avatarUrl: avatarUrl,
    status: status,
    reviewAvailableAt: reviewAvailableAt,
  );
}
