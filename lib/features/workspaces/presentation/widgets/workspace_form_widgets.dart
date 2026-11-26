import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_draft.dart';

/// Bold heading of a group of fields ("Workspace Identity", "Location").
class WorkspaceFormSection extends StatelessWidget {
  const WorkspaceFormSection(this.titleKey, {super.key});
  final String titleKey;
  @override
  Widget build(BuildContext context) => Text(
    titleKey.tr(context: context),
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

/// Field label with the red asterisk of required fields.
class WorkspaceFormLabel extends StatelessWidget {
  const WorkspaceFormLabel(this.labelKey, {super.key, this.required = false});
  final String labelKey;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: labelKey.tr(context: context),
      children: [
        if (required)
          const TextSpan(
            text: '*',
            style: TextStyle(color: AppColors.red600),
          ),
      ],
    ),
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      color: AppColors.neutral700,
    ),
  );
}

/// Image upload box (logo, tax card): PNG/JPG/JPEG/WEBP up to 5 MB.
class WorkspaceUploadField extends FormField<WorkspaceFile> {
  WorkspaceUploadField({
    super.key,
    required String labelKey,
    required ValueChanged<WorkspaceFile?> onChanged,
    bool required = false,
    super.enabled,
  }) : super(
         validator: required
             ? (file) => file == null ? 'field_required'.tr() : null
             : null,
         builder: (field) => _UploadBox(
           labelKey: labelKey,
           required: required,
           field: field,
           onChanged: (file) {
             field.didChange(file);
             onChanged(file);
           },
         ),
       );
}

class _UploadBox extends StatefulWidget {
  const _UploadBox({
    required this.labelKey,
    required this.required,
    required this.field,
    required this.onChanged,
  });
  final String labelKey;
  final bool required;
  final FormFieldState<WorkspaceFile> field;
  final ValueChanged<WorkspaceFile?> onChanged;
  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  static const _extensions = ['png', 'jpg', 'jpeg', 'webp'];
  static const _maxBytes = 5 * 1024 * 1024;
  bool _picking = false;

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensions,
      );
      if (!mounted || result == null) return;
      final file = result.files.single;
      final path = file.path;
      if (path == null ||
          file.size > _maxBytes ||
          !_extensions.contains(file.extension?.toLowerCase())) {
        showAppToast(
          context,
          'workspace_upload_invalid'.tr(context: context),
          type: ToastType.error,
        );
        return;
      }
      widget.onChanged(WorkspaceFile(name: file.name, path: path));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.field.value;
    final error = widget.field.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceFormLabel(widget.labelKey, required: widget.required),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: error == null ? QaderDesign.border : AppColors.red600,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.field.widget.enabled ? _pick : null,
            child: SizedBox(
              height: 100,
              child: file == null
                  ? const _UploadHint()
                  : _PickedFile(
                      name: file.name,
                      onRemove: widget.field.widget.enabled
                          ? () => widget.onChanged(null)
                          : null,
                    ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(fontSize: 12, color: AppColors.red600),
          ),
        ],
      ],
    );
  }
}

class _UploadHint extends StatelessWidget {
  const _UploadHint();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.file_upload_outlined, size: 20),
      const SizedBox(height: 8),
      Text(
        'workspace_upload_hint'.tr(context: context),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      Text(
        'workspace_upload_types'.tr(context: context),
        style: const TextStyle(fontSize: 12, color: QaderDesign.blue),
      ),
    ],
  );
}

class _PickedFile extends StatelessWidget {
  const _PickedFile({required this.name, required this.onRemove});
  final String name;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        const Icon(Icons.image_outlined, color: QaderDesign.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        IconButton(
          tooltip: 'workspace_upload_remove'.tr(context: context),
          onPressed: onRemove,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
}

/// Two side-by-side boxes, one selected ("Are you a company?").
class WorkspaceYesNo extends StatelessWidget {
  const WorkspaceYesNo({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (option, key) in const [(true, 'yes'), (false, 'no')]) ...[
        if (!option) const SizedBox(width: 12),
        Expanded(
          child: _ChoiceBox(
            label: 'workspace_$key'.tr(context: context),
            selected: value == option,
            onTap: onChanged == null ? null : () => onChanged!(option),
          ),
        ),
      ],
    ],
  );
}

/// Team size bands as radio boxes, two per row.
class WorkspaceSizeBands extends FormField<String> {
  WorkspaceSizeBands({
    super.key,
    required ValueChanged<String> onChanged,
    super.enabled,
  }) : super(
         validator: (value) => value == null ? 'field_required'.tr() : null,
         builder: (field) => Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             LayoutBuilder(
               builder: (context, constraints) => Wrap(
                 spacing: 12,
                 runSpacing: 12,
                 children: [
                   for (final band in workspaceSizeBands)
                     SizedBox(
                       width: (constraints.maxWidth - 12) / 2,
                       child: _ChoiceBox(
                         label: band,
                         radio: true,
                         selected: field.value == band,
                         onTap: field.widget.enabled
                             ? () {
                                 field.didChange(band);
                                 onChanged(band);
                               }
                             : null,
                       ),
                     ),
                 ],
               ),
             ),
             if (field.errorText case final error?) ...[
               const SizedBox(height: 6),
               Text(
                 error,
                 style: const TextStyle(fontSize: 12, color: AppColors.red600),
               ),
             ],
           ],
         ),
       );
}

class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({
    required this.label,
    required this.selected,
    required this.onTap,
    this.radio = false,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool radio;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? QaderDesign.blue : QaderDesign.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: radio
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (radio) ...[
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? QaderDesign.blue : AppColors.neutral300,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
