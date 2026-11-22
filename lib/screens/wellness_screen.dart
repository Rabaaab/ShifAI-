import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';
import '../models/wellness_content.dart';
import '../providers/activity_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

enum _Tab { eat, move }

/// Food and sport guidance for everyone, with or without a doctor.
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key, this.startOnMove = false});
  final bool startOnMove;

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  late _Tab _tab = widget.startOnMove ? _Tab.move : _Tab.eat;

  String _focus(HomaIrBand? band, double? bmi) {
    switch (band) {
      case HomaIrBand.significantResistance:
        return 'Start gently and steadily: a 10-minute walk after your biggest '
                'meal, and swap sugary drinks for water or plain mint tea. Talk to '
                'your doctor before starting anything intense.'
            .tr;
      case HomaIrBand.earlyResistance:
        return 'This is the stage where habits matter most. Aim for 150 minutes '
                'of activity a week, walk after meals, and cut sugar in tea and '
                'drinks first.'
            .tr;
      case HomaIrBand.optimal:
      case HomaIrBand.normal:
        return 'Your last result is in a good range. Keep your routine: '
                'vegetables and legumes at most meals, and stay active most days.'
            .tr;
      case null:
        return bmi != null && bmi >= 25
            ? 'A 10-minute walk after your biggest meal and fewer sugary '
                      'drinks are the two easiest places to start.'
                  .tr
            : 'Walk for 10 minutes after your biggest meal and fill half your '
                      'plate with vegetables. Small habits, every day.'
                  .tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labs = context.watch<LabRecordsProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final withHoma = labs.records.where((r) => r.homaIr != null).toList();
    final band = withHoma.isEmpty ? null : withHoma.last.homaIrBand;

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
              const DsTitle('Eat and', 'move', size: 36),
              const SizedBox(height: 14),
              Text(
                'General guidance to lower your risk of diabetes.'.tr,
                style: DS.text(
                  size: 15.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              DsSegmented<_Tab>(
                options: {_Tab.eat: 'Eat'.tr, _Tab.move: 'Move'.tr},
                value: _tab,
                height: 48,
                fontSize: 15,
                background: Colors.white,
                radius: 22,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 18),
              _FocusCard(text: _focus(band, profile?.bmi)),
              const SizedBox(height: 20),
              if (_tab == _Tab.eat) ..._eat() else ..._move(),
              const SizedBox(height: 22),
              Text(
                'General advice, not a personal diet or exercise plan. A doctor '
                        'or dietitian can adapt it to you.'
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

  List<Widget> _eat() => [
    const _PlateCard(),
    const SizedBox(height: 22),
    for (final level in FoodLevel.values) ...[
      _FoodGroup(
        level: level,
        items: foodItems.where((f) => f.level == level).toList(),
      ),
      const SizedBox(height: 18),
    ],
  ];

  List<Widget> _move() => [
    const _WeekCard(),
    const SizedBox(height: 16),
    const _AfterMealCard(),
    const SizedBox(height: 22),
    Text(
      'Get your heart rate up'.tr,
      style: DS.text(size: 17, weight: FontWeight.w700),
    ),
    const SizedBox(height: 10),
    for (final e in aerobicIdeas) _IdeaRow(e),
    const SizedBox(height: 18),
    Text(
      'Build muscle, 2 days a week'.tr,
      style: DS.text(size: 17, weight: FontWeight.w700),
    ),
    const SizedBox(height: 10),
    for (final e in strengthIdeas) _IdeaRow(e),
    const SizedBox(height: 18),
    DsCard(
      radius: 24,
      color: DS.amberTint,
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_border_rounded, color: DS.amberText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Stop and get help if you feel chest pain, dizziness or severe '
                      'shortness of breath. With a heart condition, or a high result, '
                      'check with your doctor before starting.'
                  .tr,
              style: DS.text(
                size: 14,
                weight: FontWeight.w600,
                color: DS.amberText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    ),
  ];
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: DS.navyGradient,
      borderRadius: BorderRadius.circular(28),
      boxShadow: DS.cardShadow(0.22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your focus'.tr,
          style: DS.text(size: 13.5, weight: FontWeight.w700, color: DS.sky),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: DS.text(
            size: 15.5,
            weight: FontWeight.w600,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _PlateCard extends StatelessWidget {
  const _PlateCard();

  @override
  Widget build(BuildContext context) {
    Widget part(int flex, Color color, String label, IconData icon) => Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: DS.ink),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: DS.text(size: 12.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build your plate'.tr,
            style: DS.text(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'The same idea for every meal, tagine or not.'.tr,
            style: DS.text(size: 14, color: DS.muted),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                part(
                  2,
                  const Color(0xFFD4EEE0),
                  'Vegetables\nhalf the plate'.tr,
                  Icons.eco_outlined,
                ),
                part(
                  1,
                  const Color(0xFFFFE2A6),
                  'Protein\na quarter'.tr,
                  Icons.set_meal_outlined,
                ),
                part(
                  1,
                  DS.skyTint,
                  'Bread, rice,\ncouscous\na quarter'.tr,
                  Icons.grain_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Eat slowly, drink water, and leave the sweets for after the meal.'
                .tr,
            style: DS.text(
              size: 14,
              weight: FontWeight.w500,
              color: DS.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodGroup extends StatelessWidget {
  const _FoodGroup({required this.level, required this.items});
  final FoodLevel level;
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (level) {
      FoodLevel.go => (DS.greenTint, DS.greenText),
      FoodLevel.watch => (DS.amberTint, DS.amberText),
      FoodLevel.limit => (DS.redTint, DS.redText),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DsPill(level.label, background: bg, foreground: fg),
        ),
        const SizedBox(height: 10),
        for (final f in items) ...[
          DsCard(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Photo(f.image),
                const SizedBox(height: 12),
                Text(
                  f.name.tr,
                  style: DS.text(size: 16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  f.examples.tr,
                  style: DS.text(
                    size: 13,
                    weight: FontWeight.w500,
                    color: DS.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  f.advice.tr,
                  style: DS.text(
                    size: 14.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final week = activity.minutesThisWeek(DateTime.now());
    final today = activity.minutesOn(DateTime.now());
    final progress = (week / weeklyGoalMinutes).clamp(0.0, 1.0);
    final done = week >= weeklyGoalMinutes;

    Widget add(int minutes) => Expanded(
      child: DsOutlineButton(
        label: '+{minutes} min'.trf({'minutes': minutes}),
        height: 48,
        fontSize: 14.5,
        fill: DS.skyTint,
        color: DS.navy,
        onPressed: () => activity.add(minutes),
      ),
    );

    return DsCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week'.tr,
                  style: DS.text(
                    size: 15,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
              ),
              if (done)
                DsPill(
                  'Goal reached'.tr,
                  background: DS.greenTint,
                  foreground: DS.greenText,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$week',
                  style: DS.text(
                    size: 42,
                    weight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                TextSpan(
                  text: ' of {weeklyGoalMinutes} min'.trf({
                    'weeklyGoalMinutes': weeklyGoalMinutes,
                  }),
                  style: DS.text(
                    size: 16,
                    weight: FontWeight.w600,
                    color: DS.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: done ? DS.green : DS.navy,
              backgroundColor: DS.skyTint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Log what you did today'.tr,
            style: DS.text(size: 14, weight: FontWeight.w600, color: DS.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              add(10),
              const SizedBox(width: 8),
              add(20),
              const SizedBox(width: 8),
              add(30),
            ],
          ),
          if (today > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Today: {today} min'.trf({'today': today}),
                    style: DS.text(
                      size: 14,
                      weight: FontWeight.w600,
                      color: DS.muted,
                    ),
                  ),
                ),
                DsTextAction(
                  'Undo today'.tr,
                  alignment: Alignment.centerRight,
                  onPressed: activity.clearToday,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AfterMealCard extends StatelessWidget {
  const _AfterMealCard();

  @override
  Widget build(BuildContext context) => DsCard(
    radius: 26,
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DsIconBadge(icon: Icons.directions_walk_rounded, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walk after you eat'.tr,
                style: DS.text(size: 16.5, weight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '10 to 15 minutes of easy walking after your biggest meal '
                        'helps your body use the sugar from it.'
                    .tr,
                style: DS.text(
                  size: 14.5,
                  weight: FontWeight.w500,
                  color: DS.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IdeaRow extends StatelessWidget {
  const _IdeaRow(this.exercise);
  final Exercise exercise;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DsCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Photo(exercise.image),
          const SizedBox(height: 12),
          Text(
            exercise.title.tr,
            style: DS.text(size: 15.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            exercise.detail.tr,
            style: DS.text(
              size: 14,
              weight: FontWeight.w500,
              color: DS.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Rounded photo at the top of a food or exercise card.
class _Photo extends StatelessWidget {
  const _Photo(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.asset(
      asset,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  );
}
