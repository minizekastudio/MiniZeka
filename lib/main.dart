import 'package:flutter/material.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievements.dart';
import 'age_selection.dart';
import 'app_theme.dart';
import 'avatar_manager.dart';
import 'child_manager.dart';
import 'games/attention_game.dart';
import 'games/logic_game.dart';
import 'games/math_game.dart';
import 'games/memory_game.dart';
import 'games/shape_game.dart';
import 'home_page.dart';
import 'parent_login.dart';
import 'sound_manager.dart';
import 'splash_overlay.dart';
import 'storage_migration.dart';
import 'theme_manager.dart';
import 'welcome_screen.dart';

/// HomePage, bir oyundan geri donuldugunde kartlarini tazeleyebilsin diye.
final RouteObserver<PageRoute<void>> routeObserver =
    RouteObserver<PageRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Depolanan veriyi once guncel semaya tasi, sonra oku.
  await StorageMigration.run();

  // Kayitli ayarlar uygulama acilmadan once yuklenir; aksi halde ses
  // tercihi her acilista varsayilana (acik) donuyordu.
  await ThemeManager.loadTheme();
  await SoundManager.loadSoundSetting();
  await AvatarManager.loadAvatar();
  await ChildManager.load();

  runApp(const MiniZekaApp());
}

// =====================================================
// UYGULAMA
// =====================================================

class MiniZekaApp extends StatelessWidget {
  const MiniZekaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
          builder: (context, child) => SplashOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
          title: 'Zeka Bahçesi',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: Builder(
            builder: (context) {
              return RoleSelectionPage(
                onChildTap: () => _openChildSection(context),
                onParentTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentLoginPage(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================
// ÇOCUK BÖLÜMÜ
// =====================================================

/// Yas daha once secilmemisse once yas ekranini gosterir.
Future<void> _openChildSection(BuildContext context) async {
  // await'ten once yakala: sonrasinda context gecersiz olabilir.
  final navigator = Navigator.of(context);

  final prefs = await SharedPreferences.getInstance();
  final childAge = prefs.getInt(StorageKeys.childAge);

  if (!context.mounted) return;

  if (childAge != null) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => _buildHomePage(context),
      ),
    );
    return;
  }

  navigator.push(
    MaterialPageRoute(
      builder: (_) => AgeSelectionPage(
        onAgeSelected: () {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => _buildHomePage(context),
            ),
          );
        },
      ),
    ),
  );
}

/// Ana sayfa iki ayri yerde birebir ayni sekilde kuruluyordu.
HomePage _buildHomePage(BuildContext context) {
  void open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  return HomePage(
    onAchievementsTap: () => open(const AchievementsPage()),
    onMemoryTap: () => open(const MemoryGame()),
    onAttentionTap: () => open(const AttentionGame()),
    onMathTap: () => open(const MathGame()),
    onShapeTap: () => open(const ShapeGame()),
    onLogicTap: () => open(const LogicGame()),
  );
}
