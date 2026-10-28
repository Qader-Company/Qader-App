class ProfessionalField {
  const ProfessionalField(
    this.name,
    this.description,
    this.jobs, {
    this.id,
    this.slug,
  });
  final int? id;
  final String? slug;
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
