import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SafeLockApp());
}

//colours- themes
class AppColors {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151820);
  static const surface2 = Color(0xFF1C2030);
  static const surface3 = Color(0xFF232840);
  static const accent = Color(0xFFC9A84C);
  static const accent2 = Color(0xFFE8C97A);
  static const red = Color(0xFFE05252);
  static const green = Color(0xFF4CAF7D);
  static const blue = Color(0xFF5B8DEE);
  static const text = Color(0xFFE8EAF0);
  static const text2 = Color(0xFF8A90A8);
  static const text3 = Color(0xFF555D7A);
  static const border = Color(0xFF252B40);
}

//data-models

class FamilyMember {
  String name;
  String phone;
  bool isOwner;
  bool isEnabled;
  Color avatarColor;

  FamilyMember({
    required this.name,
    required this.phone,
    this.isOwner = false,
    this.isEnabled = true,
    required this.avatarColor,
  });
}

class AlertItem {
  final String title;
  final String message;
  final String time;
  final String location;
  final AlertSeverity severity;

  const AlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.location,
    required this.severity,
  });
}

enum AlertSeverity { critical, warning, info }

class LogEntry {
  final String event;
  final String who;
  final String time;
  final LogType type;

  const LogEntry({
    required this.event,
    required this.who,
    required this.time,
    required this.type,
  });
}

enum LogType { success, fail, change }


//root
class SafeLockApp extends StatelessWidget {
  const SafeLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Courier', // monospace fallback; use Google Fonts pkg for Barlow
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: const SafeLockHome(),
    );
  }
}

//main shell

class SafeLockHome extends StatefulWidget {
  const SafeLockHome({super.key});

  @override
  State<SafeLockHome> createState() => _SafeLockHomeState();
}

class _SafeLockHomeState extends State<SafeLockHome> {
  int _currentIndex = 0;

  // Shared state
  String? _otpCode;
  int _otpSecondsLeft = 0;
  Timer? _otpTimer;

  final List<FamilyMember> _members = [
    FamilyMember(name: 'Akshara Siddharthan',  phone: '+91 98765 43210', isOwner: true,  isEnabled: true,  avatarColor: AppColors.accent),
    FamilyMember(name: 'Srilekha ', phone: '+91 91234 56789', isOwner: false, isEnabled: true,  avatarColor: AppColors.blue),
    FamilyMember(name: 'Naina', phone: '+91 87654 32109', isOwner: false, isEnabled: true,  avatarColor: AppColors.green),
    FamilyMember(name: 'Nishanth', phone: '+91 87674 35409', isOwner: false, isEnabled: true,  avatarColor: AppColors.green),

  ];

  final List<AlertItem> _alerts = const [
    AlertItem(title: ' Brute Force Detected',  message: '3 consecutive wrong PINs entered in 45 seconds. Lock temporarily suspended.', time: '09:39 AM', location: 'Front Door · Arduino ID: #A1F3', severity: AlertSeverity.critical),
    AlertItem(title: ' Unknown PIN Attempt',   message: 'Unrecognized 4-digit PIN entered. Not matching any stored credentials.',        time: '08:55 AM', location: 'Front Door · Arduino ID: #A1F3', severity: AlertSeverity.warning),
    AlertItem(title: ' OTP Expired Unused',    message: 'A generated OTP (****) expired without being used within the 30-second window.', time: 'Yesterday', location: 'Front Door · Arduino ID: #A1F3', severity: AlertSeverity.warning),
    AlertItem(title: ' Password Changed',       message: 'Master PIN was updated by owner Ravi Kumar via keypad interface.',              time: '2 days ago', location: 'Front Door · Arduino ID: #A1F3', severity: AlertSeverity.info),
  ];

  final List<LogEntry> _logEntries = const [
    LogEntry(event: 'Access Granted', who: 'Ravi Kumar · PIN ••••',   time: '09:12 AM', type: LogType.success),
    LogEntry(event: 'Access Denied',  who: 'Unknown · Wrong PIN (3×)', time: '09:39 AM', type: LogType.fail),
    LogEntry(event: 'OTP Access',     who: 'Priya Kumar · OTP ••••',   time: '08:45 AM', type: LogType.success),
    LogEntry(event: 'Access Granted', who: 'Arjun Kumar · PIN ••••',   time: '08:30 AM', type: LogType.success),
    LogEntry(event: 'Access Denied',  who: 'Unknown · Wrong PIN',      time: '08:55 AM', type: LogType.fail),
    LogEntry(event: 'PIN Changed',    who: 'Ravi Kumar · Keypad',      time: '2 days',   type: LogType.change),
    LogEntry(event: 'Access Granted', who: 'Ravi Kumar · PIN ••••',    time: 'YDA 6PM',  type: LogType.success),
  ];

