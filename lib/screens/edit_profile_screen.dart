import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile initial;

  const EditProfileScreen({super.key, required this.initial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _age = TextEditingController(
    text: widget.initial.age?.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: _fmt(widget.initial.heightCm),
  );
  late final _weight = TextEditingController(
    text: _fmt(widget.initial.weightKg),
  );
  late Gender? _gender = widget.initial.gender;

  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  String? _optionalNumber(String? v, double min, double max, String what) {
    if (v == null || v.trim().isEmpty) return null; // fields are optional
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a number';
    if (n < min || n > max) {
      return '$what must be between ${min.toInt()} and ${max.toInt()}';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      UserProfile(
        name: _name.text.trim(),
        gender: _gender,
        age: int.tryParse(_age.text.trim()),
        heightCm: double.tryParse(_height.text.trim()),
        weightKg: double.tryParse(_weight.text.trim()),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? suffix}) {
    final c = context.colors;
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: c.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.fieldBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final decimalFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^\d*\.?\d{0,1}'),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Edit profile'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              decoration: _decoration('Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              decoration: _decoration('Gender'),
              items: [
                for (final g in [Gender.male, Gender.female])
                  DropdownMenuItem(value: g, child: Text(g.label)),
              ],
              onChanged: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration('Age', suffix: 'years'),
              validator: (v) => _optionalNumber(v, 5, 120, 'Age'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _height,
              keyboardType: decimal,
              inputFormatters: [decimalFormatter],
              decoration: _decoration('Height', suffix: 'cm'),
              validator: (v) => _optionalNumber(v, 50, 260, 'Height'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              keyboardType: decimal,
              inputFormatters: [decimalFormatter],
              decoration: _decoration('Weight', suffix: 'kg'),
              validator: (v) => _optionalNumber(v, 20, 400, 'Weight'),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
