import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

/// A country selector beside the national number; API controllers stay separate.
class ProfilePhoneInput extends StatefulWidget {
  const ProfilePhoneInput({
    super.key,
    required this.label,
    required this.codeController,
    required this.numberController,
    required this.validator,
  });

  final String label;
  final TextEditingController codeController;
  final TextEditingController numberController;
  final FormFieldValidator<String> validator;

  @override
  State<ProfilePhoneInput> createState() => _ProfilePhoneInputState();
}

class _ProfilePhoneInputState extends State<ProfilePhoneInput> {
  static final _countries = CountryService().getAll();
  Country? _selectedCountry;

  Country? _country(String code) {
    if (_selectedCountry != null && '+${_selectedCountry!.phoneCode}' == code) {
      return _selectedCountry;
    }
    final matches = _countries.where(
      (country) => '+${country.phoneCode}' == code,
    );
    // A restored +1 alone cannot distinguish Canada from the United States.
    return matches.length == 1 ? matches.single : null;
  }

  void _pickCountry(FormFieldState<String> field) {
    FocusScope.of(context).unfocus();
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      useSafeArea: true,
      header: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(pc(context, 'Select country')),
      ),
      countryListTheme: CountryListThemeData(
        inputDecoration: InputDecoration(
          labelText: pc(context, 'Search country or code'),
          prefixIcon: const Icon(Icons.search),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      onSelect: (country) {
        if (!mounted) return;
        final code = '+${country.phoneCode}';
        setState(() => _selectedCountry = country);
        widget.codeController.text = code;
        field.didChange(code);
      },
    );
  }

  @override
  Widget build(BuildContext context) => ProfileColumn(
    gap: 6,
    children: [
      ProfileLabel(widget.label, required: true),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: FormField<String>(
              initialValue: widget.codeController.text,
              validator: (_) =>
                  RegExp(
                    r'^\+[1-9][0-9]{0,3}$',
                  ).hasMatch(widget.codeController.text.trim())
                  ? null
                  : pc(context, 'Select country'),
              builder: (field) => ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.codeController,
                builder: (context, value, _) {
                  final code = value.text.trim();
                  final country = _country(code);
                  final name = country == null
                      ? pc(context, 'Select country')
                      : CountryLocalizations.of(
                              context,
                            )?.countryName(countryCode: country.countryCode) ??
                            country.name;
                  return Semantics(
                    button: true,
                    label: '${pc(context, widget.label)}: $name $code',
                    child: InkWell(
                      key: ValueKey('${widget.label}-country'),
                      onTap: () => _pickCountry(field),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          errorText: field.errorText,
                          errorMaxLines: 3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                code.isEmpty
                                    ? pc(context, 'Country')
                                    : '${country?.countryCode ?? ''} $code'
                                          .trim(),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 20 / 12,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ProfileInput(
                '',
                controller: widget.numberController,
                hint: 'Enter phone number',
                type: TextInputType.phone,
                validator: widget.validator,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
