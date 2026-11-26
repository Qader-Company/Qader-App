/// Team size bands accepted by `POST /client/workspaces` (`size_band`).
const workspaceSizeBands = ['1-10', '11-50', '51-200', '201-500', '500+'];

/// Social platforms accepted by `POST /client/workspaces`
/// (`social_links[].platform`).
const workspaceSocialPlatforms = [
  'linkedin',
  'facebook',
  'instagram',
  'x',
  'youtube',
  'tiktok',
  'snapchat',
  'threads',
  'pinterest',
  'reddit',
  'telegram',
  'whatsapp',
  'discord',
  'github',
  'gitlab',
  'behance',
  'dribbble',
  'medium',
  'stack_overflow',
  'twitch',
  'other',
];

class WorkspaceSocialLink {
  const WorkspaceSocialLink({required this.platform, required this.url});
  final String platform;
  final String url;
}

/// A local file picked for the workspace (logo or tax card).
class WorkspaceFile {
  const WorkspaceFile({required this.name, required this.path});
  final String name;
  final String path;
}

/// What the "Create Your Workspace" form sends.
class WorkspaceDraft {
  const WorkspaceDraft({
    required this.name,
    required this.industryIds,
    required this.description,
    required this.isCompany,
    required this.countryId,
    required this.sizeBand,
    this.professionalFieldIds = const [],
    this.crNumber,
    this.taxCard,
    this.cityId,
    this.websiteUrl,
    this.logo,
    this.socialLinks = const [],
  });
  final String name;
  final List<int> industryIds;
  final List<int> professionalFieldIds;
  final String description;
  final bool isCompany;
  final String? crNumber;
  final WorkspaceFile? taxCard;
  final int countryId;
  final int? cityId;
  final String sizeBand;
  final String? websiteUrl;
  final WorkspaceFile? logo;
  final List<WorkspaceSocialLink> socialLinks;
}
