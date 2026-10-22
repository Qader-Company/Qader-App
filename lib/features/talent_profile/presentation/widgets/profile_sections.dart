import 'package:flutter/material.dart';
import '../../domain/talent_profile.dart';
import '../profile_copy.dart';
import 'profile_components.dart';

class ProfileBasicInfo extends StatelessWidget {
  const ProfileBasicInfo({super.key, required this.profile});
  final TalentProfile profile;
  @override
  Widget build(BuildContext context) => ProfileStack(
    gap: 24,
    children: [
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('Contact & Personal'),
          ProfileDetail('Phone Number', profile.phone),
          ProfileDetail('WhatsApp', profile.whatsapp),
          ProfileDetail('Email', profile.email),
          const ProfileDetail('Nationality', 'Egyptian', translated: true),
          const ProfileDetail('Religion', 'Islam', translated: true),
          const ProfileDetail('City', 'Giza', translated: true),
          const ProfileDetail('Country', 'Egypt', translated: true),
          const ProfileDetail('Gender', 'Male', translated: true),
          const ProfileDetail('Date of Birthday', '9/7/2002'),
        ],
      ),
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('Languages'),
          for (final language in ['Arabic', 'English'])
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tc(context, language),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: language == 'Arabic'
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tc(context, language == 'Arabic' ? 'Native' : 'Advanced'),
                      style: TextStyle(
                        fontSize: 12,
                        color: language == 'Arabic'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF9333EA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

class ProfileSkillsExperience extends StatelessWidget {
  const ProfileSkillsExperience({super.key});
  @override
  Widget build(BuildContext context) => ProfileStack(
    gap: 24,
    children: [
      const ProfileStack(
        gap: 12,
        children: [
          ProfileHeading('Skills'),
          ProfileTags(['Figma', 'React', 'TypeScript', 'Node.js']),
        ],
      ),
      const ProfileStack(
        gap: 12,
        children: [
          ProfileHeading('Tools'),
          ProfileTags(['Figma', 'Jira', 'Notion', 'GitHub']),
        ],
      ),
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('Work Experience'),
          _experience(
            context,
            'Senior UI/UX Designer',
            'Google Inc.',
            'Mar 2022 - Present',
            'Leading the design system and user research for Google Workspace products. Collaborated with cross-functional teams to deliver pixel-perfect experiences.',
            true,
          ),
          _experience(
            context,
            'UI Designer',
            'Dribbble Studio',
            'Jan 2020 - Feb 2022',
            'Designed mobile-first interfaces for SaaS clients. Reduced user drop-off by 34% through iterative usability testing.',
            false,
          ),
        ],
      ),
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('Projects'),
          _project(
            context,
            'Qader Talent Portal',
            'End-to-end design and front-end implementation of a talent matching platform connecting companies with top Arab tech talent.',
          ),
          _project(
            context,
            'FinTrack Mobile App',
            'Designed a personal finance management app with a focus on simplicity, accessibility, and intuitive data visualization.',
          ),
        ],
      ),
    ],
  );
  Widget _experience(
    BuildContext context,
    String title,
    String company,
    String dates,
    String description,
    bool current,
  ) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current ? profileBlue : const Color(0xFFD4D4D4),
              ),
            ),
            Expanded(
              child: Container(width: 1, color: const Color(0xFFE5E5E5)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ProfileStack(
            gap: 4,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                company,
                style: const TextStyle(fontSize: 12, color: Color(0xFF525252)),
              ),
              Text(
                dates,
                style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF737373),
                ),
              ),
              if (current)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text(
                      tc(context, 'Company profile'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => profileNotice(
                      context,
                      'Company profile',
                      'Company details are not connected yet',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _project(BuildContext context, String title, String description) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ProfileStack(
          gap: 8,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF737373),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(title, style: const TextStyle(fontSize: 12)),
                onPressed: () => profileNotice(
                  context,
                  'Project link',
                  'This sample project has no live URL',
                ),
              ),
            ),
          ],
        ),
      );
}

class ProfileWorkPreferences extends StatelessWidget {
  const ProfileWorkPreferences({super.key});
  @override
  Widget build(BuildContext context) => ProfileStack(
    gap: 24,
    children: [
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('Availability'),
          ProfileTags([tc(context, 'Full Time'), tc(context, 'Remote')]),
          const ProfileDetail('Expected Salary', '8,000–12,000 USD'),
          const ProfileDetail('Current Salary', '12,000 USD'),
          const ProfileDetail('Notice Period', '1 Month', translated: true),
          const ProfileDetail('Willing to Relocate', 'Yes', translated: true),
        ],
      ),
      ProfileStack(
        gap: 12,
        children: [
          const ProfileHeading('CV / Resume'),
          Material(
            color: const Color(0xFFF4F8FE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFB8D0FF)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => profileNotice(
                context,
                'CV / Resume',
                'This preview does not include an uploaded CV file',
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 24,
                      color: profileBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ProfileStack(
                        gap: 4,
                        children: [
                          const Text(
                            'Olivia_Rhye_CV_2026.pdf',
                            style: TextStyle(fontSize: 14, color: profileBlue),
                          ),
                          Text(
                            tc(context, 'Uploaded CV'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