  void _generateOtp() {
    _otpTimer?.cancel();
    final code = (1000 + Random().nextInt(9000)).toString();
    setState(() {
      _otpCode = code;
      _otpSecondsLeft = 30;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _otpSecondsLeft--;
        if (_otpSecondsLeft <= 0) {
          _otpCode = null;
          t.cancel();
        }
      });
    });
  }

  void _addMember(FamilyMember m) => setState(() => _members.add(m));
  void _toggleMember(int i, bool v) => setState(() => _members[i].isEnabled = v);

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        otpCode: _otpCode,
        otpSeconds: _otpSecondsLeft,
        onGenerateOtp: _generateOtp,
        onGoToAlerts: () => setState(() => _currentIndex = 2),
        onGoToCommunity: () => setState(() => _currentIndex = 1),
        onGoToLog: () => setState(() => _currentIndex = 3),
      ),
      CommunityScreen(
        members: _members,
        onAddMember: _addMember,
        onToggleMember: _toggleMember,
      ),
      AlertsScreen(alerts: _alerts),
      LogScreen(entries: _logEntries),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: screens[_currentIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        alertCount: 3,
      ),
    );
  }
}


//btm-nav
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertCount;
  const _BottomNav({required this.currentIndex, required this.onTap, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.lock_rounded,          label: 'Home',      color: AppColors.accent),
      _NavItem(icon: Icons.group_rounded,          label: 'Community', color: AppColors.blue),
      _NavItem(icon: Icons.warning_amber_rounded,  label: 'Alerts',    color: AppColors.red, badge: alertCount),
      _NavItem(icon: Icons.description_rounded,    label: 'Log',       color: AppColors.green),
    ];

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = currentIndex == i;
          final item = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40, height: 36,
                        decoration: BoxDecoration(
                          color: active ? item.color.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: active ? item.color : AppColors.text3, size: 20),
                      ),
                      if (item.badge != null && item.badge! > 0)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 1.5),
                            ),
                            child: Center(
                              child: Text('${item.badge}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.label,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: active ? item.color : AppColors.text3,
                    )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  final int? badge;
  const _NavItem({required this.icon, required this.label, required this.color, this.badge});
}


//homescreen

class HomeScreen extends StatelessWidget {
  final String? otpCode;
  final int otpSeconds;
  final VoidCallback onGenerateOtp;
  final VoidCallback onGoToAlerts;
  final VoidCallback onGoToCommunity;
  final VoidCallback onGoToLog;

  const HomeScreen({
    super.key,
    required this.otpCode,
    required this.otpSeconds,
    required this.onGenerateOtp,
    required this.onGoToAlerts,
    required this.onGoToCommunity,
    required this.onGoToLog,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                _iconBox(Icons.lock_rounded, AppColors.accent),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SAFELOCK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1)),
                  const Text('Arduino Keypad Security System', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Alert banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: onGoToAlerts,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    border: Border.all(color: AppColors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    _blinkDot(AppColors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('⚠ FRAUD ALERT ACTIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text('3 failed attempts detected — 2 min ago', style: const TextStyle(fontSize: 11, color: Color(0xFFE8A0A0))),
                    ])),
                    const Icon(Icons.chevron_right, color: AppColors.red, size: 16),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lock hero
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1E2E), Color(0xFF0F1220)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('DOOR STATUS', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.text3)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _blinkDot(AppColors.red),
                        const SizedBox(width: 8),
                        const Text('LOCKED', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 1)),
                      ]),
                    ]),
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.12),
                        border: Border.all(color: AppColors.red.withOpacity(0.25)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppColors.red, size: 28),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(children: [
                    _metaItem('LAST ACCESS', '09:12 AM'),
                    const SizedBox(width: 24),
                    _metaItem('BY', 'RAVI'),
                    const SizedBox(width: 24),
                    _metaItem('ATTEMPTS', '3', valueColor: AppColors.red),
                  ]),
                ]),
              ),
            ),

            // OTP Section
            _sectionLabel('ONE-TIME PASSWORD'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    // Generate button
                    GestureDetector(
                      onTap: onGenerateOtp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFA8722A)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Text('Generate OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D0F14), letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // OTP display
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: otpCode != null ? AppColors.accent.withOpacity(0.06) : AppColors.surface2,
                          border: Border.all(color: otpCode != null ? AppColors.accent.withOpacity(0.4) : AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          if (otpCode != null)
                            Text(otpCode!, style: const TextStyle(fontSize: 22, color: AppColors.accent2, letterSpacing: 8, fontFamily: 'Courier'))
                          else
                            const Text('Press to generate', style: TextStyle(fontSize: 12, color: AppColors.text3, fontStyle: FontStyle.italic)),
                          if (otpCode != null)
                            Text('${otpSeconds}s', style: TextStyle(fontSize: 11, color: otpSeconds <= 10 ? AppColors.red : AppColors.text3, fontFamily: 'Courier')),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text('OTP expires in 30 seconds · Share with trusted contacts only',
                    style: TextStyle(fontSize: 11, color: AppColors.text3)),
                ]),
              ),
            ),

            // Quick Actions
            _sectionLabel('QUICK ACCESS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(child: _quickCard(
                  icon: Icons.group_rounded, color: AppColors.blue,
                  title: 'Community', desc: '3 members active',
                  onTap: onGoToCommunity,
                )),
                const SizedBox(width: 10),
                Expanded(child: _quickCard(
                  icon: Icons.description_rounded, color: AppColors.green,
                  title: 'Access Log', desc: '18 entries today',
                  onTap: onGoToLog,
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCard({required IconData icon, required Color color, required String title, required String desc, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
        ]),
      ),
    );
  }

  Widget _metaItem(String label, String value, {Color? valueColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3, letterSpacing: 1)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.text2, fontFamily: 'Courier')),
    ]);
  }
}


