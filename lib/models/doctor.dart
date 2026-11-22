/// A doctor in the "Find a doctor" list.
///
/// SAMPLE DATA ONLY: names and slots are placeholders until a real directory
/// of verified doctors exists (see the doctor portal plan). The photos are
/// AI-generated.
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String city;
  final String workTime;
  final String address;
  final String phone;
  final String nextSlot;
  final String photo;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.city,
    required this.workTime,
    required this.address,
    required this.phone,
    required this.nextSlot,
    required this.photo,
  });
}

const _kenza = 'assets/images/doctors/doctor_01_kenza_lahlou.png';
const _fatima = 'assets/images/doctors/doctor_02_fatima_zahra_lahmamssi.png';
const _wafa = 'assets/images/doctors/doctor_03_wafa_aitifail.png';
const _zoubidaAmrani =
    'assets/images/doctors/doctor_04_zoubida_amrani_hannoudi.png';
const _kawtar = 'assets/images/doctors/doctor_05_kawtar_maddah_hibat_allah.png';
const _abdelkader = 'assets/images/doctors/doctor_06_abdelkader_rhissassi.png';
const _hajar = 'assets/images/doctors/doctor_07_hajar_azagouagh.png';
const _sarrah = 'assets/images/doctors/doctor_08_sarrah_el_khadir.png';
const _firdaous =
    'assets/images/doctors/doctor_09_firdaous_ameziane_hassani.png';
const _nadia = 'assets/images/doctors/doctor_10_nadia_anoun.png';
const _latifa = 'assets/images/doctors/doctor_11_latifa_meechouat.png';
const _zoubidaElQazbani =
    'assets/images/doctors/doctor_12_zoubida_el_qazbani.png';

const sampleDoctors = <Doctor>[
  Doctor(
    id: 'fes-kenza-lahlou',
    name: 'Dr Kenza Lahlou',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–17h · Sam 9h–13h',
    address: 'Lot Belair, Imm. 5, Bensouda (près du rond-point Chabat)',
    phone: '05 32 38 26 66',
    nextSlot: 'Tue, 10:30',
    photo: _kenza,
  ),
  Doctor(
    id: 'fes-fatima-zahra-lahmamssi',
    name: 'Dr Fatima Zahra Lahmamssi',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–16h · Sam 9h–13h',
    address: 'Espace Marina, 1 Rue Abdelkrim Benjelloun',
    phone: '07 67 83 30 76',
    nextSlot: 'Wed, 14:00',
    photo: _fatima,
  ),
  Doctor(
    id: 'fes-wafa-aitifail',
    name: 'Dr Wafa Aitifail',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–16h30 · Sam 9h–13h',
    address: 'Bureaux Médina, Imm. Defacto, Av. Mohammed V',
    phone: '05 35 94 46 86',
    nextSlot: 'Thu, 09:30',
    photo: _wafa,
  ),
  Doctor(
    id: 'fes-zoubida-amrani-hannoudi',
    name: 'Dr Zoubida Amrani Hannoudi',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–16h30 · Sam 9h–13h',
    address: 'Bureaux Willaya, 6e étage, Av. Allal Ben Abdellah',
    phone: '05 35 65 12 07',
    nextSlot: 'Mon, 11:00',
    photo: _zoubidaAmrani,
  ),
  Doctor(
    id: 'fes-kawtar-maddah-hibat-allah',
    name: 'Dr Kawtar Maddah Hibat Allah',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–16h30 · Sam 9h–13h',
    address: 'Résidence Salma, 38 Bd Mohammed V',
    phone: '05 35 62 36 37',
    nextSlot: 'Wed, 10:00',
    photo: _kawtar,
  ),
  Doctor(
    id: 'fes-abdelkader-rhissassi',
    name: 'Dr Abdelkader Rhissassi',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Sam 9h–16h30',
    address: 'Bureaux Printemps, 19 Rue Abdelkhalek Torres',
    phone: '05 35 94 34 52',
    nextSlot: 'Fri, 09:30',
    photo: _abdelkader,
  ),
  Doctor(
    id: 'fes-hajar-azagouagh',
    name: 'Dr Hajar Azagouagh',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–17h · Sam 9h–13h',
    address: 'Espace Le Moulin-Atlas, Av. des FAR',
    phone: '05 35 65 23 88',
    nextSlot: 'Tue, 15:00',
    photo: _hajar,
  ),
  Doctor(
    id: 'fes-sarrah-el-khadir',
    name: 'Dr Sarrah El Khadir',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 8h30–18h · Sam 9h–13h',
    address: 'Rue Ahmed Chaouki, Ville Nouvelle',
    phone: '05 35 93 24 78',
    nextSlot: 'Wed, 11:00',
    photo: _sarrah,
  ),
  Doctor(
    id: 'fes-firdaous-ameziane-hassani',
    name: 'Dr Firdaous Ameziane Hassani',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–18h (un des 8h30) · Sam 8h30–13h',
    address: '16 Av. Assila, Atlas',
    phone: '05 35 65 98 65',
    nextSlot: 'Thu, 14:00',
    photo: _firdaous,
  ),
  Doctor(
    id: 'fes-nadia-anoun',
    name: 'Dr Nadia Anoun',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–16h · Sam 9h–13h · Dim 9h–16h (?)',
    address: '12 Av. Mohammed Slaoui',
    phone: '05 35 62 15 00',
    nextSlot: 'Mon, 10:30',
    photo: _nadia,
  ),
  Doctor(
    id: 'fes-latifa-meechouat',
    name: 'Dr Latifa Meehouat',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 9h–14h · fermé le samedi',
    address: 'Bureaux Route d’Imouzzer',
    phone: '05 35 65 71 40',
    nextSlot: 'Tue, 14:30',
    photo: _latifa,
  ),
  Doctor(
    id: 'fes-zoubida-el-qazbani',
    name: 'Dr Zoubida El Qazbani',
    specialty: 'Endocrinologist',
    city: 'Fès',
    workTime: 'Lun–Ven 8h30–16h · fermé le samedi',
    address: 'Bureaux Taiba, 21 Av. Ghassan Kanafani',
    phone: '05 35 65 26 02',
    nextSlot: 'Fri, 11:30',
    photo: _zoubidaElQazbani,
  ),
];

/// Doctors of [specialty] in [city] (empty when none are listed).
List<Doctor> doctorsIn(String? city, {String specialty = 'Endocrinologist'}) =>
    city == null
    ? const []
    : sampleDoctors
          .where((d) => d.city == city && d.specialty == specialty)
          .toList();

Doctor doctorById(String id) =>
    sampleDoctors.firstWhere((d) => d.id == id, orElse: () => sampleDoctors[0]);
