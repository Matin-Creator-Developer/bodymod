import 'package:flutter/material.dart';
import 'part1_core.dart';
import 'part2_home_meals.dart';
import 'part3_body_gym_chat.dart';
import 'part4_profile_pro_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  runApp(BodyModApp(appState: appState));
}

class BodyModApp extends StatefulWidget {
  final AppState appState;
  const BodyModApp({super.key, required this.appState});

  @override
  State<BodyModApp> createState() => _BodyModAppState();
}

class _BodyModAppState extends State<BodyModApp> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState;
    final isDark = st.isDark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BodyMod AI',
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: BMColors.bg(isDark),
        useMaterial3: true,
      ),
      home: st.token.isEmpty
          ? AuthScreen(appState: st)
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: BMColors.bg(isDark),
                appBar: AppBar(
                  backgroundColor: BMColors.card(isDark),
                  elevation: 0,
                  title: Row(
                    children: [
                      const Text(
                        '🦾 BodyMod',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: BMColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (st.isBlueFire ? BMColors.neonBlue : BMColors.neonOrange)
                              .withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${st.isBlueFire ? "💙🔥" : "🔥"} ${st.streakCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: st.isBlueFire ? BMColors.neonBlue : BMColors.neonOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'تغییر تم تاریک / روشن',
                      onPressed: st.toggleTheme,
                      icon: Icon(
                        isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                        color: BMColors.neonGold,
                      ),
                    ),
                  ],
                ),
                body: IndexedStack(
                  index: _currentIndex,
                  children: [
                    DashboardTab(appState: st),
                    MealPlanAndScannerTab(appState: st),
                    BodyLogTab(appState: st),
                    SmartGymTab(appState: st),
                    AICoachChatTab(appState: st),
                    ProfileTab(appState: st),
                    SubscriptionAndAppsTab(appState: st),
                    if (st.isAdmin) CEOAdminTab(appState: st),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  height: 66,
                  backgroundColor: BMColors.card(isDark),
                  indicatorColor: BMColors.neonGreen.withOpacity(0.2),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined, size: 20),
                      selectedIcon: Icon(Icons.dashboard, color: BMColors.neonGreen, size: 22),
                      label: 'داشبورد',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.restaurant_outlined, size: 20),
                      selectedIcon: Icon(Icons.restaurant, color: BMColors.neonGreen, size: 22),
                      label: 'تغذیه',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.monitor_weight_outlined, size: 20),
                      selectedIcon: Icon(Icons.monitor_weight, color: BMColors.neonGreen, size: 22),
                      label: 'لاگ بدن',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.fitness_center_outlined, size: 20),
                      selectedIcon: Icon(Icons.fitness_center, color: BMColors.neonGreen, size: 22),
                      label: 'باشگاه',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline, size: 20),
                      selectedIcon: Icon(Icons.chat_bubble, color: BMColors.neonGreen, size: 22),
                      label: 'مربی AI',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline, size: 20),
                      selectedIcon: Icon(Icons.person, color: BMColors.neonGreen, size: 22),
                      label: 'پروفایل',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.workspace_premium_outlined, size: 20),
                      selectedIcon: Icon(Icons.workspace_premium, color: BMColors.neonGold, size: 22),
                      label: 'اشتراک',
                    ),
                    if (st.isAdmin)
                      const NavigationDestination(
                        icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                        selectedIcon:
                            Icon(Icons.admin_panel_settings, color: BMColors.neonBlue, size: 22),
                        label: 'پنل متین',
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
