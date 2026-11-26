import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/helpers/validators.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_dropdown.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_draft.dart';
import '../../domain/entities/workspace_lookup.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../cubit/create_workspace_cubit.dart';
import '../widgets/workspace_form_skeleton.dart';
import '../widgets/workspace_form_widgets.dart';
import '../widgets/workspace_social_links.dart';
import 'workspaces_view.dart';

/// "Create Your Workspace": one form, then the new workspace's dashboard.
class CreateWorkspaceView extends StatelessWidget {
  const CreateWorkspaceView({
    super.key,
    required this.repository,
    this.preview = false,
  });
  final WorkspacesRepository repository;
  final bool preview;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CreateWorkspaceCubit(repository)..loadLookups(),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _CreateWorkspaceForm(preview: preview)),
    ),
  );
}

class _CreateWorkspaceForm extends StatefulWidget {
  const _CreateWorkspaceForm({required this.preview});
  final bool preview;
  @override
  State<_CreateWorkspaceForm> createState() => _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends State<_CreateWorkspaceForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _crNumber = TextEditingController();
  final _website = TextEditingController();
  final _links = [SocialLinkInput()];
  WorkspaceFile? _logo;
  WorkspaceFile? _taxCard;
  WorkspaceLookup? _industry;
  WorkspaceLookup? _country;
  WorkspaceLookup? _city;
  String? _sizeBand;
  bool _isCompany = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _crNumber.dispose();
    _website.dispose();
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  void _submit(CreateWorkspaceCubit cubit) {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    cubit.submit(
      WorkspaceDraft(
        name: _name.text.trim(),
        industryIds: [_industry!.id],
        description: _description.text.trim(),
        isCompany: _isCompany,
        crNumber: _isCompany ? text(_crNumber) : null,
        taxCard: _isCompany ? _taxCard : null,
        countryId: _country!.id,
        cityId: _city?.id,
        sizeBand: _sizeBand!,
        websiteUrl: text(_website),
        logo: _logo,
        socialLinks: [
          for (final link in _links)
            if (link.url.text.trim().isNotEmpty)
              WorkspaceSocialLink(
                platform: link.platform,
                url: link.url.text.trim(),
              ),
        ],
      ),
    );
  }

  void _onState(BuildContext context, CreateWorkspaceState state) {
    if (state.created case final workspace?) {
      showAppToast(
        context,
        'workspace_created'.tr(context: context),
        type: ToastType.success,
      );
      final id = Uri.encodeQueryComponent(workspace.id);
      context.go(
        withPreview('${AppRouter.workspaceDashboard}?id=$id', widget.preview),
      );
    } else if (state.failure case final failure? when !state.loadingLookups) {
      showAppToast(
        context,
        failure.message.tr(context: context),
        type: ToastType.error,
      );
    }
  }

