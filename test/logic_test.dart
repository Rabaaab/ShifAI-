import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/models/doctor.dart';
import 'package:shifai/models/lab_record.dart';
import 'package:shifai/providers/appointment_provider.dart';
import 'package:shifai/providers/medicine_provider.dart';
import 'package:shifai/services/ada_risk.dart';
import 'package:shifai/services/notices.dart';
import 'package:shifai/services/prescription_parser.dart';

void main() {
  group('doctor data', () {
    test('has twelve named doctors with work times, addresses and phones', () {
      expect(sampleDoctors, hasLength(12));
      for (final doctor in sampleDoctors) {
        expect(doctor.name, startsWith('Dr '));
        expect(doctor.workTime, isNotEmpty);
        expect(doctor.address, isNotEmpty);
        expect(doctor.phone, isNotEmpty);
      }
      expect(
        sampleDoctors.map((doctor) => doctor.photo).toSet(),
        hasLength(12),
      );
    });
  });

  group('ADA risk score', () {
    AdaRiskInput person({
      int age = 30,
      bool female = true,
      double bmi = 22,
      bool gd = false,
      bool family = false,
      bool pressure = false,
      bool active = true,
    }) => AdaRiskInput(
      age: age,
      female: female,
      bmi: bmi,
      gestationalDiabetes: gd,
      familyHistory: family,
      highBloodPressure: pressure,
      physicallyActive: active,
    );

    test('a young active woman with no risk factors scores 0', () {
      expect(AdaRisk.score(person()), 0);
    });

    test('age, sex, BMI and habits add up', () {
      // 55 -> 2, male -> 1, BMI 32 -> 2, family -> 1, pressure -> 1, inactive -> 1
      final s = AdaRisk.score(
        person(
          age: 55,
          female: false,
          bmi: 32,
          family: true,
          pressure: true,
          active: false,
        ),
      );
      expect(s, 8);
      expect(AdaRisk.isHigh(s), isTrue);
    });

    test('gestational diabetes only counts for women', () {
      expect(AdaRisk.score(person(gd: true)), 1);
      expect(
        AdaRisk.score(person(female: false, gd: true)),
        1,
      ); // male point only
    });

    test('the threshold is 5', () {
      expect(AdaRisk.isHigh(4), isFalse);
      expect(AdaRisk.isHigh(5), isTrue);
    });
  });

  group('prescription parser', () {
    test('reads French lines with doses and times', () {
      final list = PrescriptionParser.parse(
        'Dr Name Surname\n'
        '1) Metformine 850 mg\n'
        '1 comprimé matin et soir pendant le repas\n'
        '2) Atorvastatine 20mg 1cp le soir\n'
        '3) Vitamine D 100 000 UI\n'
        '1 ampoule par mois',
      );
      expect(list.map((c) => c.name), [
        'Metformine',
        'Atorvastatine',
        'Vitamine D',
      ]);
      expect(list[0].dose, '850 mg');
      expect(list[0].times, ['08:00', '20:00']);
      expect(list[0].note, 'with meals');
      expect(list[1].dose, '20mg');
      expect(list[1].times, ['20:00']);
      expect(list[2].dose, '100 000 UI');
      expect(list[2].timesGuessed, isTrue);
    });

    test('reads "3 fois par jour" and English frequencies', () {
      final fr = PrescriptionParser.parse(
        'Amoxicilline 500 mg 3 fois par jour',
      );
      expect(fr.single.times, ['08:00', '13:00', '20:00']);
      final en = PrescriptionParser.parse('Metformin 500 mg twice daily');
      expect(en.single.times, ['08:00', '20:00']);
    });

    test('lines without a dose are ignored', () {
      expect(
        PrescriptionParser.parse('Ordonnance\nFès, le 12/10/2026'),
        isEmpty,
      );
    });
  });

  group('notifications', () {
    final now = DateTime(2026, 11, 26, 14, 0); // a Thursday

    List<AppNotice> build({
      List<LabRecord> records = const [],
      Appointment? appointment,
      List<Medicine> medicines = const [],
      bool reminders = false,
      int minutes = 200,
    }) => buildNotices(
      records: records,
      appointment: appointment,
      medicines: medicines,
      medicineReminders: reminders,
      weekMinutes: minutes,
      now: now,
    );

    test('a new user is asked to scan a first report', () {
      expect(build().map((n) => n.id), ['first-scan']);
    });

    test('a high result without a doctor suggests one', () {
      final high = LabRecord(
        id: 'r1',
        date: DateTime(2026, 11, 20),
        fastingGlucoseMgdl: 112,
        fastingInsulinUiuml: 12.5,
      );
      final ids = build(records: [high]).map((n) => n.id);
      expect(ids, contains('doctor-r1'));
      expect(ids, isNot(contains('first-scan')));
    });

    test('an old result asks for a new test', () {
      final old = LabRecord(
        id: 'r2',
        date: DateTime(2026, 6, 1),
        fastingGlucoseMgdl: 90,
        fastingInsulinUiuml: 5,
      );
      expect(build(records: [old]).map((n) => n.id), contains('lab-r2'));
    });

    test(
      'medicine is only due when reminders are on and the time has passed',
      () {
        const due = Medicine(
          id: 'm1',
          name: 'Medicine name',
          dose: '500 mg',
          note: '',
          time: '13:00',
        );
        const later = Medicine(
          id: 'm2',
          name: 'Medicine name',
          dose: '500 mg',
          note: '',
          time: '20:00',
        );
        expect(
          build(medicines: [due, later]).any((n) => n.id.startsWith('med-')),
          isFalse,
        );
        final ids = build(
          medicines: [due, later],
          reminders: true,
        ).map((n) => n.id);
        expect(ids.where((i) => i.startsWith('med-m1')), hasLength(1));
        expect(ids.where((i) => i.startsWith('med-m2')), isEmpty);
      },
    );

    test('low activity late in the week gets a nudge', () {
      expect(build(minutes: 40).any((n) => n.id.startsWith('move-')), isTrue);
      expect(build(minutes: 150).any((n) => n.id.startsWith('move-')), isFalse);
    });
  });
}
