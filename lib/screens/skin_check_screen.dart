import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/profile_provider.dart';
import '../providers/skin_check_provider.dart';
import '../services/ada_risk.dart';
import '../theme/ds.dart';
import '../utils/open_add_result.dart';
import '../utils/platform_helper.dart';
import '../widgets/ds_widgets.dart';
import 'find_doctor_screen.dart';
import 'profile_form_screen.dart';
import 'wellness_screen.dart';

/// For people with no blood test yet: skin signs, a private photo timeline,
/// and a short risk questionnaire (after the ADA risk test). A self-check that
/// points to a blood test when it matters. It is not a diagnosis and no model
/// analyses the photos.
class SkinCheckScreen extends StatelessWidget {
  const SkinCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.watch<SkinCheckProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final answered = [
      SkinCheckProvider.family,
      SkinCheckProvider.pressure,
      SkinCheckProvider.active,
      if (profile?.female ?? false) SkinCheckProvider.gestational,
    ].every((k) => skin.answer(k) != null);

    int? score;
    if (profile != null && answered) {
      score = AdaRisk.score(
        AdaRiskInput(
          age: profile.age,
          female: profile.female,
          bmi: profile.bmi,
          gestationalDiabetes:
              skin.answer(SkinCheckProvider.gestational) ?? false,
          familyHistory: skin.answer(SkinCheckProvider.family) ?? false,
          highBloodPressure: skin.answer(SkinCheckProvider.pressure) ?? false,
          physicallyActive: skin.answer(SkinCheckProvider.active) ?? false,
        ),
      );
    }

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: DsBackButton(),
              ),
              const SizedBox(height: 26),
              const DsTitle('Skin and', 'body check', size: 36),
              const SizedBox(height: 14),
              Text(
                'No blood test yet? Some signs can point to insulin '
                        'resistance. This is a self-check, not a diagnosis.'
                    .tr,
                style: DS.text(
                  size: 15.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle('1. Look for these signs'.tr),
              _QuestionCard(
                title: 'Dark, thick, velvety patches'.tr,
                detail:
                    'On the neck, in the armpits or in the groin. They '
                            'can look like dirt that does not wash off.'
                        .tr,
                answer: skin.answer(SkinCheckProvider.patches),
                onAnswer: (v) => skin.setAnswer(SkinCheckProvider.patches, v),
              ),
              const SizedBox(height: 10),
              _QuestionCard(
                title: 'Small skin tags'.tr,
                detail:
                    'Soft little growths on the neck, armpits or eyelids.'.tr,
                answer: skin.answer(SkinCheckProvider.tags),
                onAnswer: (v) => skin.setAnswer(SkinCheckProvider.tags, v),
              ),
              const SizedBox(height: 22),
              _SectionTitle('2. Photos to compare over time'.tr),
              const _PhotoSection(),
              const SizedBox(height: 22),
              _SectionTitle('3. Your risk factors'.tr),
              if (profile == null)
                DsCard(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add your age, height and weight first. They are part '
                                'of the score.'
                            .tr,
                        style: DS.text(
                          size: 14.5,
                          weight: FontWeight.w500,
                          color: DS.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DsPrimaryButton(
                        label: 'Add my measurements'.tr,
                        height: 52,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileFormScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _QuestionCard(
                  title: 'A parent, brother or sister has diabetes'.tr,
                  answer: skin.answer(SkinCheckProvider.family),
                  onAnswer: (v) => skin.setAnswer(SkinCheckProvider.family, v),
                ),
                const SizedBox(height: 10),
                _QuestionCard(
                  title: 'High blood pressure'.tr,
                  detail: 'Told by a doctor, or on treatment for it.'.tr,
                  answer: skin.answer(SkinCheckProvider.pressure),
                  onAnswer: (v) =>
                      skin.setAnswer(SkinCheckProvider.pressure, v),
                ),
                const SizedBox(height: 10),
                _QuestionCard(
                  title: 'Physically active most days'.tr,
                  detail: 'About 30 minutes of brisk activity on most days.'.tr,
                  answer: skin.answer(SkinCheckProvider.active),
                  onAnswer: (v) => skin.setAnswer(SkinCheckProvider.active, v),
                ),
                if (profile.female) ...[
                  const SizedBox(height: 10),
                  _QuestionCard(
                    title: 'Diabetes during a pregnancy'.tr,
                    answer: skin.answer(SkinCheckProvider.gestational),
                    onAnswer: (v) =>
                        skin.setAnswer(SkinCheckProvider.gestational, v),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              _ResultCard(score: score, skinSign: skin.hasSkinSign),
              const SizedBox(height: 18),
              Text(
                'This check does not diagnose anything. Only a blood test and '
                        'a doctor can.'
                    .tr,
                textAlign: TextAlign.center,
                style: DS.text(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: DS.text(size: 17, weight: FontWeight.w700)),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.title,
    required this.answer,
    required this.onAnswer,
    this.detail,
  });
  final String title;
  final String? detail;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    Widget choice(String label, bool value) => Expanded(
      child: Semantics(
        button: true,
        selected: answer == value,
        label: '$title: $label',
        child: GestureDetector(
          onTap: () => onAnswer(value),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: answer == value ? DS.navy : DS.field,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: DS.text(
                size: 15,
                weight: FontWeight.w700,
                color: answer == value ? Colors.white : DS.muted,
              ),
            ),
          ),
        ),
      ),
    );

    return DsCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DS.text(size: 15.5, weight: FontWeight.w800, height: 1.3),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              style: DS.text(
                size: 13.5,
                weight: FontWeight.w500,
                color: DS.muted,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              choice('Yes'.tr, true),
              const SizedBox(width: 10),
              choice('No'.tr, false),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection();

  Future<void> _take(BuildContext context, String area) async {
    final skin = context.read<SkinCheckProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    await skin.addPhoto(picked.path, area);
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.watch<SkinCheckProvider>();
    final canPhoto = isMobilePlatform && !kIsWeb;

    return DsCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Take a photo of the same place every few weeks, in good light. '
                    'Photos stay on this phone. ShifAI does not analyse them; show '
                    'them to your doctor.'
                .tr,
            style: DS.text(
              size: 14,
              weight: FontWeight.w500,
              color: DS.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (canPhoto)
            Row(
              children: [
                Expanded(
                  child: DsOutlineButton(
                    label: 'Neck'.tr,
                    icon: Icons.photo_camera_outlined,
                    height: 52,
                    onPressed: () => _take(context, 'neck'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DsOutlineButton(
                    label: 'Armpit'.tr,
                    icon: Icons.photo_camera_outlined,
                    height: 52,
                    onPressed: () => _take(context, 'armpit'),
                  ),
                ),
              ],
            )
          else
            Text(
              'Photos are available in the phone app.'.tr,
              style: DS.text(
                size: 14,
                weight: FontWeight.w600,
                color: DS.amberText,
              ),
            ),
          if (skin.photos.isNotEmpty && canPhoto) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 118,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in skin.photos.reversed)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onLongPress: () => skin.removePhoto(p),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(p.path),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 84,
                                  height: 84,
                                  color: DS.field,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: DS.iconMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.area == 'neck' ? 'Neck' : 'Armpit'}, '
                              '${DateFormat('d MMM').format(p.date)}',
                              style: DS.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: DS.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Press and hold a photo to delete it.'.tr,
              style: DS.text(size: 12.5, color: DS.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.score, required this.skinSign});
  final int? score;
  final bool skinSign;

  @override
  Widget build(BuildContext context) {
    if (score == null && !skinSign) {
      return DsCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Text(
          'Answer the questions above to see your result.'.tr,
          style: DS.text(color: DS.muted, height: 1.45),
        ),
      );
    }

    final high = score != null && AdaRisk.isHigh(score!);
    final needsTest = high || skinSign;
    final (bg, fg) = needsTest
        ? (DS.amberTint, DS.amberText)
        : (DS.greenTint, DS.greenText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsCard(
          radius: 26,
          color: bg,
          shadow: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (score != null)
                Text(
                  'Risk score {score}'.trf({'score': score}),
                  style: DS.text(size: 22, weight: FontWeight.w800, color: fg),
                ),
              if (score != null) const SizedBox(height: 6),
              Text(
                needsTest
                    ? [
                        if (high)
                          'Your answers point to a higher chance of '
                                  'prediabetes or diabetes (5 points or more).'
                              .tr,
                        if (skinSign)
                          'Dark patches and skin tags are common with insulin '
                                  'resistance, though they can have other causes.'
                              .tr,
                        'A blood test (fasting glucose with insulin, or '
                                'HbA1c) is the way to check.'
                            .tr,
                      ].join(' ')
                    : 'Your answers point to a lower chance for now. Keep '
                              'moving and eating well, and test again if your '
                              'situation changes.'
                          .tr,
                style: DS.text(
                  size: 14.5,
                  weight: FontWeight.w600,
                  color: fg,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (needsTest) ...[
          DsPrimaryButton(
            label: 'Scan a lab report'.tr,
            icon: Icons.document_scanner_outlined,
            height: 56,
            onPressed: () => openAddResult(context),
          ),
          const SizedBox(height: 10),
          DsOutlineButton(
            label: 'Find a doctor'.tr,
            icon: Icons.medical_services_outlined,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FindDoctorScreen())),
          ),
          const SizedBox(height: 10),
        ],
        DsOutlineButton(
          label: 'Eat and move'.tr,
          icon: Icons.directions_walk_rounded,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WellnessScreen())),
        ),
      ],
    );
  }
}