  String? _url(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri != null &&
            const ['http', 'https'].contains(uri.scheme) &&
            uri.host.contains('.')
        ? null
        : 'workspace_invalid_url'.tr(context: context);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CreateWorkspaceCubit, CreateWorkspaceState>(
    listenWhen: (a, b) =>
        a.created != b.created || (b.failure != null && a.failure != b.failure),
    listener: _onState,
    builder: (context, state) {
      if (state.loadingLookups) {
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: WorkspaceFormSkeleton(),
        );
      }
      final cubit = context.read<CreateWorkspaceCubit>();
      final enabled = !state.submitting;
      return Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(child: QaderLogo()),
            const SizedBox(height: 24),
            Text(
              'workspace_create_title'.tr(context: context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'workspace_create_hint'.tr(context: context),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: QaderDesign.muted,
              ),
            ),
            const SizedBox(height: 20),
            const WorkspaceFormSection('workspace_identity'),
            const SizedBox(height: 12),
            WorkspaceUploadField(
              labelKey: 'workspace_logo',
              enabled: enabled,
              onChanged: (file) => _logo = file,
            ),
            const SizedBox(height: 12),
            DefaultFormField(
              compact: true,
              enabled: enabled,
              controller: _name,
              requiredIndicator: true,
              label: 'workspace_name'.tr(context: context),
              hint: 'workspace_name_hint'.tr(context: context),
              inputFormatters: [LengthLimitingTextInputFormatter(255)],
              validator: Validators.required,
            ),
            const SizedBox(height: 20),
            const WorkspaceFormSection('workspace_business_identity'),
            const SizedBox(height: 12),
            _LookupDropdown(
              labelKey: 'workspace_industry',
              hintKey: 'workspace_industry_hint',
              required: true,
              items: state.industries,
              value: _industry,
              onChanged: enabled
                  ? (value) => setState(() => _industry = value)
                  : null,
            ),
            const SizedBox(height: 12),
            DefaultFormField(
              compact: true,
              enabled: enabled,
              controller: _description,
              requiredIndicator: true,
              label: 'workspace_description'.tr(context: context),
              hint: 'workspace_description_hint'.tr(context: context),
              maxLines: 4,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            const WorkspaceFormLabel('workspace_is_company', required: true),
            const SizedBox(height: 6),
            WorkspaceYesNo(
              value: _isCompany,
              onChanged: enabled
                  ? (value) => setState(() => _isCompany = value)
                  : null,
            ),
            if (_isCompany) ...[
              const SizedBox(height: 12),
              _CompanyFields(
                crNumber: _crNumber,
                enabled: enabled,
                onTaxCard: (file) => _taxCard = file,
              ),
            ],
            const SizedBox(height: 20),
            const WorkspaceFormSection('workspace_location'),
            const SizedBox(height: 12),
            _LookupDropdown(
              labelKey: 'workspace_country',
              hintKey: 'workspace_country_hint',
              required: true,
              items: state.countries,
              value: _country,
              onChanged: enabled
                  ? (value) {
                      if (value == null || value == _country) return;
                      setState(() {
                        _country = value;
                        _city = null;
                      });
                      cubit.selectCountry(value.id);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            _LookupDropdown(
              labelKey: 'workspace_city',
              hintKey: 'workspace_city_hint',
              items: state.cities,
              value: _city,
              onChanged: enabled
                  ? (value) => setState(() => _city = value)
                  : null,
            ),
            const SizedBox(height: 20),
            const WorkspaceFormSection('workspace_team_size'),
            const SizedBox(height: 8),
            Text(
              'workspace_size'.tr(context: context),
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
            const SizedBox(height: 8),
            WorkspaceSizeBands(
              enabled: enabled,
              onChanged: (band) => _sizeBand = band,
            ),
            const SizedBox(height: 20),
            const WorkspaceFormSection('workspace_online_presence'),
            const SizedBox(height: 12),
            DefaultFormField(
              compact: true,
              enabled: enabled,
              controller: _website,
              label: 'workspace_website'.tr(context: context),
              hint: 'workspace_website_hint'.tr(context: context),
              keyboardType: TextInputType.url,
              validator: _url,
            ),
            const SizedBox(height: 12),
            const WorkspaceFormLabel('workspace_social_links'),
            const SizedBox(height: 6),
            WorkspaceSocialLinks(
              links: _links,
              enabled: enabled,
              onAdd: () => setState(() => _links.add(SocialLinkInput())),
              onRemove: (link) => setState(() {
                _links.remove(link);
                link.dispose();
              }),
              onPlatform: (link, platform) =>
                  setState(() => link.platform = platform),
            ),
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: 'workspace_create'.tr(context: context),
              isLoading: state.submitting,
              onPressed: () => _submit(cubit),
            ),
          ],
        ),
      );
    },
  );
}

/// Tax card and CR number, asked only from companies.
class _CompanyFields extends StatelessWidget {
  const _CompanyFields({
    required this.crNumber,
    required this.enabled,
    required this.onTaxCard,
  });
  final TextEditingController crNumber;
  final bool enabled;
  final ValueChanged<WorkspaceFile?> onTaxCard;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.neutral50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceUploadField(
          labelKey: 'workspace_tax_card',
          required: true,
          enabled: enabled,
          onChanged: onTaxCard,
        ),
        const SizedBox(height: 12),
        DefaultFormField(
          compact: true,
          enabled: enabled,
          controller: crNumber,
          requiredIndicator: true,
          label: 'workspace_cr_number'.tr(context: context),
          hint: 'workspace_cr_number_hint'.tr(context: context),
          inputFormatters: [LengthLimitingTextInputFormatter(64)],
          validator: Validators.required,
        ),
      ],
    ),
  );
}

class _LookupDropdown extends StatelessWidget {
  const _LookupDropdown({
    required this.labelKey,
    required this.hintKey,
    required this.items,
    required this.value,
    required this.onChanged,
    this.required = false,
  });
  final String labelKey;
  final String hintKey;
  final List<WorkspaceLookup> items;
  final WorkspaceLookup? value;
  final ValueChanged<WorkspaceLookup?>? onChanged;
  final bool required;
  @override
  Widget build(BuildContext context) => DefaultDropdown<WorkspaceLookup>(
    // A new list (cities of another country) starts empty.
    key: ValueKey((items, value)),
    initialValue: items.contains(value) ? value : null,
    items: items,
    compact: true,
    requiredIndicator: required,
    label: labelKey.tr(context: context),
    hint: hintKey.tr(context: context),
    itemLabel: (item) => item.name,
    onChanged: onChanged,
    validator: required
        ? (item) => item == null ? 'field_required'.tr(context: context) : null
        : null,
  );
}
