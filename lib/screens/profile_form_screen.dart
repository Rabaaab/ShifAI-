import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

/// My measurements: age, sex, height, weight and waist. Everything the risk
/// estimate needs, none of it requiring a blood test. Kept on this device.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  bool _female = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().profile;
    String fmt(num? v) => v == null ? '' : v.toString();
    _age = TextEditingController(text: fmt(p?.age));
    _height = TextEditingController(text: fmt(p?.heightCm));
    _weight = TextEditingController(text: fmt(p?.weightKg));
    _waist = TextEditingController(text: fmt(p?.waistCm));
    _female = p?.female ?? true;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _waist.dispose();
    super.dispose();
  }

  String? _range(String? value, double min, double max, String unit) {
    final v = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (v == null) return 'Required'.tr;
    if (v < min || v > max) {
      return 'Enter {v}–{v2} {unit}'.trf({
        'v': min.toInt(),
        'v2': max.toInt(),
        'unit': unit,
      });
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    double num(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', '.'));

    final profile = UserProfile(
      age: num(_age).round(),
      female: _female,
      heightCm: num(_height),
      weightKg: num(_weight),
      waistCm: num(_waist),
    );
    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    await provider.save(profile);
    navigator.pop();
  }

  Widget _tile(
    TextEditingController controller,
    String label,
    String unit,
    String? Function(String?) validator, {
    bool digitsOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DS.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DS.text(size: 14, weight: FontWeight.w600, color: DS.muted),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: TextInputType.numberWithOptions(decimal: !digitsOnly),
            style: DS.text(
              size: 30,
              weight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
              suffixText: unit,
              suffixStyle: DS.text(
                size: 14,
                weight: FontWeight.w600,
                color: DS.muted,
              ),
              errorStyle: DS.text(size: 12, color: DS.redText),
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: DsBackButton(),
                      ),
                      const SizedBox(height: 24),
                      const DsTitle('My', 'measurements', size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Private. Used for your risk estimate.'.tr,
                        style: DS.text(
                          size: 15.5,
                          weight: FontWeight.w500,
                          color: DS.muted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: DS.softShadow,
                        ),
                        child: Row(
                          children: [
                            for (final entry in {
                              true: 'Female'.tr,
                              false: 'Male'.tr,
                            }.entries)
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: entry.key == _female,
                                  label: entry.value,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        setState(() => _female = entry.key),
                                    child: Container(
                                      height: 54,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: entry.key == _female
                                            ? DS.navy
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: DS.text(
                                          size: 16.5,
                                          weight: entry.key == _female
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: entry.key == _female
                                              ? Colors.white
                                              : DS.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.7,
                        children: [
                          _tile(
                            _age,
                            'Age'.tr,
                            'years',
                            (v) => _range(v, 18, 90, 'years'),
                            digitsOnly: true,
                          ),
                          _tile(
                            _height,
                            'Height'.tr,
                            'cm',
                            (v) => _range(v, 120, 230, 'cm'),
                          ),
                          _tile(
                            _weight,
                            'Weight'.tr,
                            'kg',
                            (v) => _range(v, 30, 250, 'kg'),
                          ),
                          _tile(
                            _waist,
                            'Waist'.tr,
                            'cm',
                            (v) => _range(v, 40, 200, 'cm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 22,
                              color: DS.navy,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Measure your waist at belly button level.'.tr,
                                style: DS.text(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: DS.muted,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: DsPrimaryButton(label: 'Save'.tr, onPressed: _save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
