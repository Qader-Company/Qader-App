import '../../domain/entities/talent_profile.dart';

/// Sample profile for logged-out and preview routes.
/// Preview data only: never real account data.
final previewTalentProfile = TalentProfile(
  name: 'Muhamed Bayomee',
  title: 'Senior Full Stack Developer',
  email: 'muhamedbayomee@gmail.com',
  phone: '+20 102 234 5678',
  whatsapp: '+20 102 234 5678',
  summary:
      'Experienced Senior Full Stack Developer with 7 years of expertise in building scalable web applications. Proficient in React, Node.js, TypeScript, and cloud services. Passionate about clean code architecture and delivering high-quality user experiences.',
  status: TalentProfileStatus.accepted,
  completion: .8,
  available: true,
  location: 'October, Giza',
  yearsOfExperience: 2,
  links: const [
    ProfileLink(ProfileLinkKind.linkedin, 'https://example.com'),
    ProfileLink(ProfileLinkKind.behance, 'https://example.com'),
    ProfileLink(ProfileLinkKind.portfolio, 'https://example.com'),
    ProfileLink(ProfileLinkKind.github, 'https://example.com'),
  ],
  nationality: 'Egyptian',
  religion: 'islam',
  gender: 'male',
  city: 'Giza',
  country: 'Egypt',
  dateOfBirth: DateTime(2002, 7, 9),
  languages: const [
    ProfileLanguage('Arabic', 'native'),
    ProfileLanguage('English', 'advanced'),
  ],
  skills: const ['Figma', 'React', 'TypeScript', 'Node.js'],
  tools: const ['Figma', 'Jira', 'Notion', 'GitHub'],
  experiences: [
    ProfileExperience(
      title: 'Senior UI/UX Designer',
      company: 'Google Inc.',
      companyUrl: 'https://example.com',
      start: DateTime(2022, 3),
      current: true,
      description:
          'Leading the design system and user research for Google Workspace products. Collaborated with cross-functional teams to deliver pixel-perfect experiences.',
    ),
    ProfileExperience(
      title: 'UI Designer',
      company: 'Dribbble Studio',
      start: DateTime(2020),
      end: DateTime(2022, 2),
      description:
          'Designed mobile-first interfaces for SaaS clients. Reduced user drop-off by 34% through iterative usability testing.',
    ),
  ],
  projects: const [
    ProfileProject(
      name: 'Qader Talent Portal',
      description:
          'End-to-end design and front-end implementation of a talent matching platform connecting companies with top Arab tech talent.',
      url: 'https://example.com',
    ),
    ProfileProject(
      name: 'FinTrack Mobile App',
      description:
          'Designed a personal finance management app with a focus on simplicity, accessibility, and intuitive data visualization.',
      url: 'https://example.com',
    ),
  ],
  workTypes: const ['full_time'],
  workModes: const ['remote'],
  expectedSalary: '8,000–12,000 USD',
  currentSalary: '12,000 USD',
  noticePeriodDays: 30,
  willingToRelocate: true,
  cvFileName: 'Olivia_Rhye_CV_2026.pdf',
);
