import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/child_manager.dart';
import 'package:mini_zeka/welcome_screen.dart';

/// Giris ekrani cocugun adini dogru gosteriyor mu?
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() => ChildManager.nameNotifier.value = '');

  Future<void> pumpKarsilama(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionPage(
          onChildTap: () {},
          onParentTap: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('ad girilmemişse sade başlık ve "Çocuk" görünür', (tester) async {
    ChildManager.nameNotifier.value = '';

    await pumpKarsilama(tester);

    expect(find.text('Zeka Bahçesi'), findsOneWidget);
    expect(find.text('Çocuk'), findsOneWidget);
    expect(find.textContaining("'nın"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ad girildiyse başlık ve kart adı taşımadan görünür',
      (tester) async {
    ChildManager.nameNotifier.value = 'Asya';

    await pumpKarsilama(tester);

    // Baslik iki satir: "Asya'nın" + "Zeka Bahçesi"
    expect(find.text("Asya'nın"), findsOneWidget);
    expect(find.text('Zeka Bahçesi'), findsOneWidget);

    // Rol karti artik "Çocuk" degil cocugun adini yaziyor
    expect(find.text('Asya'), findsOneWidget);
    expect(find.text('Çocuk'), findsNothing);

    // Tasma varsa burada patlar
    expect(tester.takeException(), isNull);
  });

  testWidgets('uzun ad ekrani taşırmaz', (tester) async {
    ChildManager.nameNotifier.value = 'Abdülkerim';

    await pumpKarsilama(tester);

    expect(find.text("Abdülkerim'in"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
