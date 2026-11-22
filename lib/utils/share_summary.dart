import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../models/lab_record.dart';

/// Opens WhatsApp with a short text summary of [latest]. Nothing is sent
/// unless the user presses send in WhatsApp.
Future<void> shareSummaryOnWhatsApp(
  BuildContext context,
  LabRecord latest,
) async {
  final text = StringBuffer('My ShifAI summary\n'.tr);
  if (latest.homaIr != null) {
    text.writeln(
      'HOMA-IR: {v} '
              '({label}) on {v2}'
          .trf({
            'v': latest.homaIr!.toStringAsFixed(2),
            'label': latest.homaIrBand!.label,
            'v2': DateFormat.yMMMd().format(latest.date),
          }),
    );
  } else {
    text.writeln(
      'Result from {v}'.trf({'v': DateFormat.yMMMd().format(latest.date)}),
    );
  }
  if (latest.fastingGlucoseMgdl != null) {
    text.writeln(
      'Fasting glucose: {v} mg/dL'.trf({
        'v': latest.fastingGlucoseMgdl!.toStringAsFixed(0),
      }),
    );
  }
  if (latest.fastingInsulinUiuml != null) {
    text.writeln(
      'Fasting insulin: {v} µIU/mL'.trf({
        'v': latest.fastingInsulinUiuml!.toStringAsFixed(1),
      }),
    );
  }
  if (latest.hba1cPercent != null) {
    text.writeln('HbA1c: ${latest.hba1cPercent!.toStringAsFixed(1)}%');
  }
  text.write('Screening tool only, not medical advice.'.tr);

  final uri = Uri.parse(
    'https://wa.me/?text=${Uri.encodeComponent(text.toString())}',
  );
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    opened = false;
  } on MissingPluginException {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Couldn't open WhatsApp on this device.".tr)),
    );
  }
}
