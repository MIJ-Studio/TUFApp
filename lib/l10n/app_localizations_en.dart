// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get monthNames => 'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec';

  @override
  String longDate(Object year, Object month, Object monthName, Object day) {
    return '$monthName $day, $year';
  }

  @override
  String monthDay(Object month, Object monthName, Object day) {
    return '$monthName $day';
  }

  @override
  String shortMonth(Object year, Object month, Object monthName) {
    return '$monthName \'$year';
  }

  @override
  String zoomPercent(Object percent) {
    return 'Zoom $percent%';
  }

  @override
  String couldNotSaveSettings(Object error) {
    return 'Could not save settings: $error';
  }

  @override
  String get ready => 'Ready.';

  @override
  String get loading => 'Loading...';

  @override
  String couldNotStart(Object message) {
    return 'Could not start: $message';
  }

  @override
  String couldNotOpenLink(Object url) {
    return 'Could not open the link: $url';
  }

  @override
  String get preparing => 'Preparing';

  @override
  String get extracting => 'Extracting';

  @override
  String get done => 'Done';

  @override
  String get cancelling => 'Cancelling';

  @override
  String downloadedSong(Object song) {
    return 'Downloaded: $song';
  }

  @override
  String downloadCancelled(Object song) {
    return 'Download cancelled: $song';
  }

  @override
  String tryThisLinkInstead(Object error, Object link) {
    return '$error Try this link instead: $link';
  }

  @override
  String downloadFailed(Object song, Object error) {
    return 'Download failed ($song): $error';
  }

  @override
  String searchFailed(Object error) {
    return 'Search failed: $error';
  }

  @override
  String get sortByName => 'Name';

  @override
  String get sortBySize => 'Size';

  @override
  String get sortByRecent => 'Recently downloaded';

  @override
  String get root => 'Root';

  @override
  String replacedPlusInFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'names',
      one: 'name',
    );
    return 'Replaced \'+\' with \'_\' in $count folder $_temp0. The game can\'t load paths that contain \'+\'.';
  }

  @override
  String couldNotReadFolder(Object error) {
    return 'Could not read the folder: $error';
  }

  @override
  String createdFolder(Object name) {
    return 'Created folder: $name';
  }

  @override
  String get cantDoThisWhile =>
      'Can\'t do this while a level is downloading. Try again once the download finishes.';

  @override
  String skippedStillDownloading(Object skipped) {
    return ' (skipped $skipped still downloading)';
  }

  @override
  String renamedTo(Object name) {
    return 'Renamed to: $name';
  }

  @override
  String movedItems(int count, Object where, Object skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'Moved $count $_temp0 to $where.$skipped';
  }

  @override
  String movedButCouldNot(
    Object count,
    Object failed,
    Object error,
    Object skipped,
  ) {
    return 'Moved $count, but $failed could not be moved ($error)$skipped';
  }

  @override
  String deletedItems(int count, Object skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'Deleted $count $_temp0.$skipped';
  }

  @override
  String movedEntry(Object name, Object where) {
    return 'Moved: $name → $where';
  }

  @override
  String deletedEntry(Object name) {
    return 'Deleted: $name';
  }

  @override
  String deletedWithLevels(int count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return 'Deleted with $count $_temp0: $name';
  }

  @override
  String folderOperationFailed(Object error) {
    return 'Folder operation failed: $error';
  }

  @override
  String get checkingForUpdates => 'Checking for updates...';

  @override
  String removedMissingLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return ' Removed $count $_temp0 whose folder is gone.';
  }

  @override
  String get everythingIsUpTo => 'Everything is up to date.';

  @override
  String updatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels have',
      one: 'level has',
    );
    return '$count $_temp0 an update.';
  }

  @override
  String couldNotCheckForUpdates(Object error) {
    return 'Could not check for updates: $error';
  }

  @override
  String deletedLevel(Object song) {
    return 'Deleted: $song';
  }

  @override
  String couldNotDelete(Object error) {
    return 'Could not delete: $error';
  }

  @override
  String get cantChangeTheFolder =>
      'Can\'t change the folder while a level is downloading.';

  @override
  String get useThisFolder => 'Use this folder';

  @override
  String libraryFolderChanged(Object path) {
    return 'Library folder changed: $path';
  }

  @override
  String couldNotOpenFolder(Object error) {
    return 'Could not open the folder: $error';
  }

  @override
  String failedSuffix(Object failed) {
    return ', $failed failed';
  }

  @override
  String stoppedDownloadingPack(
    Object name,
    Object done,
    Object total,
    Object failed,
  ) {
    return 'Stopped downloading \'$name\' ($done/$total done$failed)';
  }

  @override
  String downloadedPack(Object name, int done, Object failed) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return 'Downloaded \'$name\': $done $_temp0$failed';
  }

  @override
  String theDownloadStalledFor(Object seconds) {
    return 'The download stalled for $seconds seconds and was stopped.';
  }

  @override
  String theDownloadWasInterrupted(Object error) {
    return 'The download was interrupted: $error';
  }

  @override
  String theDownloadWasInterruptedBytes(Object received, Object count) {
    return 'The download was interrupted. ($received/$count bytes)';
  }

  @override
  String couldntReadTheDownloaded(Object fileName) {
    return 'Couldn\'t read the downloaded level list, so it starts fresh. The original file was kept as $fileName.';
  }

  @override
  String removedUnreadableEntries(int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'entries',
      one: 'entry',
    );
    return 'Removed $skipped unreadable $_temp0 from the downloaded level list.';
  }

  @override
  String get invalidLevelFolderName => 'Invalid level folder name';

  @override
  String zipInvalidPath(Object name) {
    return 'The zip contains an invalid path: $name';
  }

  @override
  String levelHasNoTUF(Object id) {
    return 'Level $id has no TUF CDN download link.';
  }

  @override
  String get cantWorkOutsideThe => 'Can\'t work outside the library folder.';

  @override
  String aFolderNamedAlready(Object name) {
    return 'A folder named \"$name\" already exists.';
  }

  @override
  String alreadyExists(Object name) {
    return '\"$name\" already exists.';
  }

  @override
  String get cantMoveAFolder => 'Can\'t move a folder into itself.';

  @override
  String alreadyExistsThere(Object name) {
    return '\"$name\" already exists there.';
  }

  @override
  String get folderNotFound => 'Folder not found.';

  @override
  String get pleaseEnterAName => 'Please enter a name.';

  @override
  String get namesCannotContain => 'Names cannot contain < > : \" / \\ | ? *';

  @override
  String get scores => 'Scores';

  @override
  String get passCounts => 'Pass counts';

  @override
  String get totalPasses => 'Total passes';

  @override
  String get uniqueLevelsCleared => 'Unique levels cleared';

  @override
  String get worldsFirstClears => 'World\'s first clears';

  @override
  String get worldsFirstPPClears => 'World\'s first PP clears';

  @override
  String get clears12k => '12K clears';

  @override
  String get clears16k => '16K clears';

  @override
  String get totalPurePerfects => 'Total pure perfects';

  @override
  String get reclears => 'Reclears';

  @override
  String get judgements => 'Judgements';

  @override
  String get totalTilesHit => 'Total tiles hit';

  @override
  String get generalAccuracy => 'General accuracy';

  @override
  String get earlyVsLateBias => 'Early vs late bias';

  @override
  String get levelsCleared => 'Levels cleared';

  @override
  String get totalTilecountCleared => 'Total tilecount cleared';

  @override
  String get estimatedPlaytime => 'Estimated playtime';

  @override
  String get avgBPMClearedLevels => 'Avg BPM (cleared levels)';

  @override
  String get rawSumOfAll => 'Raw sum of all pass scores';

  @override
  String get records => 'Records';

  @override
  String get firstPass => 'First pass';

  @override
  String get latestPass => 'Latest pass';

  @override
  String get bestAccuracy => 'Best accuracy';

  @override
  String get worstAccuracy => 'Worst accuracy';

  @override
  String get topSpeed => 'Top speed';

  @override
  String get highestTilecount => 'Highest tilecount';

  @override
  String get longestLevel => 'Longest level';

  @override
  String get highestBPMCleared => 'Highest BPM cleared';

  @override
  String get activity => 'Activity';

  @override
  String get accountAgeDays => 'Account age (days)';

  @override
  String get passesLast30Days => 'Passes (last 30 days)';

  @override
  String get levelsLiked => 'Levels liked';

  @override
  String get packsOwned => 'Packs owned';

  @override
  String get packsFavorited => 'Packs favorited';

  @override
  String get clearsByDifficultyType => 'Clears by difficulty type';

  @override
  String uniqueLevelsClearedTotal(Object unique, Object total) {
    return '$unique unique levels cleared ($total total passes)';
  }

  @override
  String uniqueLevelsClearedCount(Object unique) {
    return '$unique unique levels cleared';
  }

  @override
  String get identity => 'Identity';

  @override
  String get aliases => 'Aliases';

  @override
  String get teamsJoined => 'Teams joined';

  @override
  String get credits => 'Credits';

  @override
  String get levelsAsCharter => 'Levels as charter';

  @override
  String get levelsAsVFX => 'Levels as VFX';

  @override
  String get chartContent => 'Chart content';

  @override
  String get tilesPlaced => 'Tiles placed';

  @override
  String get totalChartDuration => 'Total chart duration';

  @override
  String get avgTilecount => 'Avg tilecount';

  @override
  String get avgLevelLength => 'Avg level length';

  @override
  String get avgBPM => 'Avg BPM';

  @override
  String get totalClearsOnCharts => 'Total clears on charts';

  @override
  String get totalLikesOnCharts => 'Total likes on charts';

  @override
  String get totalDownloadsOnCharts => 'Total downloads on charts';

  @override
  String get audience => 'Audience';

  @override
  String get uniquePlayersWhoCleared => 'Unique players who cleared';

  @override
  String get wfsOnCharts => 'WF\'s on charts';

  @override
  String get wfPpsOnCharts => 'WF PP\'s on charts';

  @override
  String get totalTilesHitOnCharts => 'Total tiles hit';

  @override
  String get timeline => 'Timeline';

  @override
  String get firstChart => 'First chart';

  @override
  String get latestChart => 'Latest chart';

  @override
  String get levelsByDifficultyType => 'Levels by difficulty type';

  @override
  String get special => 'Special';

  @override
  String topClear(Object letter, Object number, Object count) {
    return 'Top $letter clear: $letter$number ($count×)';
  }

  @override
  String letterNoClears(Object letter) {
    return '$letter: no clears';
  }

  @override
  String qFromWorldsFirst(Object letter, Object tier, Object count) {
    return '${letter}Q$tier from world\'s first $letter clears ($count×)';
  }

  @override
  String qNoWorldsFirst(Object letter) {
    return '${letter}Q: no world\'s first clears in this range';
  }

  @override
  String typeLevelCount(Object type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$type · $count $_temp0';
  }

  @override
  String get unexpectedSearchResponse => 'Unexpected search response.';

  @override
  String noLevelField(Object id) {
    return 'The response for level $id has no level field.';
  }

  @override
  String get unexpectedDifficultyListResponse =>
      'Unexpected difficulty list response.';

  @override
  String get listTag => 'tag';

  @override
  String get listCurationType => 'curation type';

  @override
  String unexpectedListResponse(Object label) {
    return 'Unexpected $label list response.';
  }

  @override
  String unexpectedPassResponseFor(Object levelId) {
    return 'Unexpected pass response for level $levelId.';
  }

  @override
  String unexpectedResponseForPass(Object id) {
    return 'Unexpected response for pass $id.';
  }

  @override
  String unexpectedResponseForPlayer(Object id) {
    return 'Unexpected response for player $id.';
  }

  @override
  String get unexpectedPassListResponse => 'Unexpected pass list response.';

  @override
  String get unexpectedLeaderboardResponse =>
      'Unexpected leaderboard response.';

  @override
  String get unexpectedCreatorListResponse =>
      'Unexpected creator list response.';

  @override
  String playerNotFound(Object id) {
    return 'Player $id not found.';
  }

  @override
  String unexpectedPassResponseForPlayer(Object id) {
    return 'Unexpected pass response for player $id.';
  }

  @override
  String unexpectedRankHistoryResponse(Object id) {
    return 'Unexpected rank history response for player $id.';
  }

  @override
  String creatorNotFound(Object id) {
    return 'Creator $id not found.';
  }

  @override
  String get unexpectedPackListResponse => 'Unexpected pack list response.';

  @override
  String unexpectedResponseForPack(Object id) {
    return 'Unexpected response for pack $id.';
  }

  @override
  String serverNotResponding(Object url) {
    return 'The server is not responding: $url';
  }

  @override
  String downloadRequestFailed(Object url, Object error) {
    return 'Download request failed: $url ($error)';
  }

  @override
  String requestFailed(Object path, Object error) {
    return 'Request failed: $path ($error)';
  }

  @override
  String couldNotReadTheResponse(Object path) {
    return 'Could not read the response: $path';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String keyCount(Object count) {
    return '${count}K';
  }

  @override
  String get keys16 => '16K';

  @override
  String get keys12 => '12K';

  @override
  String get theServersDifficultyList =>
      'The server\'s difficulty list has no PGU difficulties.';

  @override
  String get levels => 'Levels';

  @override
  String get packs => 'Packs';

  @override
  String get passes => 'Passes';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get creators => 'Creators';

  @override
  String get library => 'Library';

  @override
  String get downloading => 'Downloading';

  @override
  String get language => 'Language';

  @override
  String systemLanguage(Object language) {
    return 'System ($language)';
  }

  @override
  String get couldntLoadTheList => 'Couldn\'t load the list';

  @override
  String get retry => 'Retry';

  @override
  String get tryDifferentFilters => 'Try different filters.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get descending => 'Descending';

  @override
  String get ascending => 'Ascending';

  @override
  String get browsePassesFromEvery => 'Browse passes from every player.';

  @override
  String passCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'passes',
      one: 'pass',
    );
    return '$countString $_temp0';
  }

  @override
  String get noPassesFound => 'No passes found';

  @override
  String get allPassesLoaded => 'All passes loaded';

  @override
  String get searchBySongOr => 'Search by song or player (#id to find a pass)';

  @override
  String get sort => 'Sort';

  @override
  String get filter => 'Filter';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get dragTheSliderTo => 'Drag the slider to set the range.';

  @override
  String get includeSpecialDifficulties => 'Include special difficulties';

  @override
  String get keyCountFilter => 'Key count';

  @override
  String get worldsFirst => 'World\'s first';

  @override
  String get gameVersion => 'Game version';

  @override
  String get resetAll => 'Reset all';

  @override
  String get hiddenLevel => 'Hidden level';

  @override
  String get viewPlayerProfile => 'View player profile';

  @override
  String get findThePeopleWho =>
      'Find the people who make levels by level count, clears, and curations.';

  @override
  String creatorCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'creators',
      one: 'creator',
    );
    return '$countString $_temp0';
  }

  @override
  String get noCreatorsFound => 'No creators found';

  @override
  String get allCreatorsLoaded => 'All creators loaded';

  @override
  String get searchByCreatorName => 'Search by creator name (or @account)';

  @override
  String get other => 'Other';

  @override
  String get verificationStatus => 'Verification status';

  @override
  String get allStatuses => 'All statuses';

  @override
  String get curationTypes => 'Curation types';

  @override
  String get onlyShowsCreatorsWith =>
      'Only shows creators with levels of the chosen types.';

  @override
  String get matchAny => 'Any';

  @override
  String get matchAll => 'All';

  @override
  String get noLinkedAccount => 'No linked account';

  @override
  String get seePlayerRankingsBy =>
      'See player rankings by score, passes, top difficulty, and more.';

  @override
  String playerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'players',
      one: 'player',
    );
    return '$countString $_temp0';
  }

  @override
  String get noPlayersFound => 'No players found';

  @override
  String get allPlayersLoaded => 'All players loaded';

  @override
  String get searchByPlayerName => 'Search by player name';

  @override
  String get refresh => 'Refresh';

  @override
  String topDifficulty(Object difficulty) {
    return 'Top difficulty $difficulty';
  }

  @override
  String get loadingDifficulties => 'Loading difficulties...';

  @override
  String get couldntConnectToThe => 'Couldn\'t connect to the server';

  @override
  String get findLevelsOnTUF =>
      'Find levels on TUF and download them right away.';

  @override
  String get searchBySongArtist => 'Search by song, artist, or creator';

  @override
  String get includeQDifficulties => 'Include Q difficulties';

  @override
  String get noCurationTypes => 'No curation types';

  @override
  String get findByTheGrades => 'Find by the grades curators gave.';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'No tags';

  @override
  String get findByTheTags => 'Find by the tags on a level.';

  @override
  String get clearedLevels => 'Cleared levels';

  @override
  String get downloadable => 'Downloadable';

  @override
  String get filterAll => 'All';

  @override
  String get filterHide => 'Hide';

  @override
  String get filterOnly => 'Only';

  @override
  String get clearSelection => 'Clear';

  @override
  String get includeAll => 'All';

  @override
  String get specialDifficulties => 'Special difficulties';

  @override
  String get selectedDifficultiesAreShown =>
      'Selected difficulties are shown in the results too.';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String levelCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$countString $_temp0';
  }

  @override
  String get detailedView => 'Detailed view';

  @override
  String get compactView => 'Compact view';

  @override
  String get noLevelsMatch => 'No levels match';

  @override
  String get tryADifferentSearch => 'Try a different search or filter.';

  @override
  String get allLevelsLoaded => 'All levels loaded';

  @override
  String get back => 'Back';

  @override
  String uniquePlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'players',
      one: 'player',
    );
    return '$countString $_temp0';
  }

  @override
  String totalClearsSuffix(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return ' ($countString total)';
  }

  @override
  String get couldntLoadPasses => 'Couldn\'t load passes';

  @override
  String get noPassesYet => 'No passes yet';

  @override
  String get firstClear => 'First clear';

  @override
  String get highestScore => 'Highest score';

  @override
  String get highestSpeed => 'Highest speed';

  @override
  String get highestAccuracy => 'Highest accuracy';

  @override
  String get totalClears => 'Total clears';

  @override
  String get fullInfo => 'Full info';

  @override
  String feeling(Object feeling) {
    return 'Feeling $feeling';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0';
  }

  @override
  String get empty => 'Empty';

  @override
  String folderCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'folders',
      one: 'folder',
    );
    return '$countString $_temp0';
  }

  @override
  String get addedManuallyNotIn => 'Added manually (not in the app\'s list)';

  @override
  String get updateAvailable => 'Update available';

  @override
  String sizeAndDownloadDate(Object size, Object date) {
    return '$size  ·  downloaded $date';
  }

  @override
  String get update => 'Update';

  @override
  String get more => 'More';

  @override
  String get organizeYourDownloadedLevels =>
      'Organize your downloaded levels into folders and check for updates.';

  @override
  String levelCountAndSize(int count, Object size) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$countString $_temp0  ·  $size';
  }

  @override
  String get checking => 'Checking...';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String updateAll(Object count) {
    return 'Update all ($count)';
  }

  @override
  String get upBackspace => 'Up (Backspace)';

  @override
  String get newFolder => 'New folder';

  @override
  String get openInExplorer => 'Open in Explorer';

  @override
  String get changeLibraryFolder => 'Change library folder';

  @override
  String get refreshLibrary => 'Refresh';

  @override
  String selected(Object count) {
    return '$count selected';
  }

  @override
  String get move => 'Move';

  @override
  String get delete => 'Delete';

  @override
  String get deselect => 'Deselect';

  @override
  String get open => 'Open';

  @override
  String get rename => 'Rename';

  @override
  String get moveToFolder => 'Move to folder';

  @override
  String get selectAllItems => 'Select all';

  @override
  String get folderName => 'Folder name';

  @override
  String get create => 'Create';

  @override
  String get newName => 'New name';

  @override
  String get renameConfirm => 'Rename';

  @override
  String deleteNamed(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'Delete $count $_temp0?';
  }

  @override
  String thisDeletesItFrom(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return 'This deletes it from disk, including $countString $_temp0 inside.';
  }

  @override
  String get thisDeletesItFromDisk => 'This deletes it from disk.';

  @override
  String get cancel => 'Cancel';

  @override
  String moveNamed(Object name) {
    return 'Move \"$name\"';
  }

  @override
  String moveItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'Move $count $_temp0';
  }

  @override
  String get noSubfolders => 'No subfolders.';

  @override
  String get moveToRoot => 'Move to root';

  @override
  String get moveHere => 'Move here';

  @override
  String get noDownloadedLevelsYet => 'No downloaded levels yet';

  @override
  String get thisFolderIsEmpty => 'This folder is empty';

  @override
  String get findLevelsYouLike =>
      'Find levels you like in Levels and download them.';

  @override
  String get dragLevelsHereOr =>
      'Drag levels here, or create more folders inside.';

  @override
  String get browseLevels => 'Browse levels';

  @override
  String get levelPacks => 'Level Packs';

  @override
  String get browseLevelPacksMade =>
      'Browse level packs made by the community and download them in one go, folders and all.';

  @override
  String get searchByPackName => 'Search by pack name';

  @override
  String packCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'packs',
      one: 'pack',
    );
    return '$countString $_temp0';
  }

  @override
  String get couldntLoadPacks => 'Couldn\'t load packs';

  @override
  String get noPacksFound => 'No packs found';

  @override
  String get trySearchingForA => 'Try searching for a different name.';

  @override
  String get allPacksLoaded => 'All packs loaded';

  @override
  String moreCount(Object more) {
    return '+$more more';
  }

  @override
  String get pinnedPack => 'Pinned pack';

  @override
  String likeCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'likes',
      one: 'like',
    );
    return '$countString $_temp0';
  }

  @override
  String get allPacks => 'All packs';

  @override
  String get downloadPack => 'Download pack';

  @override
  String downloadPackCount(Object count) {
    return 'Download pack ($count)';
  }

  @override
  String get items => 'Items';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get expandAll => 'Expand all';

  @override
  String itemAndLevelCount(int items, int levelCount) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      levelCount,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$items $_temp0 · $levelCount $_temp1';
  }

  @override
  String downloadFolderCount(Object count) {
    return 'Download folder ($count)';
  }

  @override
  String get emptyFolder => 'Empty folder';

  @override
  String get allDownloaded => 'All downloaded';

  @override
  String downloadNamed(Object label) {
    return 'Download \'$label\'';
  }

  @override
  String downloadPackExplanation(int count, Object folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return 'Downloads the $count $_temp0 you don\'t have yet, one by one.\nThey\'re saved in the \'$folder\' folder of the library, in the same folder layout as the pack.\nLevels you already have are skipped and stay where they are.';
  }

  @override
  String get download => 'Download';

  @override
  String failedCountSuffix(Object failedCount) {
    return ' · $failedCount failed';
  }

  @override
  String get waiting => 'Waiting';

  @override
  String get stopping => 'Stopping';

  @override
  String get stop => 'Stop';

  @override
  String get couldntLoadThePack => 'Couldn\'t load the pack contents';

  @override
  String get thisPackIsEmpty => 'This pack is empty';

  @override
  String playersPass(Object player) {
    return '$player\'s pass';
  }

  @override
  String get loadingScore => 'Loading score...';

  @override
  String get couldntLoadTheScore => 'Couldn\'t load the score';

  @override
  String get topDifficultyCleared => 'Top difficulty cleared';

  @override
  String worldsFirstClearCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'clears',
      one: 'clear',
    );
    return '$countString world\'s first $_temp0';
  }

  @override
  String get rankedScoreWithoutThis => 'Ranked score without this pass';

  @override
  String clearedOn(Object date) {
    return 'Cleared $date';
  }

  @override
  String get overallRank => 'Overall rank';

  @override
  String get score => 'Score';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get speed => 'Speed';

  @override
  String get feelingRating => 'Feeling rating';

  @override
  String get expectedRating => 'Expected rating';

  @override
  String get watchVideoInBrowser => 'Watch video in browser';

  @override
  String get leavingTUF => 'Leaving TUF?';

  @override
  String get youAreAboutTo =>
      'You are about to visit an external site. Only continue if you trust this destination.';

  @override
  String trustForThisSession(Object host) {
    return 'Trust $host for this session';
  }

  @override
  String get proceed => 'Continue';

  @override
  String get openVideo => 'Open video';

  @override
  String get loadingPasses => 'Loading passes…';

  @override
  String get loadingLevels => 'Loading levels…';

  @override
  String get tilesUnit => 'tiles';

  @override
  String get creator => 'Creator';

  @override
  String get noLevels => 'No levels';

  @override
  String get totalLevels => 'Total levels';

  @override
  String get curatedLevels => 'Curated levels';

  @override
  String get totalLevelClears => 'Total level clears';

  @override
  String get bio => 'Bio';

  @override
  String get levelsByDifficulty => 'Levels by difficulty';

  @override
  String get noPasses => 'No passes';

  @override
  String get difficultiesCleared => 'Difficulties cleared';

  @override
  String get rankedScore => 'Ranked Score';

  @override
  String get averageXAcc => 'Average X-acc';

  @override
  String get totalScore => 'Total Score';

  @override
  String get viewUsersPacks => 'View user\'s packs';

  @override
  String get viewCreatorProfile => 'View creator profile';

  @override
  String get playerBio => 'Bio';

  @override
  String get clearsByDifficulty => 'Clears by difficulty';

  @override
  String clearCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'clears',
      one: 'clear',
    );
    return '$countString $_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get oneDayAgo => '1 day ago';

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get rank => 'Rank';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'followers',
      one: 'follower',
    );
    return '$countString $_temp0';
  }

  @override
  String alsoKnownAs(Object aliases) {
    return 'Also known as: $aliases';
  }

  @override
  String get showAll => 'Show all';

  @override
  String get allStats => 'All stats';

  @override
  String get rankedScoreRank => 'Ranked score rank';

  @override
  String get atHighestRankRight => 'At highest rank right now!';

  @override
  String highestRank(Object rank, Object date) {
    return 'Highest rank: #$rank ($date)';
  }

  @override
  String get unranked => 'Unranked';

  @override
  String get close => 'Close';

  @override
  String titleStats(Object title) {
    return '$title\'s stats';
  }

  @override
  String get viewPass => 'View pass';

  @override
  String difficultyClearCount(Object difficulty, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'clears',
      one: 'clear',
    );
    return '$difficulty · $count $_temp0';
  }

  @override
  String get levelUploadPermission => 'Level upload permission';

  @override
  String uploadConditions(Object text) {
    return 'Upload conditions: $text';
  }

  @override
  String playerPassCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'passes',
      one: 'pass',
    );
    return '$countString $_temp0';
  }

  @override
  String get searchBySongOrArtist => 'Search by song or artist';

  @override
  String get hideReclears => 'Hide reclears';

  @override
  String get levelsSection => 'Levels';

  @override
  String creatorLevelCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$countString $_temp0';
  }

  @override
  String get searchThisCreatorsLevels => 'Search this creator\'s levels';

  @override
  String get tournaments => 'Tournaments';

  @override
  String get openPack => 'Open pack';

  @override
  String placementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'placements',
      one: 'placement',
    );
    return '$count $_temp0';
  }

  @override
  String get otherTournaments => 'Other tournaments';

  @override
  String get scoreBreakdown => 'Score breakdown';

  @override
  String get includeDuplicates => 'Include duplicates';

  @override
  String get couldntLoadRankHistory => 'Couldn\'t load rank history';

  @override
  String get noRankHistoryStored => 'No rank history stored yet';

  @override
  String get rankOverTime => 'Rank over time';

  @override
  String get rankedScoreLine => 'Ranked score';

  @override
  String get generalScore => 'General score';

  @override
  String get passesAboveCountToward => 'Passes above count toward Ranked Score';

  @override
  String scoreOrMore(Object score) {
    return '$score+';
  }

  @override
  String get favorites => 'Favorites';

  @override
  String get pack => 'Pack';

  @override
  String rankedScoreValue(Object score) {
    return 'Ranked Score $score';
  }

  @override
  String chartLevelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$count $_temp0';
  }

  @override
  String get couldntOpenTheLevel => 'Couldn\'t open the level';

  @override
  String get couldntOpenThePass => 'Couldn\'t open the pass';

  @override
  String get theLevelOfThis => 'The level of this pass is unknown.';

  @override
  String get couldntOpenThePack => 'Couldn\'t open the pack.';

  @override
  String get notFound => 'Not found';

  @override
  String get nothingHere => 'Nothing here';

  @override
  String get couldntOpenThePage => 'Couldn\'t open the page';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get couldntLoadMore => 'Couldn\'t load more';

  @override
  String expectedDifficulty(Object difficulty) {
    return 'Expected difficulty: $difficulty';
  }

  @override
  String curation(Object curation) {
    return 'Curation: $curation';
  }

  @override
  String baseScoreOverridePP(int score) {
    final intl.NumberFormat scoreNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String scoreString = scoreNumberFormat.format(score);

    return 'Base score override: $scoreString PP (used instead of the difficulty\'s base score)';
  }

  @override
  String get length => 'Length';

  @override
  String get tileCount => 'Tiles';

  @override
  String get noCreatorInfo => 'No creator info';

  @override
  String clearedByPlayerTotal(int players, int clears) {
    final intl.NumberFormat playersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String playersString = playersNumberFormat.format(players);
    final intl.NumberFormat clearsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String clearsString = clearsNumberFormat.format(clears);

    String _temp0 = intl.Intl.pluralLogic(
      players,
      locale: localeName,
      other: 'players',
      one: 'player',
    );
    return 'Cleared by $playersString $_temp0 ($clearsString total)';
  }

  @override
  String get likes => 'Likes';

  @override
  String get watchVideo => 'Watch video';

  @override
  String get steamWorkshop => 'Steam Workshop';

  @override
  String get downloads => 'Downloads';

  @override
  String get levelFileSize => 'Level file size';

  @override
  String get downloadToLibrary => 'Download to library';

  @override
  String get updateToTheNew => 'Update to the new version';

  @override
  String get alreadyDownloaded => 'Already downloaded';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get noFileToDownload => 'No file to download directly from TUF';

  @override
  String get noLink => 'No link';

  @override
  String addedOn(Object date) {
    return 'Added: $date';
  }

  @override
  String get team => 'Team';

  @override
  String get baseScore => 'Base score';

  @override
  String get charters => 'Charters';

  @override
  String get vfx => 'VFX';

  @override
  String get worldsFirstClearBadge => 'World\'s First Clear!';

  @override
  String get worldsFirstPurePerfect => 'World\'s First Pure Perfect!';

  @override
  String get autoSubmitted => 'Auto-submitted';

  @override
  String get submittedStraightFromThe => 'Submitted straight from the game';

  @override
  String get noHold => 'No Hold';

  @override
  String get altHoldOption => 'Alt. hold option';

  @override
  String get beforeTheEngineChange =>
      'Before the engine change (up to v2.9.8).\nTiming engine issues made it less stable and precise.';

  @override
  String get beforeXPerfectUp => 'Before X-Perfect (up to v3.3.1).';

  @override
  String get whatThisPassAdds => 'What this pass adds to the ranked score';

  @override
  String get doesntCountTowardThe =>
      'Doesn\'t count toward the ranked score (what it could have added)';

  @override
  String get speedMultiplier => 'Speed';

  @override
  String get clearSortRecent => 'Date';

  @override
  String get clearSortScore => 'Score';

  @override
  String get clearSortAccuracy => 'Accuracy';

  @override
  String get clearSortDifficulty => 'Difficulty';

  @override
  String get clearSortSpeed => 'Speed';

  @override
  String get clearSortKeyCount => 'Key count';

  @override
  String get clearSortRandom => 'Random';

  @override
  String get keyCountFilterAll => 'All';

  @override
  String get keyCountFilterK12 => '12K';

  @override
  String get keyCountFilterK16 => '16K';

  @override
  String get worldsFirstFilterNone => 'All';

  @override
  String get worldsFirstFilterWf => 'WF';

  @override
  String get worldsFirstFilterWfpp => 'WF PP';

  @override
  String get worldsFirstFilterEither => 'Either';

  @override
  String get worldsFirstFilterBoth => 'Both';

  @override
  String get gameVersionFilterAll => 'All';

  @override
  String get gameVersionFilterLatest => 'Latest';

  @override
  String get gameVersionFilterPre340 => '<3.4.0';

  @override
  String get gameVersionFilterV2 => 'v2';

  @override
  String get leaderboardSortRankedScore => 'Ranked Score';

  @override
  String get leaderboardSortTotalScoreV2 => 'Total Score';

  @override
  String get leaderboardSortGeneralScore => 'General Score';

  @override
  String get leaderboardSortPpScore => 'PP Score';

  @override
  String get leaderboardSortWfScore => 'WF Score';

  @override
  String get leaderboardSortWfPPScore => 'WF PP Score';

  @override
  String get leaderboardSortScore12K => '12K Score';

  @override
  String get leaderboardSortAverageXacc => 'Average X-acc';

  @override
  String get leaderboardSortTotalPasses => 'Total Passes';

  @override
  String get leaderboardSortUniversalPassCount => 'Universal Passes';

  @override
  String get leaderboardSortWorldsFirstCount => 'WF Passes';

  @override
  String get leaderboardSortWorldsFirstPPCount => 'WF PP Passes';

  @override
  String get leaderboardSortTopDiff => 'Top Difficulty';

  @override
  String get leaderboardSortTop12kDiff => 'Top 12K Difficulty';

  @override
  String get creatorSortChartsTotal => 'Total Levels';

  @override
  String get creatorSortChartsCharted => 'Levels Charted';

  @override
  String get creatorSortChartsVfxed => 'Levels VFX\'d';

  @override
  String get creatorSortChartsTeamed => 'Levels as a team member';

  @override
  String get creatorSortTotalChartClears => 'Total Level Clears';

  @override
  String get creatorSortTotalChartLikes => 'Total Level Likes';

  @override
  String get creatorSortName => 'Name';

  @override
  String get packSortRecent => 'Recent';

  @override
  String get packSortName => 'Name';

  @override
  String get packSortLevels => 'Level Count';

  @override
  String get packSortFavorites => 'Favorites';

  @override
  String get judgementTooEarly => 'Too Early';

  @override
  String get judgementEarly => 'Early!';

  @override
  String get judgementEarlyPerfect => 'EPerfect';

  @override
  String get judgementPerfectMinus => 'Perfect−';

  @override
  String get judgementPerfect => 'Perfect';

  @override
  String get judgementPerfectPlus => 'Perfect+';

  @override
  String get judgementLatePerfect => 'LPerfect';

  @override
  String get judgementLate => 'Late!';

  @override
  String get judgementTooLate => 'Too Late';

  @override
  String get playerScoreRankedScore => 'Ranked Score';

  @override
  String get playerScoreRankedScoreDescription =>
      'Decaying sum of 20 best clears (excluding reclears)';

  @override
  String get playerScoreTotalScoreV2 => 'Total Score';

  @override
  String get playerScoreTotalScoreV2Description =>
      'Sum of all clears without reclears';

  @override
  String get playerScoreGeneralScore => 'General Score';

  @override
  String get playerScoreGeneralScoreDescription =>
      'Sum of all clears including reclears';

  @override
  String get playerScorePpScore => 'PP Score';

  @override
  String get playerScorePpScoreDescription =>
      'Ranked Score, but all clears must also be pure perfects';

  @override
  String get playerScoreWfScore => 'WF Score';

  @override
  String get playerScoreWfScoreDescription =>
      'Sum of all level base scores from world\'s first passes';

  @override
  String get playerScoreWfPPScore => 'WF PP Score';

  @override
  String get playerScoreWfPPScoreDescription =>
      'Sum of all level base scores from world\'s first pure perfect passes';

  @override
  String get playerScoreScore12K => '12K Score';

  @override
  String get playerScoreScore12KDescription =>
      'Ranked Score, but all clears must be 12K';

  @override
  String get playerScoreAverageXacc => 'Average X-acc';

  @override
  String get playerScoreAverageXaccDescription =>
      'Average accuracy of top 20 passes';

  @override
  String get creatorVerificationAllowed => 'Allowed';

  @override
  String get creatorVerificationConditional => 'Conditional';

  @override
  String get creatorVerificationPending => 'Pending';

  @override
  String get creatorVerificationDeclined => 'Declined';

  @override
  String get playerPassSortScore => 'Score';

  @override
  String get playerPassSortImpact => 'Impact';

  @override
  String get playerPassSortSpeed => 'Speed';

  @override
  String get playerPassSortDate => 'Date';

  @override
  String get playerPassSortXacc => 'X-Accuracy';

  @override
  String get playerPassSortDifficulty => 'Difficulty';

  @override
  String get rankRangeDays30 => '30 days';

  @override
  String get rankRangeDays90 => '90 days';

  @override
  String get rankRangeDays365 => '1 year';

  @override
  String get rankRangeAll => 'All time';

  @override
  String get levelSortRecent => 'Newest (ID)';

  @override
  String get levelSortDiff => 'Difficulty';

  @override
  String get levelSortClears => 'Clears';

  @override
  String get levelSortTotalClears => 'Total clears';

  @override
  String get levelSortLikes => 'Likes';

  @override
  String get levelSortBaseScore => 'Base score';

  @override
  String get levelSortBpm => 'BPM';

  @override
  String get levelSortTiles => 'Tiles';

  @override
  String get levelSortTime => 'Length';

  @override
  String get levelSortRandom => 'Random';

  @override
  String get hidden => 'Hidden';

  @override
  String get extra => 'Extra';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get lowestDifficulty => 'Lowest difficulty';

  @override
  String get highestDifficulty => 'Highest difficulty';
}
