/// Image asset paths.
class AppAssets {
  AppAssets._();

  /// LPU crest ("A José P. Laurel Legacy").
  static const logo = 'assets/images/lpu_logo.png';

  /// Crest + "LPU · Lyceum of the Philippines University" lockup (ID card).
  static const idHeader = 'assets/images/lpu_id_header.png';

  /// LPU Cavite campus photo (ID card background).
  static const campusPhoto = 'assets/images/lpu_campus.jpg';

  /// Campus tour location photos (Week 7). Registrar and Student Center
  /// have none yet and fall back to [campusPhoto].
  static const mainBuilding = 'assets/images/locations/main_building.jpg';
  static const library = 'assets/images/locations/library.jpg';
  static const computerLab = 'assets/images/locations/computer_lab.jpg';
  static const avTheater = 'assets/images/locations/av_theater.jpg';

  /// ID portrait for the demo student account.
  static const portraitTheophilus =
      'assets/images/portrait_theophilus_nueva.jpg';

  /// ID portrait for the demo faculty account.
  static const portraitAlyssa = 'assets/images/portrait_alyssa_pocaan.jpg';
}
