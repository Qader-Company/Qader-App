import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../domain/talent_profile.dart';
import '../profile_copy.dart';
import 'profile_components.dart';
import '../../../../core/widgets/qader_theme.dart';

Future<TalentProfile?> editTalentProfile(
  BuildContext context,
  TalentProfile profile,
) => showModalBottomSheet<TalentProfile>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  builder: (_) => QaderTheme(child: _EditProfileSheet(profile: profile)),
);

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});
  final TalentProfile profile;
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final fields = <String, TextEditingController>{
    'Full Name': TextEditingController(text: widget.profile.name),
    'Job Title': TextEditingController(text: widget.profile.title),
    'Email': TextEditingController(text: widget.profile.email),
    'Phone Number': TextEditingController(text: widget.profile.phone),
    'WhatsApp': TextEditingController(text: widget.profile.whatsapp),
    'Professional Summary': TextEditingController(text: widget.profile.summary),
  };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      24,
      16,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: ProfileStack(
          children: [
            const ProfileHeading('Edit Profile'),
            Text(
              tc(context, 'Changes are kept for this preview session only'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF737373)),
            ),
            for (final entry in fields.entries)
              DefaultFormField(
                compact: true,
                label: tc(context, entry.key),
                controller: entry.value,
                maxLines: entry.key == 'Professional Summary' ? 4 : 1,
                keyboardType: entry.key == 'Email'
                    ? TextInputType.emailAddress
                    : entry.key == 'Phone Number' || entry.key == 'WhatsApp'
                    ? TextInputType.phone
                    : TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tc(context, 'This field is required');
                  }
                  if (entry.key == 'Email' &&
                      !RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(value.trim())) {
                    return tc(context, 'Enter a valid email');
                  }
                  if ((entry.key == 'Phone Number' ||
                          entry.key == 'WhatsApp') &&
                      (!RegExp(r'^\+?[0-9\s()-]+$').hasMatch(value) ||
                          value.replaceAll(RegExp(r'[^0-9]'), '').length < 7)) {
                    return tc(context, 'Enter a valid phone number');
                  }
                  return null;
                },
              ),
            Row(
              children: [
                Expanded(
                  child: DefaultButton.compact(
                    text: tc(context, 'Cancel'),
                    isOutlined: true,
                    color: const Color(0xFFD4D4D4),
                    textColor: const Color(0xFF525252),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton.compact(
                    text: tc(context, 'Save Changes'),
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        widget.profile.copyWith(
                          name: fields['Full Name']!.text.trim(),
                          title: fields['Job Title']!.text.trim(),
                          email: fields['Email']!.text.trim(),
                          phone: fields['Phone Number']!.text.trim(),
                          whatsapp: fields['WhatsApp']!.text.trim(),
                          summary: fields['Professional Summary']!.text.trim(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
