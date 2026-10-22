import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ProfileSetupSeed {
  const ProfileSetupSeed({required this.name, required this.email});
  final String name;
  final String email;
}

class ProfessionalField {
  const ProfessionalField(this.name, this.description, this.jobs);
  final String name;
  final String description;
  final List<String> jobs;
  static const values = [
    ProfessionalField(
      'Software Development',
      'Roles related to coding, engineering, and software architecture.',
      [
        'Software Engineer',
        'Frontend Developer',
        'Backend Developer',
        'Mobile Developer',
        'QA Engineer',
      ],
    ),
    ProfessionalField('Design', 'Graphic, UI/UX, and product design roles.', [
      'UI/UX Designer',
      'Graphic Designer',
      'Product Designer',
    ]),
    ProfessionalField(
      'Sales',
      'Business development, account management, and sales operations.',
      [
        'Sales Representative',
        'Account Manager',
        'Business Development Manager',
      ],
    ),
    ProfessionalField(
      'Marketing',
      'Digital marketing, brand management, and growth strategies.',
      ['Digital Marketer', 'Content Specialist', 'Brand Manager'],
    ),
    ProfessionalField(
      'Customer Service',
      'Support, success, and customer experience roles.',
      ['Customer Support Specialist', 'Customer Success Manager'],
    ),
    ProfessionalField(
      'Human Resources',
      'Talent acquisition, people operations, and HR management.',
      ['HR Specialist', 'Recruiter', 'HR Manager'],
    ),
    ProfessionalField(
      'Finance & Accounting',
      'Financial planning, accounting, and treasury roles.',
      ['Accountant', 'Financial Analyst', 'Treasury Specialist'],
    ),
    ProfessionalField(
      'Operations',
      'Supply chain, logistics, and business operations management.',
      [
        'Operations Specialist',
        'Logistics Coordinator',
        'Supply Chain Manager',
      ],
    ),
  ];
}

class LanguageEntry {
  LanguageEntry(this.id, {this.language, this.level});
  final int id;
  String? language;
  String? level;
}

class ExperienceEntry {
  ExperienceEntry(this.id);
  final int id;
  bool current = false;
  DateTime? from;
  DateTime? to;
}

class ProjectEntry {
  ProjectEntry(this.id);
  final int id;
  final images = <PlatformFile>[];
}

/// Draft data lives only in memory until a real profile API is available.
class ProfileSetupController extends ChangeNotifier {
  ProfileSetupController({ProfileSetupSeed? seed}) {
    text('name').text = seed?.name ?? 'Olivia Rhye';
    text('email').text = seed?.email ?? 'olivia@untitledui.com';
  }
  int step = 0;
  int _nextId = 3;
  ProfessionalField field = ProfessionalField.values.first;
  final _text = <String, TextEditingController>{};
  final selections = <String, String?>{};
  final skills = ['React', 'TypeScript'];
  final languages = [
    LanguageEntry(1, language: 'English', level: 'B1'),
    LanguageEntry(2),
  ];
  final experiences = [ExperienceEntry(1)];
  final projects = [ProjectEntry(1)];
  PlatformFile? cv;
  DateTime? birthday;
  TextEditingController text(String key) =>
      _text.putIfAbsent(key, TextEditingController.new);
  String? value(String key) => selections[key];
  void select(String key, String? value) {
    selections[key] = value;
    notifyListeners();
  }

  void refresh() => notifyListeners();
  void go(int value) {
    step = value;
    notifyListeners();
  }

  void chooseField(ProfessionalField value) {
    if (field != value) selections.remove('job');
    field = value;
    notifyListeners();
  }

  void addLanguage() {
    languages.add(LanguageEntry(_nextId++));
    notifyListeners();
  }

  void addExperience() {
    experiences.add(ExperienceEntry(_nextId++));
    notifyListeners();
  }

  void addProject() {
    projects.add(ProjectEntry(_nextId++));
    notifyListeners();
  }

  @override
  void dispose() {
    for (final value in _text.values) {
      value.dispose();
    }
    super.dispose();
  }
}
