// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get languageName => '한국어';

  @override
  String get monthNames => '1월|2월|3월|4월|5월|6월|7월|8월|9월|10월|11월|12월';

  @override
  String longDate(Object year, Object month, Object monthName, Object day) {
    return '$year년 $month월 $day일';
  }

  @override
  String monthDay(Object month, Object monthName, Object day) {
    return '$month월 $day일';
  }

  @override
  String shortMonth(Object year, Object month, Object monthName) {
    return '$year년 $month월';
  }

  @override
  String zoomPercent(Object percent) {
    return '화면 배율 $percent%';
  }

  @override
  String couldNotSaveSettings(Object error) {
    return '설정을 저장하지 못했습니다: $error';
  }

  @override
  String get ready => '준비됐습니다.';

  @override
  String get loading => '불러오는 중...';

  @override
  String couldNotStart(Object message) {
    return '시작하지 못했습니다: $message';
  }

  @override
  String couldNotOpenLink(Object url) {
    return '링크를 열 수 없습니다: $url';
  }

  @override
  String get preparing => '준비 중';

  @override
  String get extracting => '압축 해제';

  @override
  String get done => '완료';

  @override
  String get cancelling => '취소 중';

  @override
  String downloadedSong(Object song) {
    return '받기 완료: $song';
  }

  @override
  String downloadCancelled(Object song) {
    return '받기를 취소했습니다: $song';
  }

  @override
  String tryThisLinkInstead(Object error, Object link) {
    return '$error 대신 이 링크를 확인하세요: $link';
  }

  @override
  String downloadFailed(Object song, Object error) {
    return '받지 못했습니다 ($song): $error';
  }

  @override
  String searchFailed(Object error) {
    return '검색하지 못했습니다: $error';
  }

  @override
  String get sortByName => '이름순';

  @override
  String get sortBySize => '크기순';

  @override
  String get sortByRecent => '최근 받은 순';

  @override
  String get root => '루트';

  @override
  String replacedPlusInFolders(int count) {
    return '폴더 이름의 \'+\'를 \'_\'로 바꿨습니다 ($count개). 게임이 \'+\'가 든 경로를 불러오지 못해서예요.';
  }

  @override
  String couldNotReadFolder(Object error) {
    return '폴더를 읽지 못했습니다: $error';
  }

  @override
  String createdFolder(Object name) {
    return '폴더를 만들었습니다: $name';
  }

  @override
  String get cantDoThisWhile =>
      '받는 중인 레벨이 있어서 지금은 할 수 없습니다. 받기가 끝난 뒤 다시 해 주세요.';

  @override
  String skippedStillDownloading(Object skipped) {
    return ' (받는 중이라 $skipped개는 건너뛰었습니다)';
  }

  @override
  String renamedTo(Object name) {
    return '이름을 바꿨습니다: $name';
  }

  @override
  String movedItems(int count, Object where, Object skipped) {
    return '$count개를 $where(으)로 옮겼습니다.$skipped';
  }

  @override
  String movedButCouldNot(
    Object count,
    Object failed,
    Object error,
    Object skipped,
  ) {
    return '$count개를 옮기고 $failed개는 옮기지 못했습니다 ($error)$skipped';
  }

  @override
  String deletedItems(int count, Object skipped) {
    return '$count개를 지웠습니다.$skipped';
  }

  @override
  String movedEntry(Object name, Object where) {
    return '옮겼습니다: $name → $where';
  }

  @override
  String deletedEntry(Object name) {
    return '지웠습니다: $name';
  }

  @override
  String deletedWithLevels(int count, Object name) {
    return '레벨 $count개와 함께 지웠습니다: $name';
  }

  @override
  String folderOperationFailed(Object error) {
    return '폴더를 다루지 못했습니다: $error';
  }

  @override
  String get checkingForUpdates => '업데이트를 확인하는 중...';

  @override
  String removedMissingLevels(int count) {
    return ' 폴더가 사라진 레벨 $count개는 목록에서 뺐습니다.';
  }

  @override
  String get everythingIsUpTo => '모두 최신 버전입니다.';

  @override
  String updatesAvailable(int count) {
    return '업데이트할 레벨이 $count개 있습니다.';
  }

  @override
  String couldNotCheckForUpdates(Object error) {
    return '업데이트를 확인하지 못했습니다: $error';
  }

  @override
  String deletedLevel(Object song) {
    return '삭제했습니다: $song';
  }

  @override
  String couldNotDelete(Object error) {
    return '삭제하지 못했습니다: $error';
  }

  @override
  String get cantChangeTheFolder => '받는 중인 레벨이 있어서 폴더를 바꿀 수 없습니다.';

  @override
  String get useThisFolder => '이 폴더 사용';

  @override
  String libraryFolderChanged(Object path) {
    return '라이브러리 폴더를 바꿨습니다: $path';
  }

  @override
  String couldNotOpenFolder(Object error) {
    return '폴더를 열 수 없습니다: $error';
  }

  @override
  String failedSuffix(Object failed) {
    return ', 실패 $failed개';
  }

  @override
  String stoppedDownloadingPack(
    Object name,
    Object done,
    Object total,
    Object failed,
  ) {
    return '\'$name\' 받기를 멈췄습니다 ($done/$total개 받음$failed)';
  }

  @override
  String downloadedPack(Object name, int done, Object failed) {
    return '\'$name\' 받기 완료: $done개$failed';
  }

  @override
  String theDownloadStalledFor(Object seconds) {
    return '다운로드가 $seconds초 동안 멈춰서 중단했습니다.';
  }

  @override
  String theDownloadWasInterrupted(Object error) {
    return '다운로드가 중간에 끊겼습니다: $error';
  }

  @override
  String theDownloadWasInterruptedBytes(Object received, Object count) {
    return '다운로드가 중간에 끊겼습니다. ($received/$count bytes)';
  }

  @override
  String couldntReadTheDownloaded(Object fileName) {
    return '받은 레벨 목록 파일을 읽을 수 없어서 새로 시작합니다. 원래 파일은 $fileName(으)로 남겨 뒀습니다.';
  }

  @override
  String removedUnreadableEntries(int skipped) {
    return '받은 레벨 목록에서 읽을 수 없는 항목 $skipped개를 뺐습니다.';
  }

  @override
  String get invalidLevelFolderName => '레벨 폴더 이름이 올바르지 않습니다';

  @override
  String zipInvalidPath(Object name) {
    return 'zip에 잘못된 경로가 있습니다: $name';
  }

  @override
  String levelHasNoTUF(Object id) {
    return '레벨 $id은(는) TUF CDN 다운로드 링크가 없습니다.';
  }

  @override
  String get cantWorkOutsideThe => '라이브러리 폴더 밖은 다룰 수 없습니다.';

  @override
  String aFolderNamedAlready(Object name) {
    return '\"$name\" 폴더가 이미 있습니다.';
  }

  @override
  String alreadyExists(Object name) {
    return '\"$name\"이(가) 이미 있습니다.';
  }

  @override
  String get cantMoveAFolder => '폴더를 자기 자신 안으로 옮길 수 없습니다.';

  @override
  String alreadyExistsThere(Object name) {
    return '\"$name\"이(가) 옮길 곳에 이미 있습니다.';
  }

  @override
  String get folderNotFound => '폴더를 찾을 수 없습니다.';

  @override
  String get pleaseEnterAName => '이름을 입력해 주세요.';

  @override
  String get namesCannotContain => '이름에 < > : \" / \\ | ? * 는 쓸 수 없습니다.';

  @override
  String get scores => '점수';

  @override
  String get passCounts => '클리어 수';

  @override
  String get totalPasses => '총 클리어 횟수';

  @override
  String get uniqueLevelsCleared => '클리어한 레벨';

  @override
  String get worldsFirstClears => '세계 최초 클리어';

  @override
  String get worldsFirstPPClears => '세계 최초 완플 클리어';

  @override
  String get clears12k => '12키 클리어';

  @override
  String get clears16k => '16키 클리어';

  @override
  String get totalPurePerfects => '완벽한 클리어 합계';

  @override
  String get reclears => '중복 클리어';

  @override
  String get judgements => '판정';

  @override
  String get totalTilesHit => '총 누른 타일';

  @override
  String get generalAccuracy => '평균 정확도';

  @override
  String get earlyVsLateBias => '빠름/느림 쏠림';

  @override
  String get levelsCleared => '클리어한 레벨';

  @override
  String get totalTilecountCleared => '클리어한 총 타일 수';

  @override
  String get estimatedPlaytime => '예상 플레이 시간';

  @override
  String get avgBPMClearedLevels => '평균 BPM (클리어한 레벨)';

  @override
  String get rawSumOfAll => '총 점수 (중복 포함)';

  @override
  String get records => '기록';

  @override
  String get firstPass => '첫 클리어';

  @override
  String get latestPass => '최근 클리어';

  @override
  String get bestAccuracy => '최고 정확도';

  @override
  String get worstAccuracy => '최저 정확도';

  @override
  String get topSpeed => '최고 속도';

  @override
  String get highestTilecount => '최고 타일 수';

  @override
  String get longestLevel => '최장 길이';

  @override
  String get highestBPMCleared => '클리어한 최고 BPM';

  @override
  String get activity => '활동';

  @override
  String get accountAgeDays => '가입 일수';

  @override
  String get passesLast30Days => '최근 30일 클리어 수';

  @override
  String get levelsLiked => '좋아요 표시한 레벨 수';

  @override
  String get packsOwned => '제작한 팩 수';

  @override
  String get packsFavorited => '좋아요 표시한 팩 수';

  @override
  String get clearsByDifficultyType => '클리어한 난이도 수';

  @override
  String uniqueLevelsClearedTotal(Object unique, Object total) {
    return '고유 레벨 $unique개 클리어 (총 $total회)';
  }

  @override
  String uniqueLevelsClearedCount(Object unique) {
    return '클리어한 고유 레벨 $unique개';
  }

  @override
  String get identity => '기본 정보';

  @override
  String get aliases => '별칭';

  @override
  String get teamsJoined => '팀 참여';

  @override
  String get credits => '참여';

  @override
  String get levelsAsCharter => '채보 참여 레벨';

  @override
  String get levelsAsVFX => '이펙트 참여 레벨';

  @override
  String get chartContent => '레벨 내용';

  @override
  String get tilesPlaced => '총 타일 수';

  @override
  String get totalChartDuration => '총 채보 길이';

  @override
  String get avgTilecount => '평균 타일 수';

  @override
  String get avgLevelLength => '평균 채보 길이';

  @override
  String get avgBPM => '평균 BPM';

  @override
  String get totalClearsOnCharts => '모든 레벨 클리어 수';

  @override
  String get totalLikesOnCharts => '모든 레벨 좋아요 수';

  @override
  String get totalDownloadsOnCharts => '모든 레벨 다운로드 수';

  @override
  String get audience => '플레이어';

  @override
  String get uniquePlayersWhoCleared => '클리어한 플레이어 수';

  @override
  String get wfsOnCharts => '레벨의 세계 최초 클리어';

  @override
  String get wfPpsOnCharts => '레벨의 세계 최초 완플';

  @override
  String get totalTilesHitOnCharts => '플레이어가 누른 타일';

  @override
  String get timeline => '타임라인';

  @override
  String get firstChart => '첫 제작';

  @override
  String get latestChart => '최근 제작';

  @override
  String get levelsByDifficultyType => '난이도별 레벨';

  @override
  String get special => '특수';

  @override
  String topClear(Object letter, Object number, Object count) {
    return '최고 $letter 클리어: $letter$number ($count회)';
  }

  @override
  String letterNoClears(Object letter) {
    return '$letter: 클리어 없음';
  }

  @override
  String qFromWorldsFirst(Object letter, Object tier, Object count) {
    return '세계 최초 $letter 클리어로 얻은 ${letter}Q$tier ($count회)';
  }

  @override
  String qNoWorldsFirst(Object letter) {
    return '${letter}Q: 해당 범위의 세계 최초 클리어 없음';
  }

  @override
  String typeLevelCount(Object type, int count) {
    return '$type · 레벨 $count개';
  }

  @override
  String get unexpectedSearchResponse => '검색 응답 형식이 올바르지 않습니다.';

  @override
  String noLevelField(Object id) {
    return '레벨 $id의 응답에 level 필드가 없습니다.';
  }

  @override
  String get unexpectedDifficultyListResponse => '난이도 목록 응답 형식이 올바르지 않습니다.';

  @override
  String get listTag => '태그';

  @override
  String get listCurationType => '큐레이션 유형';

  @override
  String unexpectedListResponse(Object label) {
    return '$label 목록 응답 형식이 올바르지 않습니다.';
  }

  @override
  String unexpectedPassResponseFor(Object levelId) {
    return '레벨 $levelId의 기록 응답 형식이 올바르지 않습니다.';
  }

  @override
  String unexpectedResponseForPass(Object id) {
    return '기록 $id의 응답 형식이 올바르지 않습니다.';
  }

  @override
  String unexpectedResponseForPlayer(Object id) {
    return '플레이어 $id의 응답 형식이 올바르지 않습니다.';
  }

  @override
  String get unexpectedPassListResponse => '클리어 목록 응답 형식이 올바르지 않습니다.';

  @override
  String get unexpectedLeaderboardResponse => '리더보드 응답 형식이 올바르지 않습니다.';

  @override
  String get unexpectedCreatorListResponse => '제작자 목록 응답 형식이 올바르지 않습니다.';

  @override
  String playerNotFound(Object id) {
    return '플레이어 $id을(를) 찾을 수 없습니다.';
  }

  @override
  String unexpectedPassResponseForPlayer(Object id) {
    return '플레이어 $id의 기록 응답 형식이 올바르지 않습니다.';
  }

  @override
  String unexpectedRankHistoryResponse(Object id) {
    return '플레이어 $id의 순위 기록 응답 형식이 올바르지 않습니다.';
  }

  @override
  String creatorNotFound(Object id) {
    return '제작자 $id을(를) 찾을 수 없습니다.';
  }

  @override
  String get unexpectedPackListResponse => '팩 목록 응답 형식이 올바르지 않습니다.';

  @override
  String unexpectedResponseForPack(Object id) {
    return '팩 $id의 응답 형식이 올바르지 않습니다.';
  }

  @override
  String serverNotResponding(Object url) {
    return '서버가 응답하지 않습니다: $url';
  }

  @override
  String downloadRequestFailed(Object url, Object error) {
    return '다운로드 요청 실패: $url ($error)';
  }

  @override
  String requestFailed(Object path, Object error) {
    return '요청 실패: $path ($error)';
  }

  @override
  String couldNotReadTheResponse(Object path) {
    return '응답을 읽을 수 없습니다: $path';
  }

  @override
  String get unknown => '알 수 없음';

  @override
  String keyCount(Object count) {
    return '$count키';
  }

  @override
  String get keys16 => '16키';

  @override
  String get keys12 => '12키';

  @override
  String get theServersDifficultyList => '서버 난이도 목록에 PGU 난이도가 없습니다.';

  @override
  String get levels => '레벨 찾기';

  @override
  String get packs => '레벨 팩';

  @override
  String get passes => '클리어';

  @override
  String get leaderboard => '리더보드';

  @override
  String get creators => '제작자';

  @override
  String get library => '레벨 관리';

  @override
  String get downloading => '받는 중';

  @override
  String get language => '언어';

  @override
  String systemLanguage(Object language) {
    return '시스템 언어 ($language)';
  }

  @override
  String get couldntLoadTheList => '목록을 불러오지 못했어요';

  @override
  String get retry => '다시 시도';

  @override
  String get tryDifferentFilters => '다른 조건으로 찾아보세요.';

  @override
  String get clearSearch => '검색어 지우기';

  @override
  String get descending => '내림차순';

  @override
  String get ascending => '오름차순';

  @override
  String get browsePassesFromEvery => '모든 플레이어의 클리어 기록을 둘러보세요.';

  @override
  String passCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '클리어 $countString개';
  }

  @override
  String get noPassesFound => '찾는 클리어 기록이 없어요';

  @override
  String get allPassesLoaded => '모든 클리어 기록을 불러왔어요';

  @override
  String get searchBySongOr => '곡 이름, 플레이어로 검색 (#번호로 기록 찾기)';

  @override
  String get sort => '정렬';

  @override
  String get filter => '필터';

  @override
  String get difficulty => '난이도';

  @override
  String get dragTheSliderTo => '슬라이더를 끌어서 범위를 정하세요.';

  @override
  String get includeSpecialDifficulties => '특수 난이도도 보기';

  @override
  String get keyCountFilter => '키 수';

  @override
  String get worldsFirst => '세계 최초';

  @override
  String get gameVersion => '게임 버전';

  @override
  String get resetAll => '모두 초기화';

  @override
  String get hiddenLevel => '숨겨진 레벨';

  @override
  String get viewPlayerProfile => '플레이어 프로필 보기';

  @override
  String get findThePeopleWho => '레벨을 만든 사람들을 레벨 수, 클리어 수, 큐레이션으로 찾아보세요.';

  @override
  String creatorCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '제작자 $countString명';
  }

  @override
  String get noCreatorsFound => '찾는 제작자가 없어요';

  @override
  String get allCreatorsLoaded => '모든 제작자를 불러왔어요';

  @override
  String get searchByCreatorName => '제작자 이름으로 검색 (@계정으로도)';

  @override
  String get other => '기타';

  @override
  String get verificationStatus => '인증 상태';

  @override
  String get allStatuses => '모든 상태';

  @override
  String get curationTypes => '큐레이션 유형';

  @override
  String get onlyShowsCreatorsWith => '고른 유형의 레벨이 있는 제작자만 보여줍니다.';

  @override
  String get matchAny => '하나라도';

  @override
  String get matchAll => '모두';

  @override
  String get noLinkedAccount => '연동된 계정 없음';

  @override
  String get seePlayerRankingsBy => '플레이어 순위를 점수, 클리어 수, 최고 난이도 등으로 보세요.';

  @override
  String playerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '플레이어 $countString명';
  }

  @override
  String get noPlayersFound => '찾는 플레이어가 없어요';

  @override
  String get allPlayersLoaded => '모든 플레이어를 불러왔어요';

  @override
  String get searchByPlayerName => '플레이어 이름으로 검색';

  @override
  String get refresh => '새로고침';

  @override
  String topDifficulty(Object difficulty) {
    return '최고 난이도 $difficulty';
  }

  @override
  String get loadingDifficulties => '난이도 정보를 불러오는 중...';

  @override
  String get couldntConnectToThe => '서버에 연결하지 못했습니다';

  @override
  String get findLevelsOnTUF => 'TUF에 등록된 레벨을 찾아서 바로 받아보세요.';

  @override
  String get searchBySongArtist => '곡 이름, 작곡가, 제작자로 검색';

  @override
  String get includeQDifficulties => 'Q 난이도 포함';

  @override
  String get noCurationTypes => '큐레이션 유형 없음';

  @override
  String get findByTheGrades => '큐레이터가 매긴 등급으로 찾습니다.';

  @override
  String get tags => '태그';

  @override
  String get noTags => '태그 없음';

  @override
  String get findByTheTags => '레벨에 붙은 태그로 찾습니다.';

  @override
  String get clearedLevels => '클리어한 레벨';

  @override
  String get downloadable => '다운로드 가능';

  @override
  String get filterAll => '전체';

  @override
  String get filterHide => '숨기기';

  @override
  String get filterOnly => '만 보기';

  @override
  String get clearSelection => '선택 해제';

  @override
  String get includeAll => '모두 포함';

  @override
  String get specialDifficulties => '특수 난이도';

  @override
  String get selectedDifficultiesAreShown => '선택한 난이도를 결과에 함께 보여줍니다.';

  @override
  String get selectAll => '전체 선택';

  @override
  String get deselectAll => '전체 선택 해제';

  @override
  String levelCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '레벨 $countString개';
  }

  @override
  String get detailedView => '자세히 보기';

  @override
  String get compactView => '간략히 보기';

  @override
  String get noLevelsMatch => '조건에 맞는 레벨이 없어요';

  @override
  String get tryADifferentSearch => '검색어나 필터를 바꿔 보세요.';

  @override
  String get allLevelsLoaded => '모든 레벨을 불러왔어요';

  @override
  String get back => '뒤로';

  @override
  String uniquePlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString명';
  }

  @override
  String totalClearsSuffix(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return ' (총 $countString회)';
  }

  @override
  String get couldntLoadPasses => '기록을 불러오지 못했어요';

  @override
  String get noPassesYet => '아직 클리어 기록이 없어요';

  @override
  String get firstClear => '최초 클리어';

  @override
  String get highestScore => '최고 점수';

  @override
  String get highestSpeed => '최고 속도';

  @override
  String get highestAccuracy => '최고 정확도';

  @override
  String get totalClears => '총 클리어 수';

  @override
  String get fullInfo => '전체 정보';

  @override
  String feeling(Object feeling) {
    return '체감 $feeling';
  }

  @override
  String itemCount(int count) {
    return '$count개 항목';
  }

  @override
  String get empty => '비어 있음';

  @override
  String folderCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '폴더 $countString개';
  }

  @override
  String get addedManuallyNotIn => '직접 넣은 레벨 (앱 목록에는 없어요)';

  @override
  String get updateAvailable => '업데이트 있음';

  @override
  String sizeAndDownloadDate(Object size, Object date) {
    return '$size  ·  $date에 받음';
  }

  @override
  String get update => '업데이트';

  @override
  String get more => '더 보기';

  @override
  String get organizeYourDownloadedLevels =>
      '받아 둔 레벨을 폴더로 정리하고 업데이트를 확인할 수 있어요.';

  @override
  String levelCountAndSize(int count, Object size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '레벨 $countString개  ·  $size';
  }

  @override
  String get checking => '확인 중...';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String updateAll(Object count) {
    return '모두 업데이트 ($count)';
  }

  @override
  String get upBackspace => '위로 (Backspace)';

  @override
  String get newFolder => '새 폴더';

  @override
  String get openInExplorer => '탐색기에서 열기';

  @override
  String get changeLibraryFolder => '라이브러리 폴더 변경';

  @override
  String get refreshLibrary => '새로 고침';

  @override
  String selected(Object count) {
    return '$count개 선택됨';
  }

  @override
  String get move => '이동';

  @override
  String get delete => '삭제';

  @override
  String get deselect => '선택 해제';

  @override
  String get open => '열기';

  @override
  String get rename => '이름 변경';

  @override
  String get moveToFolder => '폴더로 이동';

  @override
  String get selectAllItems => '모두 선택';

  @override
  String get folderName => '폴더 이름';

  @override
  String get create => '만들기';

  @override
  String get newName => '새 이름';

  @override
  String get renameConfirm => '바꾸기';

  @override
  String deleteNamed(Object name) {
    return '\"$name\"을(를) 삭제할까요?';
  }

  @override
  String deleteItems(int count) {
    return '$count개를 삭제할까요?';
  }

  @override
  String thisDeletesItFrom(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '폴더 안의 레벨 $countString개를 포함해 디스크에서 지워집니다.';
  }

  @override
  String get thisDeletesItFromDisk => '디스크에서 지워집니다.';

  @override
  String get cancel => '취소';

  @override
  String moveNamed(Object name) {
    return '\"$name\" 옮기기';
  }

  @override
  String moveItems(int count) {
    return '$count개 옮기기';
  }

  @override
  String get noSubfolders => '하위 폴더가 없어요.';

  @override
  String get moveToRoot => '루트로 옮기기';

  @override
  String get moveHere => '여기로 옮기기';

  @override
  String get noDownloadedLevelsYet => '아직 받은 레벨이 없어요';

  @override
  String get thisFolderIsEmpty => '빈 폴더예요';

  @override
  String get findLevelsYouLike => '레벨 찾기에서 마음에 드는 레벨을 받아보세요.';

  @override
  String get dragLevelsHereOr => '레벨을 끌어다 놓거나, 안에 폴더를 더 만들 수 있어요.';

  @override
  String get browseLevels => '레벨 둘러보기';

  @override
  String get levelPacks => '레벨 팩';

  @override
  String get browseLevelPacksMade =>
      '커뮤니티에서 만든 레벨 팩을 둘러보고, 폴더 구조 그대로 한 번에 받아보세요.';

  @override
  String get searchByPackName => '팩 이름으로 검색';

  @override
  String packCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '팩 $countString개';
  }

  @override
  String get couldntLoadPacks => '팩을 불러오지 못했어요';

  @override
  String get noPacksFound => '찾는 팩이 없어요';

  @override
  String get trySearchingForA => '다른 이름으로 검색해 보세요.';

  @override
  String get allPacksLoaded => '모든 팩을 불러왔어요';

  @override
  String moreCount(Object more) {
    return '+$more개 더';
  }

  @override
  String get pinnedPack => '고정된 팩';

  @override
  String likeCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '좋아요 $countString개';
  }

  @override
  String get allPacks => '팩 목록';

  @override
  String get downloadPack => '팩 받기';

  @override
  String downloadPackCount(Object count) {
    return '팩 받기 ($count개)';
  }

  @override
  String get items => '항목';

  @override
  String get collapseAll => '모두 접기';

  @override
  String get expandAll => '모두 펼치기';

  @override
  String itemAndLevelCount(int items, int levelCount) {
    return '$items개 항목 · 레벨 $levelCount개';
  }

  @override
  String downloadFolderCount(Object count) {
    return '폴더 받기 ($count개)';
  }

  @override
  String get emptyFolder => '빈 폴더';

  @override
  String get allDownloaded => '모두 받음';

  @override
  String downloadNamed(Object label) {
    return '\'$label\' 받기';
  }

  @override
  String downloadPackExplanation(int count, Object folder) {
    return '아직 받지 않은 레벨 $count개를 차례로 받습니다.\n레벨 관리의 \'$folder\' 폴더 안에 팩과 같은 폴더 구조로 저장돼요.\n이미 받은 레벨은 건너뛰고 원래 자리에 그대로 둡니다.';
  }

  @override
  String get download => '받기';

  @override
  String failedCountSuffix(Object failedCount) {
    return ' · 실패 $failedCount';
  }

  @override
  String get waiting => '대기 중';

  @override
  String get stopping => '멈추는 중';

  @override
  String get stop => '멈추기';

  @override
  String get couldntLoadThePack => '팩 내용을 불러오지 못했어요';

  @override
  String get thisPackIsEmpty => '비어 있는 팩이에요';

  @override
  String playersPass(Object player) {
    return '$player의 클리어';
  }

  @override
  String get loadingScore => '점수 불러오는 중...';

  @override
  String get couldntLoadTheScore => '점수를 불러오지 못했어요';

  @override
  String get topDifficultyCleared => '가장 높이 깬 난이도';

  @override
  String worldsFirstClearCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '세계 최초 클리어 $countString개';
  }

  @override
  String get rankedScoreWithoutThis => '이 기록이 없었을 때의 랭킹 점수';

  @override
  String clearedOn(Object date) {
    return '$date 클리어';
  }

  @override
  String get overallRank => '전체 랭킹 순위';

  @override
  String get score => '점수';

  @override
  String get accuracy => '정확도';

  @override
  String get speed => '속도';

  @override
  String get feelingRating => '체감 난이도';

  @override
  String get expectedRating => '예상 난이도';

  @override
  String get watchVideoInBrowser => '브라우저에서 영상 보기';

  @override
  String get leavingTUF => 'TUF를 떠나시겠습니까?';

  @override
  String get youAreAboutTo => '외부 사이트로 이동합니다. 신뢰할 수 있는 주소인지 확인하세요.';

  @override
  String trustForThisSession(Object host) {
    return '이 세션 동안 $host 신뢰';
  }

  @override
  String get proceed => '계속';

  @override
  String get openVideo => '영상 열기';

  @override
  String get loadingPasses => '클리어 불러오는 중…';

  @override
  String get loadingLevels => '레벨 불러오는 중…';

  @override
  String get tilesUnit => '타일';

  @override
  String get creator => '제작자';

  @override
  String get noLevels => '레벨이 없어요';

  @override
  String get totalLevels => '모든 레벨';

  @override
  String get curatedLevels => '큐레이션 레벨';

  @override
  String get totalLevelClears => '레벨 클리어 수';

  @override
  String get bio => '소개';

  @override
  String get levelsByDifficulty => '난이도별 레벨';

  @override
  String get noPasses => '기록이 없어요';

  @override
  String get difficultiesCleared => '깬 난이도';

  @override
  String get rankedScore => '랭크 점수';

  @override
  String get averageXAcc => '평균 절대정확도';

  @override
  String get totalScore => '총 점수';

  @override
  String get viewUsersPacks => '사용자 팩 보기';

  @override
  String get viewCreatorProfile => '제작자 프로필 보기';

  @override
  String get playerBio => '내 소개';

  @override
  String get clearsByDifficulty => '난이도별 클리어';

  @override
  String clearCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString회 클리어';
  }

  @override
  String get today => '오늘';

  @override
  String get oneDayAgo => '1일 전';

  @override
  String daysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String get rank => '순위';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '팔로워 $countString명';
  }

  @override
  String alsoKnownAs(Object aliases) {
    return '다른 이름: $aliases';
  }

  @override
  String get showAll => '모두 보기';

  @override
  String get allStats => '전체 통계';

  @override
  String get rankedScoreRank => '랭크 점수 순위';

  @override
  String get atHighestRankRight => '지금 최고 순위입니다!';

  @override
  String highestRank(Object rank, Object date) {
    return '최고 순위 #$rank ($date)';
  }

  @override
  String get unranked => '순위 없음';

  @override
  String get close => '닫기';

  @override
  String titleStats(Object title) {
    return '$title의 통계';
  }

  @override
  String get viewPass => '클리어 보기';

  @override
  String difficultyClearCount(Object difficulty, int count) {
    return '$difficulty · $count회 클리어';
  }

  @override
  String get levelUploadPermission => '레벨 등록 허가 상태';

  @override
  String uploadConditions(Object text) {
    return '등록 조건: $text';
  }

  @override
  String playerPassCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString개 클리어';
  }

  @override
  String get searchBySongOrArtist => '곡 이름, 작곡가로 검색';

  @override
  String get hideReclears => '재클리어 숨기기';

  @override
  String get levelsSection => '레벨';

  @override
  String creatorLevelCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString개';
  }

  @override
  String get searchThisCreatorsLevels => '이 제작자의 레벨 검색';

  @override
  String get tournaments => '토너먼트';

  @override
  String get openPack => '팩 열기';

  @override
  String placementCount(int count) {
    return '$count개 입상';
  }

  @override
  String get otherTournaments => '기타 토너먼트';

  @override
  String get scoreBreakdown => '점수 상세';

  @override
  String get includeDuplicates => '중복 포함';

  @override
  String get couldntLoadRankHistory => '순위 기록을 불러오지 못했어요';

  @override
  String get noRankHistoryStored => '저장된 순위 기록이 없어요';

  @override
  String get rankOverTime => '순위 변화';

  @override
  String get rankedScoreLine => '랭크 점수';

  @override
  String get generalScore => '일반 점수';

  @override
  String get passesAboveCountToward => '여기까지 랭크 점수에 들어가요';

  @override
  String scoreOrMore(Object score) {
    return '$score 이상';
  }

  @override
  String get favorites => '즐겨찾기';

  @override
  String get pack => '팩';

  @override
  String rankedScoreValue(Object score) {
    return '랭크 점수 $score';
  }

  @override
  String chartLevelCount(int count) {
    return '레벨 $count개';
  }

  @override
  String get couldntOpenTheLevel => '레벨을 열지 못했습니다';

  @override
  String get couldntOpenThePass => '클리어를 열지 못했습니다';

  @override
  String get theLevelOfThis => '기록의 레벨을 알 수 없습니다.';

  @override
  String get couldntOpenThePack => '팩을 열지 못했습니다.';

  @override
  String get notFound => '찾을 수 없어요';

  @override
  String get nothingHere => '아무것도 없어요';

  @override
  String get couldntOpenThePage => '페이지를 열지 못했어요';

  @override
  String get collapse => '접기';

  @override
  String get expand => '펼치기';

  @override
  String get couldntLoadMore => '더 불러오지 못했어요';

  @override
  String expectedDifficulty(Object difficulty) {
    return '예상 난이도: $difficulty';
  }

  @override
  String curation(Object curation) {
    return '큐레이션: $curation';
  }

  @override
  String baseScoreOverridePP(int score) {
    final intl.NumberFormat scoreNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String scoreString = scoreNumberFormat.format(score);

    return '기반 점수 변동: $scoreString PP (난이도 기본 점수 대신 적용됩니다)';
  }

  @override
  String get length => '길이';

  @override
  String get tileCount => '타일 수';

  @override
  String get noCreatorInfo => '제작자 정보 없음';

  @override
  String clearedByPlayerTotal(int players, int clears) {
    final intl.NumberFormat playersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String playersString = playersNumberFormat.format(players);
    final intl.NumberFormat clearsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String clearsString = clearsNumberFormat.format(clears);

    return '클리어 $playersString명 (총 $clearsString회)';
  }

  @override
  String get likes => '좋아요';

  @override
  String get watchVideo => '영상 보기';

  @override
  String get steamWorkshop => '스팀 창작마당';

  @override
  String get downloads => '받은 횟수';

  @override
  String get levelFileSize => '레벨 파일 크기';

  @override
  String get downloadToLibrary => '라이브러리에 받기';

  @override
  String get updateToTheNew => '새 버전으로 업데이트';

  @override
  String get alreadyDownloaded => '이미 받은 레벨입니다';

  @override
  String get downloaded => '받음';

  @override
  String get noFileToDownload => 'TUF에서 직접 받을 수 있는 파일이 없습니다';

  @override
  String get noLink => '링크 없음';

  @override
  String addedOn(Object date) {
    return '등록: $date';
  }

  @override
  String get team => '팀';

  @override
  String get baseScore => '기반 점수';

  @override
  String get charters => '채보';

  @override
  String get vfx => '이펙트';

  @override
  String get worldsFirstClearBadge => '세계 최초 클리어!';

  @override
  String get worldsFirstPurePerfect => '세계 최초 PP 클리어!';

  @override
  String get autoSubmitted => '자동 제출';

  @override
  String get submittedStraightFromThe => '게임에서 바로 제출된 기록';

  @override
  String get noHold => '홀드 설정 꺼짐';

  @override
  String get altHoldOption => '기본 외 홀드 타일 동작';

  @override
  String get beforeTheEngineChange =>
      '엔진 변경 이전 버전입니다 (v2.9.8까지).\n타이밍 엔진 문제로 안정성과 정밀도가 낮았습니다.';

  @override
  String get beforeXPerfectUp => 'X-Perfect 이전 버전입니다 (v3.3.1까지).';

  @override
  String get whatThisPassAdds => '이 기록이 랭킹 점수에 보탠 몫';

  @override
  String get doesntCountTowardThe => '랭킹 점수에 들어가지 않는 기록이에요 (보탤 수 있었던 몫)';

  @override
  String get speedMultiplier => '배속';

  @override
  String get clearSortRecent => '최신순';

  @override
  String get clearSortScore => '점수';

  @override
  String get clearSortAccuracy => '정확도';

  @override
  String get clearSortDifficulty => '난이도';

  @override
  String get clearSortSpeed => '속도';

  @override
  String get clearSortKeyCount => '키 수';

  @override
  String get clearSortRandom => '무작위';

  @override
  String get keyCountFilterAll => '전체';

  @override
  String get keyCountFilterK12 => '12키';

  @override
  String get keyCountFilterK16 => '16키';

  @override
  String get worldsFirstFilterNone => '전체';

  @override
  String get worldsFirstFilterWf => 'WF';

  @override
  String get worldsFirstFilterWfpp => 'WF PP';

  @override
  String get worldsFirstFilterEither => '둘 중 하나';

  @override
  String get worldsFirstFilterBoth => '둘 다';

  @override
  String get gameVersionFilterAll => '전체';

  @override
  String get gameVersionFilterLatest => '최신';

  @override
  String get gameVersionFilterPre340 => '<3.4.0';

  @override
  String get gameVersionFilterV2 => 'v2';

  @override
  String get leaderboardSortRankedScore => '랭크 점수';

  @override
  String get leaderboardSortTotalScoreV2 => '총 점수';

  @override
  String get leaderboardSortGeneralScore => '일반 점수';

  @override
  String get leaderboardSortPpScore => '완벽한 플레이 점수';

  @override
  String get leaderboardSortWfScore => '세계 최초 점수';

  @override
  String get leaderboardSortWfPPScore => '세계 최초 완플 점수';

  @override
  String get leaderboardSortScore12K => '12키 점수';

  @override
  String get leaderboardSortAverageXacc => '평균 절대정확도';

  @override
  String get leaderboardSortTotalPasses => '클리어한 레벨';

  @override
  String get leaderboardSortUniversalPassCount => 'U 클리어';

  @override
  String get leaderboardSortWorldsFirstCount => '세계 최초 클리어';

  @override
  String get leaderboardSortWorldsFirstPPCount => '세계 최초 완플 클리어';

  @override
  String get leaderboardSortTopDiff => '최고 난이도';

  @override
  String get leaderboardSortTop12kDiff => '최고 12키 난이도';

  @override
  String get creatorSortChartsTotal => '총 레벨';

  @override
  String get creatorSortChartsCharted => '채보 레벨';

  @override
  String get creatorSortChartsVfxed => '이펙트 레벨';

  @override
  String get creatorSortChartsTeamed => '팀 명의 레벨';

  @override
  String get creatorSortTotalChartClears => '모든 레벨 클리어 수';

  @override
  String get creatorSortTotalChartLikes => '모든 레벨 좋아요 수';

  @override
  String get creatorSortName => '이름';

  @override
  String get packSortRecent => '최신';

  @override
  String get packSortName => '이름';

  @override
  String get packSortLevels => '레벨 수';

  @override
  String get packSortFavorites => '좋아요 수';

  @override
  String get judgementTooEarly => '너무 빠름';

  @override
  String get judgementEarly => '빠름!';

  @override
  String get judgementEarlyPerfect => '빠름';

  @override
  String get judgementPerfectMinus => '정확−';

  @override
  String get judgementPerfect => '정확';

  @override
  String get judgementPerfectPlus => '정확+';

  @override
  String get judgementLatePerfect => '느림';

  @override
  String get judgementLate => '느림!';

  @override
  String get judgementTooLate => '너무 느림';

  @override
  String get playerScoreRankedScore => '랭크 점수';

  @override
  String get playerScoreRankedScoreDescription =>
      '상위 20개 클리어 점수 합산 (순위 낮을수록 감소, 재클리어 제외)';

  @override
  String get playerScoreTotalScoreV2 => '총 점수';

  @override
  String get playerScoreTotalScoreV2Description => '모든 클리어 점수 합산 (재클리어 제외)';

  @override
  String get playerScoreGeneralScore => '일반 점수';

  @override
  String get playerScoreGeneralScoreDescription => '모든 클리어 점수 합산 (재클리어 포함)';

  @override
  String get playerScorePpScore => '완벽한 플레이 점수';

  @override
  String get playerScorePpScoreDescription => '랭크 점수와 같지만, 모든 클리어가 완벽한 플레이';

  @override
  String get playerScoreWfScore => '세계 최초 점수';

  @override
  String get playerScoreWfScoreDescription => '세계 최초 클리어한 레벨 기본 점수 합산';

  @override
  String get playerScoreWfPPScore => '세계 최초 완플 점수';

  @override
  String get playerScoreWfPPScoreDescription =>
      '세계 최초 완벽한 플레이 클리어한 레벨 기본 점수 합산';

  @override
  String get playerScoreScore12K => '12키 점수';

  @override
  String get playerScoreScore12KDescription => '랭크 점수와 같지만, 12키 클리어 한정';

  @override
  String get playerScoreAverageXacc => '평균 절대정확도';

  @override
  String get playerScoreAverageXaccDescription => '상위 20개 클리어의 평균 정확도';

  @override
  String get creatorVerificationAllowed => '허가';

  @override
  String get creatorVerificationConditional => '조건 있음';

  @override
  String get creatorVerificationPending => '대기 중';

  @override
  String get creatorVerificationDeclined => '거절';

  @override
  String get playerPassSortScore => '점수';

  @override
  String get playerPassSortImpact => '랭크';

  @override
  String get playerPassSortSpeed => '속도';

  @override
  String get playerPassSortDate => '날짜';

  @override
  String get playerPassSortXacc => '절대정확도';

  @override
  String get playerPassSortDifficulty => '난이도';

  @override
  String get rankRangeDays30 => '30일';

  @override
  String get rankRangeDays90 => '90일';

  @override
  String get rankRangeDays365 => '1년';

  @override
  String get rankRangeAll => '전체';

  @override
  String get levelSortRecent => '최신순 (ID)';

  @override
  String get levelSortDiff => '난이도';

  @override
  String get levelSortClears => '클리어 수';

  @override
  String get levelSortTotalClears => '전체 클리어';

  @override
  String get levelSortLikes => '좋아요 수';

  @override
  String get levelSortBaseScore => '기반 점수';

  @override
  String get levelSortBpm => 'BPM';

  @override
  String get levelSortTiles => '타일 수';

  @override
  String get levelSortTime => '길이';

  @override
  String get levelSortRandom => '무작위';

  @override
  String get hidden => '히든';

  @override
  String get extra => '엑스트라';

  @override
  String get cancelled => '취소됨';

  @override
  String get lowestDifficulty => '최저 난이도';

  @override
  String get highestDifficulty => '최고 난이도';
}
