import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lab_records_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

/// Emergency help. The dialer opens with the number filled in; the person
/// still has to press call. ShifAI cannot judge an emergency.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  /// 112 reaches local emergency services from most mobile phones. Change it
  /// to the national number (for example 15 or 141) if your market needs it.
  static const emergencyNumber = '112';

  Future<void> _dial(BuildContext context, String number) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: number));
    } on PlatformException {
      opened = false;
    } on MissingPluginException {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the dialer. Call {number}.'.trf({'number': number}),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final labs = context.watch<LabRecordsProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final meds = context.watch<MedicineProvider>().items;
    final doctor = context.watch<AppointmentProvider>().appointment?.doctor;

    final display = auth.displayName == 'ShifAI member'
        ? ''
        : auth.displayName;
    final who = [
      if (display.isNotEmpty) display,
      if (profile != null) '${profile.age}',
    ].join(', ');
    final homa = labs.records.where((r) => r.homaIr != null).lastOrNull?.homaIr;
    final medicineText = meds.isEmpty
        ? 'None added'.tr
        : (meds.length == 1
              ? meds.first.name
              : '${meds.first.name} +${meds.length - 1}');

    Widget idCell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DS.text(
              size: 12.5,
              weight: FontWeight.w600,
              color: const Color(0xFFB7D3E8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: DS.text(
              size: 15.5,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: DsBackButton(),
              ),
              const SizedBox(height: 26),
              const DsTitle('In an', 'emergency'),
              const SizedBox(height: 22),
              Semantics(
                button: true,
                label: 'Call emergency services'.tr,
                child: GestureDetector(
                  onTap: () => _dial(context, emergencyNumber),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                    decoration: BoxDecoration(
                      color: DS.emergency,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: DS.emergency.withValues(alpha: 0.32),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Call emergency services'.tr,
                                style: DS.text(
                                  size: 20,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Opens your phone'.tr,
                                style: DS.text(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFFFFE3E4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (doctor != null)
                DsCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "This doctor's phone number is not available in the prototype."
                            .tr,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      DsDoctorAvatar(asset: doctor.photo, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Call {name}'.trf({'name': doctor.name}),
                              style: DS.text(size: 16, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your doctor'.tr,
                              style: DS.text(
                                size: 13.5,
                                weight: FontWeight.w500,
                                color: DS.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const DsIconBadge(icon: Icons.phone_outlined, size: 46),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              DsCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call now if you have'.tr,
                      style: DS.text(size: 17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    for (final s in [
                      'Fainting or confusion'.tr,
                      'Very fast or deep breathing'.tr,
                      'Vomiting that does not stop'.tr,
                      'Chest pain or trouble breathing'.tr,
                    ]) ...[
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: DS.emergency,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s,
                              style: DS.text(
                                size: 15.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                decoration: BoxDecoration(
                  gradient: DS.navyGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: DS.cardShadow(0.22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'My medical ID'.tr,
                            style: DS.text(
                              size: 17,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Show to responders'.tr,
                            style: DS.text(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: DS.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        idCell('Name'.tr, who.isEmpty ? 'Not set'.tr : who),
                        idCell(
                          'Latest HOMA-IR'.tr,
                          homa == null
                              ? 'None yet'.tr
                              : homa.toStringAsFixed(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        idCell('Medicine'.tr, medicineText),
                        idCell('Doctor'.tr, doctor?.name ?? 'None yet'.tr),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'ShifAI cannot judge an emergency. If in doubt, call.'.tr,
                  textAlign: TextAlign.center,
                  style: DS.text(
                    size: 13.5,
                    weight: FontWeight.w500,
                    color: DS.muted,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