//communityscreen
class CommunityScreen extends StatelessWidget {
  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onAddMember;
  final void Function(int, bool) onToggleMember;

  const CommunityScreen({super.key, required this.members, required this.onAddMember, required this.onToggleMember});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              _iconBox(Icons.group_rounded, AppColors.blue),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('COMMUNITY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1)),
                const Text('Family lock access management', style: TextStyle(fontSize: 11, color: AppColors.text3)),
              ]),
            ]),
          ),
          _sectionLabel('MEMBERS (${members.length})'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: members.length + 1,
              itemBuilder: (ctx, i) {
                if (i == members.length) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: GestureDetector(
                      onTap: () => _showAddModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add, color: AppColors.text3, size: 16),
                          SizedBox(width: 8),
                          Text('ADD FAMILY MEMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                  );
                }
                final m = members[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      // Avatar
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: m.avatarColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(m.name[0], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: m.avatarColor))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.3)),
                        const SizedBox(height: 2),
                        Text(m.phone, style: const TextStyle(fontSize: 12, color: AppColors.text3, fontFamily: 'Courier')),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: m.isOwner ? AppColors.accent.withOpacity(0.15) : AppColors.blue.withOpacity(0.12),
                            border: Border.all(color: m.isOwner ? AppColors.accent.withOpacity(0.3) : AppColors.blue.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(m.isOwner ? 'OWNER' : 'MEMBER',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: m.isOwner ? AppColors.accent : AppColors.blue, letterSpacing: 1)),
                        ),
                        if (!m.isOwner) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => onToggleMember(i, !m.isEnabled),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36, height: 20,
                              decoration: BoxDecoration(
                                color: m.isEnabled ? AppColors.green : AppColors.surface3,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: m.isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  width: 16, height: 16,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final colors = [AppColors.red, AppColors.blue, AppColors.green, AppColors.accent];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('ADD FAMILY MEMBER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 0.5)),
            const SizedBox(height: 20),
            _modalField('FULL NAME', nameCtrl, 'e.g. Sunita Kumar'),
            const SizedBox(height: 14),
            _modalField('PHONE NUMBER', phoneCtrl, '+91 XXXXX XXXXX', keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  onAddMember(FamilyMember(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? 'No number' : phoneCtrl.text.trim(),
                    avatarColor: colors[Random().nextInt(colors.length)],
                  ));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ADD MEMBER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D0F14), letterSpacing: 1.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _modalField(String label, TextEditingController ctrl, String hint, {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3, letterSpacing: 1)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.text, fontFamily: 'Courier', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.text3),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}
//alertscreen
class AlertsScreen extends StatefulWidget {
  final List<AlertItem> alerts;
  const AlertsScreen({super.key, required this.alerts});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _pushEnabled = true;
  bool _smsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              _iconBox(Icons.warning_amber_rounded, AppColors.red, borderColor: AppColors.red.withOpacity(0.3)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SECURITY ALERTS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1)),
                const Text('Real-time fraud & intrusion detection', style: TextStyle(fontSize: 11, color: AppColors.text3)),
              ]),
            ]),
          ),
          _sectionLabel('NOTIFICATIONS'),
          _toggleRow('Push Alerts', 'Fraudulent activity notifications', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          const SizedBox(height: 6),
          _toggleRow('SMS Alerts', 'Send to all community members', _smsEnabled, (v) => setState(() => _smsEnabled = v)),
          _sectionLabel('RECENT ALERTS'),
          ...widget.alerts.map((a) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: _AlertCard(item: a),
          )),
        ]),
      ),
    );
  }

  Widget _toggleRow(String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ])),
          GestureDetector(
            onTap: () => onChanged(!val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 26,
              decoration: BoxDecoration(color: val ? AppColors.green : AppColors.surface3, borderRadius: BorderRadius.circular(13)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: val ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem item;
  const _AlertCard({required this.item});

  Color get _barColor {
    switch (item.severity) {
      case AlertSeverity.critical: return AppColors.red;
      case AlertSeverity.warning: return AppColors.accent;
      case AlertSeverity.info: return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(children: [
          Container(width: 3, color: _barColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(item.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _barColor, letterSpacing: 0.5))),
                  Text(item.time, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontFamily: 'Courier')),
                ]),
                const SizedBox(height: 4),
                Text(item.message, style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 10, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(item.location, style: const TextStyle(fontSize: 11, color: AppColors.text3, fontFamily: 'Courier')),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}


//logscreen
class LogScreen extends StatefulWidget {
  final List<LogEntry> entries;
  const LogScreen({super.key, required this.entries});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Granted', 'Denied', 'OTP', 'Today'];

  List<LogEntry> get _filtered {
    if (_filter == 'All') return widget.entries;
    if (_filter == 'Granted') return widget.entries.where((e) => e.type == LogType.success).toList();
    if (_filter == 'Denied') return widget.entries.where((e) => e.type == LogType.fail).toList();
    if (_filter == 'OTP') return widget.entries.where((e) => e.event.contains('OTP')).toList();
    if (_filter == 'Today') return widget.entries.where((e) => !e.time.contains('days') && !e.time.contains('YDA')).toList();
    return widget.entries;
  }

  @override
  Widget build(BuildContext context) {
    final granted = widget.entries.where((e) => e.type == LogType.success).length;
    final denied = widget.entries.where((e) => e.type == LogType.fail).length;
    final otpUsed = widget.entries.where((e) => e.event.contains('OTP')).length;

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            _iconBox(Icons.description_rounded, AppColors.green),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ACCESS LOG', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: 1)),
              const Text('All entry & exit attempts', style: TextStyle(fontSize: 11, color: AppColors.text3)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Expanded(child: _statCard('$granted', 'GRANTED', AppColors.green)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('$denied', 'DENIED', AppColors.red)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('$otpUsed', 'OTP USED', AppColors.accent)),
          ]),
        ),

        // Filters
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: _filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _filter == f ? AppColors.accent : AppColors.surface,
                    border: Border.all(color: _filter == f ? AppColors.accent : AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                    color: _filter == f ? const Color(0xFF0D0F14) : AppColors.text3,
                  )),
                ),
              ),
            )).toList(),
          ),
        ),

        // Log list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final e = _filtered[i];
              final (iconData, iconColor) = switch (e.type) {
                LogType.success => (Icons.check_rounded, AppColors.green),
                LogType.fail    => (Icons.close_rounded, AppColors.red),
                LogType.change  => (Icons.edit_rounded, AppColors.accent),
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(iconData, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.event.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: 0.3)),
                      const SizedBox(height: 2),
                      Text(e.who, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                    ])),
                    Text(e.time, style: const TextStyle(fontSize: 10, color: AppColors.text3, fontFamily: 'Courier'), textAlign: TextAlign.right),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String num, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(num, style: TextStyle(fontSize: 22, color: color, fontFamily: 'Courier')),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.text3, letterSpacing: 1)),
      ]),
    );
  }
}

//shared-helpers
Widget _iconBox(IconData icon, Color color, {Color? borderColor}) {
  return Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: AppColors.surface2,
      border: Border.all(color: borderColor ?? AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
    child: Text(text, style: const TextStyle(fontSize: 11, letterSpacing: 2.5, color: AppColors.text3)),
  );
}

Widget _blinkDot(Color color) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: const Duration(milliseconds: 900),
    builder: (_, v, child) => Opacity(opacity: v, child: child),
    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
  );
}
