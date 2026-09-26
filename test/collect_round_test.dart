import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/collect_round.dart';
import 'package:mini_zeka/games/memory_symbols.dart';

const _seeds = 120;

Iterable<CollectWorld> _boards(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield buildCollectBoard(rung: rung, random: Random(seed));
  }
}

/// Drives the squirrel onto [item] and returns how long it took.
double _walkTo(CollectWorld world, BoardPoint target, {double limit = 8}) {
  var spent = 0.0;
  const dt = 1 / 60;

  world.steerTo(target);

  while (spent < limit && world.player.distanceTo(target) > 0.01) {
    world.step(dt);
    spent += dt;
  }

  return spent;
}

void main() {
  group('tahta', () {
    for (var rung = 0; rung < collectLadder.length; rung++) {
      final rule = collectRuleFor(rung);

      test('bölüm ${rung + 1}: kural kadar hedef ve çeldirici var', () {
        for (final world in _boards(rung)) {
          expect(world.targetTotal, rule.targetCount);
          expect(world.items.length, rule.targetCount + rule.distractorCount);
          expect(world.chasers, hasLength(rule.chaserCount));
        }
      });

      test('bölüm ${rung + 1}: taşlar üst üste binmiyor', () {
        for (final world in _boards(rung)) {
          for (var i = 0; i < world.items.length; i++) {
            for (var j = i + 1; j < world.items.length; j++) {
              expect(
                world.items[i].position.distanceTo(world.items[j].position),
                greaterThan(CollectWorld.itemRadius),
                reason: 'bölüm ${rung + 1}',
              );
            }
          }
        }
      });

      test('bölüm ${rung + 1}: tur sıfırdan başlar, taşın üstünde değil', () {
        // A face under the squirrel's starting spot was collected on the
        // first frame, so the board opened at 1 / 5.
        for (final world in _boards(rung)) {
          expect(world.collected, 0);

          for (final item in world.items) {
            expect(
              world.player.distanceTo(item.position),
              greaterThan(CollectWorld.playerRadius + CollectWorld.itemRadius),
              reason: 'bölüm ${rung + 1}: ${item.face} başlangıçta toplanır',
            );
          }
        }
      });

      test('bölüm ${rung + 1}: sincap baykuşun kucağında başlamıyor', () {
        for (final world in _boards(rung)) {
          for (final chaser in world.chasers) {
            expect(
              world.player.distanceTo(chaser.position),
              greaterThan(CollectWorld.playerRadius * 3),
            );
          }
        }
      });
    }

    test('ilk bölümde baykuş yok, sonrakilerde var', () {
      expect(collectRules.first.chaserCount, 0);

      for (final rule in collectRules.skip(1)) {
        expect(rule.chaserCount, greaterThan(0));
      }
    });

    test('baykuş her zaman sincaptan yavaş', () {
      for (final rule in collectRules) {
        expect(rule.chaserSpeed, lessThan(CollectWorld.playerSpeed / 2));
      }
    });
  });

  group('çeldiriciler', () {
    test('kolay bölümlerde hedefle aynı kümeden değil', () {
      for (final rung in [0, 1]) {
        for (final world in _boards(rung)) {
          final group = symbolClusters.firstWhere(
            (g) => g.contains(world.targetFace),
          );

          for (final item in world.items) {
            if (item.face == world.targetFace) continue;
            expect(
              group,
              isNot(contains(item.face)),
              reason: '${world.targetFace} yanında ${item.face}',
            );
          }
        }
      }
    });

    test('üst bölümlerde en az bir çeldirici hedefe benziyor', () {
      for (var rung = 2; rung < collectLadder.length; rung++) {
        for (final world in _boards(rung)) {
          final group = symbolClusters.firstWhere(
            (g) => g.contains(world.targetFace),
          );

          final lookAlikes = world.items.where(
            (item) =>
                item.face != world.targetFace && group.contains(item.face),
          );

          expect(lookAlikes, isNotEmpty, reason: 'bölüm ${rung + 1}');
        }
      }
    });

    test('toplanacak yüzlerin sayısı kuralla birebir', () {
      // A face is either worth gathering or it is not; a board that had one
      // extra target would quietly make the round longer than the rule says.
      for (var rung = 0; rung < collectLadder.length; rung++) {
        final rule = collectRuleFor(rung);

        for (final world in _boards(rung)) {
          final wanted = world.items.where(
            (item) => world.targetFaces.contains(item.face),
          );

          expect(wanted, hasLength(rule.targetCount));
          expect(world.items.length - wanted.length, rule.distractorCount);
        }
      }
    });
  });

  group('oynanış', () {
    test('doğru yüze varmak onu toplar', () {
      final world = buildCollectBoard(rung: 0, random: Random(1));
      final target = world.items.firstWhere(
        (item) => item.face == world.targetFace,
      );

      _walkTo(world, target.position);

      // Walking in a straight line can sweep up others on the way, so the
      // claim is about this item, not the total.
      expect(target.isCollected, isTrue);
      expect(world.collected, greaterThanOrEqualTo(1));
      expect(world.wrongGrabs, 0);
    });

    test('yanlış yüz toplanmaz, tur bitmez, taş kaybolmaz', () {
      final world = buildCollectBoard(rung: 0, random: Random(1));
      final wrong = world.items.firstWhere(
        (item) => item.face != world.targetFace,
      );

      _walkTo(world, wrong.position);

      expect(wrong.isCollected, isFalse);
      expect(world.wrongGrabs, 1);
      expect(world.isFinished, isFalse);
      expect(world.items, contains(wrong), reason: 'taş tahtada kalır');
    });

    test('aynı yanlış yüzde beklemek hatayı çoğaltmaz', () {
      final world = buildCollectBoard(rung: 0, random: Random(1));
      final wrong = world.items.firstWhere(
        (item) => item.face != world.targetFace,
      );

      _walkTo(world, wrong.position);

      // Standing on it must not turn one mistake into hundreds, however
      // long the child pauses there.
      for (var i = 0; i < 60 * 10; i++) {
        world.step(1 / 60);
      }

      expect(world.wrongGrabs, 1);
    });

    test('bütün hedefler toplanınca tur biter', () {
      final world = buildCollectBoard(rung: 0, random: Random(3));

      for (final item in [...world.items]) {
        if (item.face != world.targetFace) continue;
        _walkTo(world, item.position);
      }

      expect(world.collected, world.targetTotal);
      expect(world.isFinished, isTrue);
    });

    test('sincap tahtanın dışına çıkamaz', () {
      final world = buildCollectBoard(rung: 0, random: Random(2));

      _walkTo(world, const BoardPoint(5, -3));

      expect(world.player.x, inInclusiveRange(0, 1));
      expect(world.player.y, inInclusiveRange(0, 1));
    });
  });

  group('baykuş', () {
    test('yakalayınca bir tane düşürür, uyur ve tur bitmez', () {
      final world = buildCollectBoard(rung: 1, random: Random(4));
      final chaser = world.chasers.first;

      // Gather one, then stand still in the owl's path.
      final first = world.items.firstWhere(
        (item) => item.face == world.targetFace,
      );
      _walkTo(world, first.position);
      expect(world.collected, greaterThanOrEqualTo(1));

      world.steerTo(world.player);
      final before = world.collected;
      final mistakesBefore = world.wrongGrabs;
      final onBoardBefore = world.items.where((i) => !i.isCollected).length;

      for (var i = 0; i < 60 * 20 && !world.wasCaught; i++) {
        world.step(1 / 60);
      }

      expect(world.wasCaught, isTrue, reason: 'baykuş hiç yetişemedi');
      expect(world.collected, before - 1, reason: 'tam bir tane düşmeli');
      expect(
        world.items.where((i) => !i.isCollected).length,
        onBoardBefore + 1,
        reason: 'düşen taş tahtaya geri döner',
      );
      expect(chaser.isAsleep, isTrue);
      expect(world.isSafe, isTrue);
      expect(world.isFinished, isFalse);
      expect(
        world.wrongGrabs,
        mistakesBefore,
        reason: 'yakalanmak hata sayılmaz',
      );
    });

    test('uyuyan baykuş yerinden kımıldamaz', () {
      final world = buildCollectBoard(rung: 1, random: Random(4));
      final chaser = world.chasers.first;

      chaser.sleepFor = CollectWorld.sleepSeconds;
      final before = chaser.position;

      for (var i = 0; i < 60; i++) {
        world.step(1 / 60);
      }

      expect(chaser.position, before);
    });

    test('hareket eden sincabın arasını baykuş açamaz', () {
      // The owl is pressure, not a trap: while the squirrel keeps moving
      // away it is never overtaken. (Standing still in a corner is another
      // matter — being caught there costs one face and the owl sleeps.)
      for (var rung = 1; rung < collectLadder.length; rung++) {
        final world = buildCollectBoard(rung: rung, random: Random(6));
        final chaser = world.chasers.first;

        // Put the squirrel just ahead of the owl and run straight away.
        world.steerTo(const BoardPoint(1, 1));
        var previous = world.player.distanceTo(chaser.position);

        for (var i = 0; i < 60; i++) {
          world.step(1 / 60);

          final gap = world.player.distanceTo(chaser.position);

          if (world.player.x < 0.99 || world.player.y < 0.99) {
            expect(
              gap,
              greaterThanOrEqualTo(previous - 1e-9),
              reason: 'bölüm ${rung + 1}: koşarken ara kapandı',
            );
          }

          previous = gap;
        }
      }
    });
  });

  group('hedef değişimi', () {
    test('yalnızca son bölümde iki hedef yüz var', () {
      for (var rung = 0; rung < collectLadder.length - 1; rung++) {
        for (final world in _boards(rung)) {
          expect(world.targetFaces, hasLength(1));
        }
      }

      for (final world in _boards(collectLadder.length - 1)) {
        expect(world.targetFaces, hasLength(2));
      }
    });

    test('ilk yüz bitince hedef ikinciye geçer', () {
      final rung = collectLadder.length - 1;
      final world = buildCollectBoard(rung: rung, random: Random(7));

      final firstFace = world.targetFace;
      expect(world.targetFaces.first, firstFace);

      for (final item in [...world.items]) {
        if (item.face != firstFace) continue;
        _walkTo(world, item.position);
      }

      expect(world.targetFace, world.targetFaces.last);
      expect(world.targetFace, isNot(firstFace));
      expect(world.isFinished, isFalse, reason: 'ikinci yüz duruyor');
    });
  });

  group('ekranın okuduğu şeyler', () {
    test('toplanan taş yalnızca o karede bildirilir', () {
      // The screen turns this into a pop; replaying an old one would show a
      // face lifting off an empty patch of board.
      final world = buildCollectBoard(rung: 0, random: Random(1));
      final target = world.items.firstWhere(
        (item) => item.face == world.targetFace,
      );

      expect(world.justCollected, isEmpty);

      world.steerTo(target.position);

      while (!target.isCollected) {
        world.step(1 / 60);
      }

      expect(world.justCollected, contains(target));

      world.step(1 / 60);
      expect(world.justCollected, isEmpty);
    });

    test('hız gidilen yönü gösterir, durunca sıfırlanır', () {
      // The squirrel is mirrored and hops from this; without it the sprite
      // slid backwards across the board.
      final world = buildCollectBoard(rung: 0, random: Random(2));

      expect(world.velocity.magnitude, 0);

      world.steerTo(const BoardPoint(1, 0.5));
      world.step(1 / 60);

      expect(world.velocity.x, greaterThan(0));
      expect(world.velocity.magnitude,
          closeTo(CollectWorld.playerSpeed, 0.001));

      world.steerTo(const BoardPoint(0, 0.5));
      world.step(1 / 60);
      expect(world.velocity.x, lessThan(0));

      // Arrived: nothing left to walk towards.
      world.steerTo(world.player);
      world.step(1 / 60);
      expect(world.velocity.magnitude, 0);
    });
  });

  test('temiz tur payı tahtadaki şey sayısına göre', () {
    // One mistake in five decisions, the same ratio the tap games use — not
    // a flat one, which would punish a long crossing far more.
    for (final rule in collectRules) {
      expect(rule.allowedMistakes, greaterThanOrEqualTo(1));
      expect(
        rule.allowedMistakes,
        (rule.targetCount + rule.distractorCount) ~/ questionsPerRound,
      );
    }

    expect(collectRules.first.allowedMistakes, 1);
    expect(collectRules.last.allowedMistakes, greaterThan(1));
  });

  test('aynı tohum aynı tahtayı üretir', () {
    for (var rung = 0; rung < collectLadder.length; rung++) {
      final a = buildCollectBoard(rung: rung, random: Random(9));
      final b = buildCollectBoard(rung: rung, random: Random(9));

      for (var i = 0; i < a.items.length; i++) {
        expect(a.items[i].face, b.items[i].face);
        expect(a.items[i].position, b.items[i].position);
      }
    }
  });
}
