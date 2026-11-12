/// Per-week builds (Week 1–7 lab requirements).
///
/// Every feature is always in the code; this file only decides what is
/// shown. Each `week-N` branch changes [defaultLabWeek] to N, so that build
/// shows exactly what the labs up to Week N ask for. Nothing is deleted:
/// set the number back to 7 to see everything again.
library;

/// The lab week this build represents (1–7). `master` is 7 (everything).
const int defaultLabWeek = 7;

class LabWeek {
  LabWeek._();

  /// Current week. Tests may change it; the app uses [defaultLabWeek].
  static int current = defaultLabWeek;

  /// App name used by each week's lab handout (see the vault's Course
  /// Overview). Week 7's name is the final one.
  static const _appNames = {
    1: 'LPU Smart Campus Dashboard',
    2: 'LPU Dashboard',
    3: 'LPU Student Information App',
    4: 'Student Management Dashboard',
    5: 'Smart Device Dashboard',
    6: 'Smart Connected Dashboard',
    7: 'Smart Campus Tour Guide',
  };

  static String get appName => _appNames[current] ?? _appNames[7]!;
}

/// Each feature and the lab week that introduces it. A feature is shown when
/// [LabWeek.current] is that week or later, and before [Feature.replacedIn]
/// if it has one.
///
/// Always shown (Week 1 or app frame): login with password and the
/// Student/Faculty roles, Access Denied, header with notification badge,
/// Home / Analytics / Device / Settings tabs, Dashboard / Recent Activity
/// tabs, ID card, quick-action grid, world clock, account header and Log out.
enum Feature {
  // Week 1 – dashboard shell. Weeks 1–6 only: the final Home (Week 7, the
  // Figma design) shows network status and the location card instead, and
  // the bottom nav already opens Device, Analytics and Settings.
  kpiCards(1, 'KPI cards: Network, API, Storage status', replacedIn: 7),
  dashboardTiles(
    1,
    'Action tiles: Device, Network, Reports, Settings',
    replacedIn: 7,
  ),
  // GPS status: the Week 6 Current Location card and Map stand in for the
  // Week 1 GPS KPI card, so they show from Week 1.
  location(1, 'Current Location card (Week 6, shown from Week 1)'),
  map(1, 'Map with Home, School and Workplace markers (Week 6)'),
  // Week 1 Challenge 1 (LPU theme): welcome banner with name, programme
  // and LPU Cavite, plus the campus icons.
  campusWelcome(1, 'Welcome banner and campus icons', replacedIn: 7),

  // Week 2 – API integration.
  apiDirectory(2, 'Online Directory: API users with loading and error states'),
  facultyDirectory(2, 'Faculty Directory card'),
  apiSummary(2, 'API summary stats: users, companies, emails, contacts'),
  programmeCards(
    2,
    'CCS programme cards: BSIT-NS, BSIT-WM, BSCS-DS, BSCS-SE',
    replacedIn: 7,
  ),

  // Week 3 – forms, navigation, local storage, file export.
  registrationForm(3, 'Registration form (Add Student)'),
  studentDirectory(
    3,
    'Student Directory: saved students list with Add Student',
  ),
  myRecord(3, 'My Record: summary page with saved data'),
  fileExport(3, 'Export to student_info.txt and File Saved'),
  aboutLpu(3, 'About LPU page, opened from the AppBar'),
  infoCards(
    3,
    'Dashboard cards: Students, Programs, Campus (Column / Row)',
    replacedIn: 7,
  ),
  // Week 4 turns the form into Add/Edit Student inside Student Records,
  // which goes back to the list after saving.
  summaryPage(3, 'Form → Summary Page → File Saved', replacedIn: 4),

  // Week 4 – CRUD, stats, real-time API sync.
  studentRecords(4, 'Student Records: list, search, filter, edit, delete'),
  grades(4, 'Grades on student records'),
  classStats(4, 'Class stats: total, average, top performer, online users'),
  syncStatus(4, 'Sync Status card, Sync Now, 15-second auto-refresh'),
  dataManagement(4, 'Settings > Data Management: refresh, reset database'),

  // Week 5 – camera and sensors.
  device(5, 'Device tab: camera, gallery, accelerometer, gyroscope, compass'),

  // Week 6 – device services and cloud.
  emergencyContacts(6, 'Emergency Contacts (call, SMS, email)'),
  cloudTasks(6, 'Cloud Tasks (Firestore)'),
  notifications(6, 'Notifications screen and reminder categories'),
  fingerprint(6, 'Fingerprint login'),
  securityCenter(6, 'Settings > Security Center'),
  appActivity(6, 'Analytics: sign-ins and app activity'),

  // Week 7 – offline sync and campus tour.
  networkStatus(7, 'Network status (green / amber / red)'),
  offlineSync(7, 'Offline queue: pending records, completed syncs, auto-sync'),
  connectivityLog(7, 'Connectivity log'),
  campusTour(7, 'Campus Tour, Location Detail, visits and bookmarks'),
  tourProgress(7, 'Tour progress card'),
  arGuide(7, 'AR campus guide (optional)');

  const Feature(this.week, this.description, {this.replacedIn});

  final int week;
  final String description;

  /// The week whose screens replace this feature (hidden from then on).
  final int? replacedIn;

  bool get on =>
      LabWeek.current >= week &&
      (replacedIn == null || LabWeek.current < replacedIn!);
}
