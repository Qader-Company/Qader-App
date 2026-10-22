import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';

class ProfileUpload extends StatefulWidget {
  const ProfileUpload({
    super.key,
    required this.files,
    required this.onChanged,
    this.images = false,
  });
  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onChanged;
  final bool images;
  @override
  State<ProfileUpload> createState() => _ProfileUploadState();
}

class _ProfileUploadState extends State<ProfileUpload> {
  bool _picking = false;
  Future<void> _pick(FormFieldState<List<PlatformFile>> field) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final extensions = widget.images
          ? ['png', 'jpg', 'jpeg']
          : ['pdf', 'doc', 'docx'];
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: widget.images,
        withData: widget.images,
      );
      if (!mounted || result == null) return;
      final limit = (widget.images ? 5 : 10) * 1024 * 1024;
      if (result.files.any(
        (f) =>
            f.size > limit || !extensions.contains(f.extension?.toLowerCase()),
      )) {
        _error(
          widget.images
              ? 'Choose PNG or JPG images up to 5 MB each'
              : 'Choose a PDF or DOC file up to 10 MB',
        );
        return;
      }
      final files = widget.images
          ? [...widget.files, ...result.files]
          : result.files.take(1).toList();
      if (files.length > 5) {
        _error('You can select up to 5 images');
        return;
      }
      if (widget.images && files.any((f) => f.bytes == null)) {
        _error('Could not read this file. Please try again.');
        return;
      }
      field.didChange(files);
      widget.onChanged(files);
    } catch (_) {
      if (mounted) _error('Could not read this file. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _error(String text) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(pc(context, text))));
  @override
  Widget build(BuildContext context) => FormField<List<PlatformFile>>(
    initialValue: widget.files,
    validator: widget.images
        ? null
        : (v) => v == null || v.isEmpty
              ? pc(context, 'Please select your CV')
              : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _picking ? null : () => _pick(field),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(minHeight: 158),
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : QaderDesign.border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8EFFC),
                    ),
                    child: const Center(
                      child: QaderAsset(
                        'profile_upload',
                        width: 13,
                        height: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_picking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      pc(
                        context,
                        widget.images
                            ? 'Drag & Drop images here'
                            : 'Drag & Drop your cv here',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: QaderDesign.primary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    pc(
                      context,
                      widget.images
                          ? 'PNG, JPG up to 5 MB each'
                          : 'PDF, DOC up to 10 MB',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF737373),
                    ),
                  ),
                  if (widget.images) ...[
                    const SizedBox(height: 8),
                    Text(
                      pc(context, 'Browse Files'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: QaderDesign.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              field.errorText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (widget.files.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (widget.images)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < widget.files.length; i++)
                  SizedBox(
                    width: 88,
                    height: 72,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              widget.files[i].bytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip:
                                  '${pc(context, 'Remove')} ${widget.files[i].name}',
                              icon: const QaderAsset(
                                'profile_image_remove',
                                width: 7.75,
                                height: 7.75,
                              ),
                              onPressed: () => _remove(i, field),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.files.first.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: pc(context, 'Remove CV'),
                  onPressed: () => _remove(0, field),
                  icon: const QaderAsset(
                    'profile_trash',
                    width: 16,
                    height: 18,
                  ),
                ),
              ],
            ),
          if (widget.images)
            Text(
              '${widget.files.length} / 5 ${pc(context, 'images selected')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
            ),
        ],
      ],
    ),
  );
  void _remove(int index, FormFieldState<List<PlatformFile>> field) {
    final files = [...widget.files]..removeAt(index);
    field.didChange(files);
    widget.onChanged(files);
  }
}
