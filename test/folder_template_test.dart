import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/core/folder_template.dart';
import 'package:tufapp/core/level_manager.dart';
import 'package:tufapp/core/models/difficulty.dart';
import 'package:tufapp/core/models/level.dart';

void main() {
  const level = Level(
    id: 1,
    song: 'multi_arm',
    artist: 'Frums',
    credits: [
      LevelCredit(role: 'charter', creatorName: 'Zagon'),
      LevelCredit(role: 'charter', creatorName: 'Nephrolepis', sortOrder: 1),
      LevelCredit(role: 'vfxer', creatorName: 'Asansis', sortOrder: 2),
    ],
    difficulty: Difficulty(id: 0, name: 'GQ0 (G1~G4)'),
    bpm: 182.5,
    tilecount: 1234,
  );
  String format(String template, [Level value = level]) => LevelFolderTemplate.format(template, value);

  group('레벨 폴더 이름 형식', () {
    test('기본값은 예전과 같은 "#{id} {제목}"', () {
      expect(format(LevelFolderTemplate.defaultTemplate), '#1 multi_arm');
      expect(format('   '), '#1 multi_arm', reason: '비어 있으면 기본값');
    });

    test('태그를 값으로 바꾸고, 대소문자는 가리지 않는다', () {
      expect(format('{Artist} - {song} [{ID}]'), 'Frums - multi_arm [1]');
      expect(format('{charter} | {vfxer}'), 'Zagon & Nephrolepis｜Asansis', reason: '| 는 폴더 이름에 못 써서 전각 ｜, 양옆 띄어쓰기 없이');
      expect(format('{creator}'), 'Zagon & 1 more｜Asansis', reason: '사이트에 보이는 제작자');
      expect(format('{difficulty} {bpm} {tiles}'), 'GQ0 182.5 1234');
    });

    test('{team}은 팀이 없으면 제작자를 쓴다', () {
      expect(format('{team}'), 'Zagon & 1 more｜Asansis', reason: '팀이 없는 레벨');
      const teamLevel = Level(id: 9, song: 'Song', artist: 'Artist', team: 'Team A', creator: 'someone');
      expect(format('{team} - {song}', teamLevel), 'Team A - Song');
      expect(format('{team} - {song}', const Level(id: 9, song: 'Song', artist: '', creator: 'A | B')), 'A｜B - Song');
    });

    test('| 는 _ 가 아니라 생김새가 같은 전각 ｜ 로, 다른 못 쓰는 글자는 _ 로', () {
      expect(format('{song}', const Level(id: 1, song: 'X:||', artist: '')), 'X_｜｜');
      expect(format('{song} | {id}'), 'multi_arm｜1', reason: '형식에 직접 쓴 | 도');
    });

    test('/ 는 하위 폴더를 만들고, 값 안의 / 는 폴더를 나누지 않는다', () {
      expect(format('{artist}/{song}'), 'Frums/multi_arm');
      expect(format(r'{artist}\{song}'), 'Frums/multi_arm');
      expect(format('{artist}/{song}', const Level(id: 2, song: 'A/B', artist: 'C:D')), 'C_D/A_B');
      expect(format('//{song}//'), 'multi_arm', reason: '빈 폴더 이름은 버린다');
    });

    test('빈 값 때문에 남는 괄호와 구분자는 지운다', () {
      const bare = Level(id: 7, song: 'Song', artist: '');
      expect(format('{artist} - {song} [{id}]', bare), 'Song [7]');
      expect(format('{song} - {artist} - {id}', bare), 'Song - 7');
      expect(format('{song} ({team})', bare), 'Song');
      expect(format('{team}/{song}', bare), 'Song', reason: '값이 빈 폴더는 만들지 않는다');
      expect(format('{team}', bare), '#7', reason: '이름이 아예 없으면 ID를 쓴다');
    });

    test('값이 다 있으면 직접 쓴 구분자는 건드리지 않는다', () {
      expect(format('-{song}-'), '-multi_arm-');
    });

    test('값 안의 공백·괄호·구분자는 정리하지 않는다 (기본 형식은 예전 이름과 똑같다)', () {
      for (final song in ['Altered⇄[     ]', '  lead', '[]', 'A - - B', '( )', 'x  y']) {
        final level = Level(id: 15539, song: song, artist: '');
        expect(format(LevelFolderTemplate.defaultTemplate, level), LevelManager.safeFolderName('#15539 $song'));
        expect(format('{artist} - {song}', level), LevelManager.safeFolderName(song), reason: '빈 작곡가만 정리');
      }
    });

    test('없는 태그는 적은 그대로 두고 알려 준다', () {
      expect(LevelFolderTemplate.unknownTags('{sogn} - {artist} {}'), ['{sogn}', '{}']);
      expect(format('{sogn} {id}'), '{sogn} 1');
    });

    test('너무 길면 긴 글 값부터 줄여서 ID는 남긴다', () {
      final long = Level(id: 11372, song: 'S' * 120, artist: 'A' * 30);
      final name = format('{artist} - {song} [{id}]', long);
      expect(name.length, lessThanOrEqualTo(80));
      expect(name, endsWith(' [11372]'));
      expect(name, startsWith('${'A' * 30} - '));
    });

    test('줄일 때 이모지를 반으로 자르지 않는다', () {
      final name = format('{song} {id}', Level(id: 1, song: '${'a' * 76}😀😀😀', artist: ''));
      expect(name.length, lessThanOrEqualTo(80));
      expect(name.runes.every((rune) => rune < 0xD800 || rune > 0xDFFF), isTrue, reason: '짝 잃은 서로게이트가 없다');
    });
  });

  group('제작자 전체 이름', () {
    test('줄이지 않고 채보·이펙트 구분 없이 모두 & 로 잇는다', () {
      expect(level.creatorFull, 'Zagon & Nephrolepis & Asansis');
      const both = Level(
        id: 1,
        song: '',
        artist: '',
        credits: [
          LevelCredit(role: 'charter', creatorName: 'V0W4N'),
          LevelCredit(role: 'vfxer', creatorName: 'V0W4N', sortOrder: 1),
        ],
      );
      expect(both.creatorFull, 'V0W4N', reason: '채보와 이펙트를 같이 한 사람은 한 번만');
      expect(level.creatorDisplay, 'Zagon & 1 more | Asansis', reason: '사이트 표시는 그대로');
    });

    test('팀이 먼저, 크레딧이 없으면 검색 결과의 제작자', () {
      expect(const Level(id: 1, song: '', artist: '', team: 'Team', credits: []).creatorFull, 'Team');
      expect(const Level(id: 1, song: '', artist: '', creator: 'A | B').creatorFull, 'A & B');
      expect(const Level(id: 1, song: '', artist: '', creator: 'V0W4N | V0W4N').creatorFull, 'V0W4N');
    });
  });
}
