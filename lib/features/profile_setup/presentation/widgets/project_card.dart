import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_upload.dart';

/// One project entry (with images) in the skills & experience step.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.draft,
    required this.entry,
    required this.index,
  });
  final ProfileSetupCubit draft;
  final ProjectEntry entry;
  final int index;
  String get prefix => 'project_${entry.id}_';
  @override
  Widget build(BuildContext context) => ProfileEntryCard(
    title: '${pc(context, 'Project')} ${index + 1}',
    onRemove: () {
      draft.projects.remove(entry);
      draft.refresh();
    },
    children: [
      ProfileInput(
        'Project Name',
        controller: draft.text('${prefix}name'),
        hint: 'e.g shelfspot',
        validator: (v) {
          final active =
              draft.isConnected ||
              draft.text('${prefix}description').text.trim().isNotEmpty ||
              draft.text('${prefix}url').text.trim().isNotEmpty ||
              entry.images.isNotEmpty;
          return active ? requiredProfile(context, v) : null;
        },
      ),
      ProfileInput(
        'Project Description',
        controller: draft.text('${prefix}description'),
        hint: 'Describe your project...',
        lines: 5,
      ),
      ProfileInput(
        'Project Link',
        controller: draft.text('${prefix}url'),
        hint: 'https://...',
        type: TextInputType.url,
        validator: (v) => profileUrl(context, v),
      ),
      ProfileColumn(
        gap: 4,
        children: [
          const ProfileLabel('Project Images'),
          Text(
            pc(
              context,
              'Upload screenshots or images of your work (max 5 images)',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
      ProfileUpload(
        images: true,
        files: entry.images,
        onChanged: (files) {
          entry.images
            ..clear()
            ..addAll(files);
          draft.refresh();
        },
      ),
      for (final image in entry.savedImages)
        Text(
          image['file_name']?.toString() ??
              image['name']?.toString() ??
              'Image ${image['id']}',
        ),
    ],
  );
}
