import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// Name of this language, written in the language itself (shown in the language menu).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// Short month names, January to December, separated by |.
  ///
  /// In en, this message translates to:
  /// **'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec'**
  String get monthNames;

  /// A full date, e.g. May 5, 2026.
  ///
  /// In en, this message translates to:
  /// **'{monthName} {day}, {year}'**
  String longDate(Object year, Object month, Object monthName, Object day);

  /// A date without the year, e.g. May 5.
  ///
  /// In en, this message translates to:
  /// **'{monthName} {day}'**
  String monthDay(Object month, Object monthName, Object day);

  /// A month with a two-digit year, e.g. May '26.
  ///
  /// In en, this message translates to:
  /// **'{monthName} \'{year}'**
  String shortMonth(Object year, Object month, Object monthName);

  /// No description provided for @zoomPercent.
  ///
  /// In en, this message translates to:
  /// **'Zoom {percent}%'**
  String zoomPercent(Object percent);

  /// No description provided for @couldNotSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings: {error}'**
  String couldNotSaveSettings(Object error);

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready.'**
  String get ready;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @couldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {message}'**
  String couldNotStart(Object message);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link: {url}'**
  String couldNotOpenLink(Object url);

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting'**
  String get extracting;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling'**
  String get cancelling;

  /// No description provided for @downloadedSong.
  ///
  /// In en, this message translates to:
  /// **'Downloaded: {song}'**
  String downloadedSong(Object song);

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled: {song}'**
  String downloadCancelled(Object song);

  /// No description provided for @tryThisLinkInstead.
  ///
  /// In en, this message translates to:
  /// **'{error} Try this link instead: {link}'**
  String tryThisLinkInstead(Object error, Object link);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed ({song}): {error}'**
  String downloadFailed(Object song, Object error);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(Object error);

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortBySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortBySize;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently downloaded'**
  String get sortByRecent;

  /// No description provided for @root.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get root;

  /// No description provided for @replacedPlusInFolders.
  ///
  /// In en, this message translates to:
  /// **'Replaced \'+\' with \'_\' in {count} folder {count, plural, =1{name} other{names}}. The game can\'t load paths that contain \'+\'.'**
  String replacedPlusInFolders(int count);

  /// No description provided for @couldNotReadFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not read the folder: {error}'**
  String couldNotReadFolder(Object error);

  /// No description provided for @createdFolder.
  ///
  /// In en, this message translates to:
  /// **'Created folder: {name}'**
  String createdFolder(Object name);

  /// No description provided for @cantDoThisWhile.
  ///
  /// In en, this message translates to:
  /// **'Can\'t do this while a level is downloading. Try again once the download finishes.'**
  String get cantDoThisWhile;

  /// No description provided for @skippedStillDownloading.
  ///
  /// In en, this message translates to:
  /// **' (skipped {skipped} still downloading)'**
  String skippedStillDownloading(Object skipped);

  /// No description provided for @renamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to: {name}'**
  String renamedTo(Object name);

  /// No description provided for @movedItems.
  ///
  /// In en, this message translates to:
  /// **'Moved {count} {count, plural, =1{item} other{items}} to {where}.{skipped}'**
  String movedItems(int count, Object where, Object skipped);

  /// No description provided for @movedButCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Moved {count}, but {failed} could not be moved ({error}){skipped}'**
  String movedButCouldNot(
    Object count,
    Object failed,
    Object error,
    Object skipped,
  );

  /// No description provided for @deletedItems.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} {count, plural, =1{item} other{items}}.{skipped}'**
  String deletedItems(int count, Object skipped);

  /// No description provided for @movedEntry.
  ///
  /// In en, this message translates to:
  /// **'Moved: {name} → {where}'**
  String movedEntry(Object name, Object where);

  /// No description provided for @deletedEntry.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {name}'**
  String deletedEntry(Object name);

  /// No description provided for @deletedWithLevels.
  ///
  /// In en, this message translates to:
  /// **'Deleted with {count} {count, plural, =1{level} other{levels}}: {name}'**
  String deletedWithLevels(int count, Object name);

  /// No description provided for @folderOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Folder operation failed: {error}'**
  String folderOperationFailed(Object error);

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @removedMissingLevels.
  ///
  /// In en, this message translates to:
  /// **' Removed {count} {count, plural, =1{level} other{levels}} whose folder is gone.'**
  String removedMissingLevels(int count);

  /// No description provided for @everythingIsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date.'**
  String get everythingIsUpTo;

  /// No description provided for @updatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{level has} other{levels have}} an update.'**
  String updatesAvailable(int count);

  /// No description provided for @couldNotCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates: {error}'**
  String couldNotCheckForUpdates(Object error);

  /// No description provided for @deletedLevel.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {song}'**
  String deletedLevel(Object song);

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDelete(Object error);

  /// No description provided for @cantChangeTheFolder.
  ///
  /// In en, this message translates to:
  /// **'Can\'t change the folder while a level is downloading.'**
  String get cantChangeTheFolder;

  /// No description provided for @useThisFolder.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get useThisFolder;

  /// No description provided for @libraryFolderChanged.
  ///
  /// In en, this message translates to:
  /// **'Library folder changed: {path}'**
  String libraryFolderChanged(Object path);

  /// No description provided for @couldNotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not open the folder: {error}'**
  String couldNotOpenFolder(Object error);

  /// No description provided for @failedSuffix.
  ///
  /// In en, this message translates to:
  /// **', {failed} failed'**
  String failedSuffix(Object failed);

  /// No description provided for @stoppedDownloadingPack.
  ///
  /// In en, this message translates to:
  /// **'Stopped downloading \'{name}\' ({done}/{total} done{failed})'**
  String stoppedDownloadingPack(
    Object name,
    Object done,
    Object total,
    Object failed,
  );

  /// No description provided for @downloadedPack.
  ///
  /// In en, this message translates to:
  /// **'Downloaded \'{name}\': {done} {done, plural, =1{level} other{levels}}{failed}'**
  String downloadedPack(Object name, int done, Object failed);

  /// No description provided for @theDownloadStalledFor.
  ///
  /// In en, this message translates to:
  /// **'The download stalled for {seconds} seconds and was stopped.'**
  String theDownloadStalledFor(Object seconds);

  /// No description provided for @theDownloadWasInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The download was interrupted: {error}'**
  String theDownloadWasInterrupted(Object error);

  /// No description provided for @theDownloadWasInterruptedBytes.
  ///
  /// In en, this message translates to:
  /// **'The download was interrupted. ({received}/{count} bytes)'**
  String theDownloadWasInterruptedBytes(Object received, Object count);

  /// No description provided for @couldntReadTheDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the downloaded level list, so it starts fresh. The original file was kept as {fileName}.'**
  String couldntReadTheDownloaded(Object fileName);

  /// No description provided for @removedUnreadableEntries.
  ///
  /// In en, this message translates to:
  /// **'Removed {skipped} unreadable {skipped, plural, =1{entry} other{entries}} from the downloaded level list.'**
  String removedUnreadableEntries(int skipped);

  /// No description provided for @invalidLevelFolderName.
  ///
  /// In en, this message translates to:
  /// **'Invalid level folder name'**
  String get invalidLevelFolderName;

  /// No description provided for @zipInvalidPath.
  ///
  /// In en, this message translates to:
  /// **'The zip contains an invalid path: {name}'**
  String zipInvalidPath(Object name);

  /// No description provided for @levelHasNoTUF.
  ///
  /// In en, this message translates to:
  /// **'Level {id} has no TUF CDN download link.'**
  String levelHasNoTUF(Object id);

  /// No description provided for @cantWorkOutsideThe.
  ///
  /// In en, this message translates to:
  /// **'Can\'t work outside the library folder.'**
  String get cantWorkOutsideThe;

  /// No description provided for @aFolderNamedAlready.
  ///
  /// In en, this message translates to:
  /// **'A folder named \"{name}\" already exists.'**
  String aFolderNamedAlready(Object name);

  /// No description provided for @alreadyExists.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists.'**
  String alreadyExists(Object name);

  /// No description provided for @cantMoveAFolder.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move a folder into itself.'**
  String get cantMoveAFolder;

  /// No description provided for @alreadyExistsThere.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists there.'**
  String alreadyExistsThere(Object name);

  /// No description provided for @folderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder not found.'**
  String get folderNotFound;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get pleaseEnterAName;

  /// No description provided for @namesCannotContain.
  ///
  /// In en, this message translates to:
  /// **'Names cannot contain < > : \" / \\ | ? *'**
  String get namesCannotContain;

  /// No description provided for @scores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get scores;

  /// No description provided for @passCounts.
  ///
  /// In en, this message translates to:
  /// **'Pass counts'**
  String get passCounts;

  /// No description provided for @totalPasses.
  ///
  /// In en, this message translates to:
  /// **'Total passes'**
  String get totalPasses;

  /// No description provided for @uniqueLevelsCleared.
  ///
  /// In en, this message translates to:
  /// **'Unique levels cleared'**
  String get uniqueLevelsCleared;

  /// No description provided for @worldsFirstClears.
  ///
  /// In en, this message translates to:
  /// **'World\'s first clears'**
  String get worldsFirstClears;

  /// No description provided for @worldsFirstPPClears.
  ///
  /// In en, this message translates to:
  /// **'World\'s first PP clears'**
  String get worldsFirstPPClears;

  /// No description provided for @clears12k.
  ///
  /// In en, this message translates to:
  /// **'12K clears'**
  String get clears12k;

  /// No description provided for @clears16k.
  ///
  /// In en, this message translates to:
  /// **'16K clears'**
  String get clears16k;

  /// No description provided for @totalPurePerfects.
  ///
  /// In en, this message translates to:
  /// **'Total pure perfects'**
  String get totalPurePerfects;

  /// No description provided for @reclears.
  ///
  /// In en, this message translates to:
  /// **'Reclears'**
  String get reclears;

  /// No description provided for @judgements.
  ///
  /// In en, this message translates to:
  /// **'Judgements'**
  String get judgements;

  /// No description provided for @totalTilesHit.
  ///
  /// In en, this message translates to:
  /// **'Total tiles hit'**
  String get totalTilesHit;

  /// No description provided for @generalAccuracy.
  ///
  /// In en, this message translates to:
  /// **'General accuracy'**
  String get generalAccuracy;

  /// No description provided for @earlyVsLateBias.
  ///
  /// In en, this message translates to:
  /// **'Early vs late bias'**
  String get earlyVsLateBias;

  /// No description provided for @levelsCleared.
  ///
  /// In en, this message translates to:
  /// **'Levels cleared'**
  String get levelsCleared;

  /// No description provided for @totalTilecountCleared.
  ///
  /// In en, this message translates to:
  /// **'Total tilecount cleared'**
  String get totalTilecountCleared;

  /// No description provided for @estimatedPlaytime.
  ///
  /// In en, this message translates to:
  /// **'Estimated playtime'**
  String get estimatedPlaytime;

  /// No description provided for @avgBPMClearedLevels.
  ///
  /// In en, this message translates to:
  /// **'Avg BPM (cleared levels)'**
  String get avgBPMClearedLevels;

  /// No description provided for @rawSumOfAll.
  ///
  /// In en, this message translates to:
  /// **'Raw sum of all pass scores'**
  String get rawSumOfAll;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @firstPass.
  ///
  /// In en, this message translates to:
  /// **'First pass'**
  String get firstPass;

  /// No description provided for @latestPass.
  ///
  /// In en, this message translates to:
  /// **'Latest pass'**
  String get latestPass;

  /// No description provided for @bestAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Best accuracy'**
  String get bestAccuracy;

  /// No description provided for @worstAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Worst accuracy'**
  String get worstAccuracy;

  /// No description provided for @topSpeed.
  ///
  /// In en, this message translates to:
  /// **'Top speed'**
  String get topSpeed;

  /// No description provided for @highestTilecount.
  ///
  /// In en, this message translates to:
  /// **'Highest tilecount'**
  String get highestTilecount;

  /// No description provided for @longestLevel.
  ///
  /// In en, this message translates to:
  /// **'Longest level'**
  String get longestLevel;

  /// No description provided for @highestBPMCleared.
  ///
  /// In en, this message translates to:
  /// **'Highest BPM cleared'**
  String get highestBPMCleared;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @accountAgeDays.
  ///
  /// In en, this message translates to:
  /// **'Account age (days)'**
  String get accountAgeDays;

  /// No description provided for @passesLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Passes (last 30 days)'**
  String get passesLast30Days;

  /// No description provided for @levelsLiked.
  ///
  /// In en, this message translates to:
  /// **'Levels liked'**
  String get levelsLiked;

  /// No description provided for @packsOwned.
  ///
  /// In en, this message translates to:
  /// **'Packs owned'**
  String get packsOwned;

  /// No description provided for @packsFavorited.
  ///
  /// In en, this message translates to:
  /// **'Packs favorited'**
  String get packsFavorited;

  /// No description provided for @clearsByDifficultyType.
  ///
  /// In en, this message translates to:
  /// **'Clears by difficulty type'**
  String get clearsByDifficultyType;

  /// No description provided for @uniqueLevelsClearedTotal.
  ///
  /// In en, this message translates to:
  /// **'{unique} unique levels cleared ({total} total passes)'**
  String uniqueLevelsClearedTotal(Object unique, Object total);

  /// No description provided for @uniqueLevelsClearedCount.
  ///
  /// In en, this message translates to:
  /// **'{unique} unique levels cleared'**
  String uniqueLevelsClearedCount(Object unique);

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @aliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get aliases;

  /// No description provided for @teamsJoined.
  ///
  /// In en, this message translates to:
  /// **'Teams joined'**
  String get teamsJoined;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @levelsAsCharter.
  ///
  /// In en, this message translates to:
  /// **'Levels as charter'**
  String get levelsAsCharter;

  /// No description provided for @levelsAsVFX.
  ///
  /// In en, this message translates to:
  /// **'Levels as VFX'**
  String get levelsAsVFX;

  /// No description provided for @chartContent.
  ///
  /// In en, this message translates to:
  /// **'Chart content'**
  String get chartContent;

  /// No description provided for @tilesPlaced.
  ///
  /// In en, this message translates to:
  /// **'Tiles placed'**
  String get tilesPlaced;

  /// No description provided for @totalChartDuration.
  ///
  /// In en, this message translates to:
  /// **'Total chart duration'**
  String get totalChartDuration;

  /// No description provided for @avgTilecount.
  ///
  /// In en, this message translates to:
  /// **'Avg tilecount'**
  String get avgTilecount;

  /// No description provided for @avgLevelLength.
  ///
  /// In en, this message translates to:
  /// **'Avg level length'**
  String get avgLevelLength;

  /// No description provided for @avgBPM.
  ///
  /// In en, this message translates to:
  /// **'Avg BPM'**
  String get avgBPM;

  /// No description provided for @totalClearsOnCharts.
  ///
  /// In en, this message translates to:
  /// **'Total clears on charts'**
  String get totalClearsOnCharts;

  /// No description provided for @totalLikesOnCharts.
  ///
  /// In en, this message translates to:
  /// **'Total likes on charts'**
  String get totalLikesOnCharts;

  /// No description provided for @totalDownloadsOnCharts.
  ///
  /// In en, this message translates to:
  /// **'Total downloads on charts'**
  String get totalDownloadsOnCharts;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @uniquePlayersWhoCleared.
  ///
  /// In en, this message translates to:
  /// **'Unique players who cleared'**
  String get uniquePlayersWhoCleared;

  /// No description provided for @wfsOnCharts.
  ///
  /// In en, this message translates to:
  /// **'WF\'s on charts'**
  String get wfsOnCharts;

  /// No description provided for @wfPpsOnCharts.
  ///
  /// In en, this message translates to:
  /// **'WF PP\'s on charts'**
  String get wfPpsOnCharts;

  /// No description provided for @totalTilesHitOnCharts.
  ///
  /// In en, this message translates to:
  /// **'Total tiles hit'**
  String get totalTilesHitOnCharts;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @firstChart.
  ///
  /// In en, this message translates to:
  /// **'First chart'**
  String get firstChart;

  /// No description provided for @latestChart.
  ///
  /// In en, this message translates to:
  /// **'Latest chart'**
  String get latestChart;

  /// No description provided for @levelsByDifficultyType.
  ///
  /// In en, this message translates to:
  /// **'Levels by difficulty type'**
  String get levelsByDifficultyType;

  /// No description provided for @special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get special;

  /// No description provided for @topClear.
  ///
  /// In en, this message translates to:
  /// **'Top {letter} clear: {letter}{number} ({count}×)'**
  String topClear(Object letter, Object number, Object count);

  /// No description provided for @letterNoClears.
  ///
  /// In en, this message translates to:
  /// **'{letter}: no clears'**
  String letterNoClears(Object letter);

  /// No description provided for @qFromWorldsFirst.
  ///
  /// In en, this message translates to:
  /// **'{letter}Q{tier} from world\'s first {letter} clears ({count}×)'**
  String qFromWorldsFirst(Object letter, Object tier, Object count);

  /// No description provided for @qNoWorldsFirst.
  ///
  /// In en, this message translates to:
  /// **'{letter}Q: no world\'s first clears in this range'**
  String qNoWorldsFirst(Object letter);

  /// No description provided for @typeLevelCount.
  ///
  /// In en, this message translates to:
  /// **'{type} · {count} {count, plural, =1{level} other{levels}}'**
  String typeLevelCount(Object type, int count);

  /// No description provided for @unexpectedSearchResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected search response.'**
  String get unexpectedSearchResponse;

  /// No description provided for @noLevelField.
  ///
  /// In en, this message translates to:
  /// **'The response for level {id} has no level field.'**
  String noLevelField(Object id);

  /// No description provided for @unexpectedDifficultyListResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected difficulty list response.'**
  String get unexpectedDifficultyListResponse;

  /// No description provided for @listTag.
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get listTag;

  /// No description provided for @listCurationType.
  ///
  /// In en, this message translates to:
  /// **'curation type'**
  String get listCurationType;

  /// No description provided for @unexpectedListResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected {label} list response.'**
  String unexpectedListResponse(Object label);

  /// No description provided for @unexpectedPassResponseFor.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pass response for level {levelId}.'**
  String unexpectedPassResponseFor(Object levelId);

  /// No description provided for @unexpectedResponseForPass.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response for pass {id}.'**
  String unexpectedResponseForPass(Object id);

  /// No description provided for @unexpectedResponseForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response for player {id}.'**
  String unexpectedResponseForPlayer(Object id);

  /// No description provided for @unexpectedPassListResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pass list response.'**
  String get unexpectedPassListResponse;

  /// No description provided for @unexpectedLeaderboardResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected leaderboard response.'**
  String get unexpectedLeaderboardResponse;

  /// No description provided for @unexpectedCreatorListResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected creator list response.'**
  String get unexpectedCreatorListResponse;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player {id} not found.'**
  String playerNotFound(Object id);

  /// No description provided for @unexpectedPassResponseForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pass response for player {id}.'**
  String unexpectedPassResponseForPlayer(Object id);

  /// No description provided for @unexpectedRankHistoryResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected rank history response for player {id}.'**
  String unexpectedRankHistoryResponse(Object id);

  /// No description provided for @creatorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Creator {id} not found.'**
  String creatorNotFound(Object id);

  /// No description provided for @unexpectedPackListResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pack list response.'**
  String get unexpectedPackListResponse;

  /// No description provided for @unexpectedResponseForPack.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response for pack {id}.'**
  String unexpectedResponseForPack(Object id);

  /// No description provided for @serverNotResponding.
  ///
  /// In en, this message translates to:
  /// **'The server is not responding: {url}'**
  String serverNotResponding(Object url);

  /// No description provided for @downloadRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Download request failed: {url} ({error})'**
  String downloadRequestFailed(Object url, Object error);

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed: {path} ({error})'**
  String requestFailed(Object path, Object error);

  /// No description provided for @couldNotReadTheResponse.
  ///
  /// In en, this message translates to:
  /// **'Could not read the response: {path}'**
  String couldNotReadTheResponse(Object path);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @keyCount.
  ///
  /// In en, this message translates to:
  /// **'{count}K'**
  String keyCount(Object count);

  /// No description provided for @keys16.
  ///
  /// In en, this message translates to:
  /// **'16K'**
  String get keys16;

  /// No description provided for @keys12.
  ///
  /// In en, this message translates to:
  /// **'12K'**
  String get keys12;

  /// No description provided for @theServersDifficultyList.
  ///
  /// In en, this message translates to:
  /// **'The server\'s difficulty list has no PGU difficulties.'**
  String get theServersDifficultyList;

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// No description provided for @packs.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get packs;

  /// No description provided for @passes.
  ///
  /// In en, this message translates to:
  /// **'Passes'**
  String get passes;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @creators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creators;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System ({language})'**
  String systemLanguage(Object language);

  /// No description provided for @couldntLoadTheList.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list'**
  String get couldntLoadTheList;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try different filters.'**
  String get tryDifferentFilters;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @browsePassesFromEvery.
  ///
  /// In en, this message translates to:
  /// **'Browse passes from every player.'**
  String get browsePassesFromEvery;

  /// No description provided for @passCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{pass} other{passes}}'**
  String passCount(int count);

  /// No description provided for @noPassesFound.
  ///
  /// In en, this message translates to:
  /// **'No passes found'**
  String get noPassesFound;

  /// No description provided for @allPassesLoaded.
  ///
  /// In en, this message translates to:
  /// **'All passes loaded'**
  String get allPassesLoaded;

  /// No description provided for @searchBySongOr.
  ///
  /// In en, this message translates to:
  /// **'Search by song or player (#id to find a pass)'**
  String get searchBySongOr;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @dragTheSliderTo.
  ///
  /// In en, this message translates to:
  /// **'Drag the slider to set the range.'**
  String get dragTheSliderTo;

  /// No description provided for @includeSpecialDifficulties.
  ///
  /// In en, this message translates to:
  /// **'Include special difficulties'**
  String get includeSpecialDifficulties;

  /// No description provided for @keyCountFilter.
  ///
  /// In en, this message translates to:
  /// **'Key count'**
  String get keyCountFilter;

  /// No description provided for @worldsFirst.
  ///
  /// In en, this message translates to:
  /// **'World\'s first'**
  String get worldsFirst;

  /// No description provided for @gameVersion.
  ///
  /// In en, this message translates to:
  /// **'Game version'**
  String get gameVersion;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get resetAll;

  /// No description provided for @hiddenLevel.
  ///
  /// In en, this message translates to:
  /// **'Hidden level'**
  String get hiddenLevel;

  /// No description provided for @viewPlayerProfile.
  ///
  /// In en, this message translates to:
  /// **'View player profile'**
  String get viewPlayerProfile;

  /// No description provided for @findThePeopleWho.
  ///
  /// In en, this message translates to:
  /// **'Find the people who make levels by level count, clears, and curations.'**
  String get findThePeopleWho;

  /// No description provided for @creatorCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{creator} other{creators}}'**
  String creatorCount(int count);

  /// No description provided for @noCreatorsFound.
  ///
  /// In en, this message translates to:
  /// **'No creators found'**
  String get noCreatorsFound;

  /// No description provided for @allCreatorsLoaded.
  ///
  /// In en, this message translates to:
  /// **'All creators loaded'**
  String get allCreatorsLoaded;

  /// No description provided for @searchByCreatorName.
  ///
  /// In en, this message translates to:
  /// **'Search by creator name (or @account)'**
  String get searchByCreatorName;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationStatus;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @curationTypes.
  ///
  /// In en, this message translates to:
  /// **'Curation types'**
  String get curationTypes;

  /// No description provided for @onlyShowsCreatorsWith.
  ///
  /// In en, this message translates to:
  /// **'Only shows creators with levels of the chosen types.'**
  String get onlyShowsCreatorsWith;

  /// No description provided for @matchAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get matchAny;

  /// No description provided for @matchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get matchAll;

  /// No description provided for @noLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'No linked account'**
  String get noLinkedAccount;

  /// No description provided for @seePlayerRankingsBy.
  ///
  /// In en, this message translates to:
  /// **'See player rankings by score, passes, top difficulty, and more.'**
  String get seePlayerRankingsBy;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{player} other{players}}'**
  String playerCount(int count);

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get noPlayersFound;

  /// No description provided for @allPlayersLoaded.
  ///
  /// In en, this message translates to:
  /// **'All players loaded'**
  String get allPlayersLoaded;

  /// No description provided for @searchByPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Search by player name'**
  String get searchByPlayerName;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @topDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Top difficulty {difficulty}'**
  String topDifficulty(Object difficulty);

  /// No description provided for @loadingDifficulties.
  ///
  /// In en, this message translates to:
  /// **'Loading difficulties...'**
  String get loadingDifficulties;

  /// No description provided for @couldntConnectToThe.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the server'**
  String get couldntConnectToThe;

  /// No description provided for @findLevelsOnTUF.
  ///
  /// In en, this message translates to:
  /// **'Find levels on TUF and download them right away.'**
  String get findLevelsOnTUF;

  /// No description provided for @searchBySongArtist.
  ///
  /// In en, this message translates to:
  /// **'Search by song, artist, or creator'**
  String get searchBySongArtist;

  /// No description provided for @includeQDifficulties.
  ///
  /// In en, this message translates to:
  /// **'Include Q difficulties'**
  String get includeQDifficulties;

  /// No description provided for @noCurationTypes.
  ///
  /// In en, this message translates to:
  /// **'No curation types'**
  String get noCurationTypes;

  /// No description provided for @findByTheGrades.
  ///
  /// In en, this message translates to:
  /// **'Find by the grades curators gave.'**
  String get findByTheGrades;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @findByTheTags.
  ///
  /// In en, this message translates to:
  /// **'Find by the tags on a level.'**
  String get findByTheTags;

  /// No description provided for @clearedLevels.
  ///
  /// In en, this message translates to:
  /// **'Cleared levels'**
  String get clearedLevels;

  /// No description provided for @downloadable.
  ///
  /// In en, this message translates to:
  /// **'Downloadable'**
  String get downloadable;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get filterHide;

  /// No description provided for @filterOnly.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get filterOnly;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @includeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get includeAll;

  /// No description provided for @specialDifficulties.
  ///
  /// In en, this message translates to:
  /// **'Special difficulties'**
  String get specialDifficulties;

  /// No description provided for @selectedDifficultiesAreShown.
  ///
  /// In en, this message translates to:
  /// **'Selected difficulties are shown in the results too.'**
  String get selectedDifficultiesAreShown;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @levelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{level} other{levels}}'**
  String levelCount(int count);

  /// No description provided for @detailedView.
  ///
  /// In en, this message translates to:
  /// **'Detailed view'**
  String get detailedView;

  /// No description provided for @compactView.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get compactView;

  /// No description provided for @noLevelsMatch.
  ///
  /// In en, this message translates to:
  /// **'No levels match'**
  String get noLevelsMatch;

  /// No description provided for @tryADifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get tryADifferentSearch;

  /// No description provided for @allLevelsLoaded.
  ///
  /// In en, this message translates to:
  /// **'All levels loaded'**
  String get allLevelsLoaded;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @uniquePlayerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{player} other{players}}'**
  String uniquePlayerCount(int count);

  /// No description provided for @totalClearsSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count} total)'**
  String totalClearsSuffix(int count);

  /// No description provided for @couldntLoadPasses.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load passes'**
  String get couldntLoadPasses;

  /// No description provided for @noPassesYet.
  ///
  /// In en, this message translates to:
  /// **'No passes yet'**
  String get noPassesYet;

  /// No description provided for @firstClear.
  ///
  /// In en, this message translates to:
  /// **'First clear'**
  String get firstClear;

  /// No description provided for @highestScore.
  ///
  /// In en, this message translates to:
  /// **'Highest score'**
  String get highestScore;

  /// No description provided for @highestSpeed.
  ///
  /// In en, this message translates to:
  /// **'Highest speed'**
  String get highestSpeed;

  /// No description provided for @highestAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Highest accuracy'**
  String get highestAccuracy;

  /// No description provided for @totalClears.
  ///
  /// In en, this message translates to:
  /// **'Total clears'**
  String get totalClears;

  /// No description provided for @fullInfo.
  ///
  /// In en, this message translates to:
  /// **'Full info'**
  String get fullInfo;

  /// No description provided for @feeling.
  ///
  /// In en, this message translates to:
  /// **'Feeling {feeling}'**
  String feeling(Object feeling);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}}'**
  String itemCount(int count);

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @folderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{folder} other{folders}}'**
  String folderCount(int count);

  /// No description provided for @addedManuallyNotIn.
  ///
  /// In en, this message translates to:
  /// **'Added manually (not in the app\'s list)'**
  String get addedManuallyNotIn;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @sizeAndDownloadDate.
  ///
  /// In en, this message translates to:
  /// **'{size}  ·  downloaded {date}'**
  String sizeAndDownloadDate(Object size, Object date);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @organizeYourDownloadedLevels.
  ///
  /// In en, this message translates to:
  /// **'Organize your downloaded levels into folders and check for updates.'**
  String get organizeYourDownloadedLevels;

  /// No description provided for @levelCountAndSize.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{level} other{levels}}  ·  {size}'**
  String levelCountAndSize(int count, Object size);

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @updateAll.
  ///
  /// In en, this message translates to:
  /// **'Update all ({count})'**
  String updateAll(Object count);

  /// No description provided for @upBackspace.
  ///
  /// In en, this message translates to:
  /// **'Up (Backspace)'**
  String get upBackspace;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @openInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open in Explorer'**
  String get openInExplorer;

  /// No description provided for @changeLibraryFolder.
  ///
  /// In en, this message translates to:
  /// **'Change library folder'**
  String get changeLibraryFolder;

  /// No description provided for @refreshLibrary.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLibrary;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(Object count);

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveToFolder;

  /// No description provided for @selectAllItems.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAllItems;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @renameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameConfirm;

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteNamed(Object name);

  /// No description provided for @deleteItems.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{item} other{items}}?'**
  String deleteItems(int count);

  /// No description provided for @thisDeletesItFrom.
  ///
  /// In en, this message translates to:
  /// **'This deletes it from disk, including {count} {count, plural, =1{level} other{levels}} inside.'**
  String thisDeletesItFrom(int count);

  /// No description provided for @thisDeletesItFromDisk.
  ///
  /// In en, this message translates to:
  /// **'This deletes it from disk.'**
  String get thisDeletesItFromDisk;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @moveNamed.
  ///
  /// In en, this message translates to:
  /// **'Move \"{name}\"'**
  String moveNamed(Object name);

  /// No description provided for @moveItems.
  ///
  /// In en, this message translates to:
  /// **'Move {count} {count, plural, =1{item} other{items}}'**
  String moveItems(int count);

  /// No description provided for @noSubfolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders.'**
  String get noSubfolders;

  /// No description provided for @moveToRoot.
  ///
  /// In en, this message translates to:
  /// **'Move to root'**
  String get moveToRoot;

  /// No description provided for @moveHere.
  ///
  /// In en, this message translates to:
  /// **'Move here'**
  String get moveHere;

  /// No description provided for @noDownloadedLevelsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloaded levels yet'**
  String get noDownloadedLevelsYet;

  /// No description provided for @thisFolderIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get thisFolderIsEmpty;

  /// No description provided for @findLevelsYouLike.
  ///
  /// In en, this message translates to:
  /// **'Find levels you like in Levels and download them.'**
  String get findLevelsYouLike;

  /// No description provided for @dragLevelsHereOr.
  ///
  /// In en, this message translates to:
  /// **'Drag levels here, or create more folders inside.'**
  String get dragLevelsHereOr;

  /// No description provided for @browseLevels.
  ///
  /// In en, this message translates to:
  /// **'Browse levels'**
  String get browseLevels;

  /// No description provided for @levelPacks.
  ///
  /// In en, this message translates to:
  /// **'Level Packs'**
  String get levelPacks;

  /// No description provided for @browseLevelPacksMade.
  ///
  /// In en, this message translates to:
  /// **'Browse level packs made by the community and download them in one go, folders and all.'**
  String get browseLevelPacksMade;

  /// No description provided for @searchByPackName.
  ///
  /// In en, this message translates to:
  /// **'Search by pack name'**
  String get searchByPackName;

  /// No description provided for @packCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{pack} other{packs}}'**
  String packCount(int count);

  /// No description provided for @couldntLoadPacks.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load packs'**
  String get couldntLoadPacks;

  /// No description provided for @noPacksFound.
  ///
  /// In en, this message translates to:
  /// **'No packs found'**
  String get noPacksFound;

  /// No description provided for @trySearchingForA.
  ///
  /// In en, this message translates to:
  /// **'Try searching for a different name.'**
  String get trySearchingForA;

  /// No description provided for @allPacksLoaded.
  ///
  /// In en, this message translates to:
  /// **'All packs loaded'**
  String get allPacksLoaded;

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{more} more'**
  String moreCount(Object more);

  /// No description provided for @pinnedPack.
  ///
  /// In en, this message translates to:
  /// **'Pinned pack'**
  String get pinnedPack;

  /// No description provided for @likeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{like} other{likes}}'**
  String likeCount(int count);

  /// No description provided for @allPacks.
  ///
  /// In en, this message translates to:
  /// **'All packs'**
  String get allPacks;

  /// No description provided for @downloadPack.
  ///
  /// In en, this message translates to:
  /// **'Download pack'**
  String get downloadPack;

  /// No description provided for @downloadPackCount.
  ///
  /// In en, this message translates to:
  /// **'Download pack ({count})'**
  String downloadPackCount(Object count);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get collapseAll;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// No description provided for @itemAndLevelCount.
  ///
  /// In en, this message translates to:
  /// **'{items} {items, plural, =1{item} other{items}} · {levelCount} {levelCount, plural, =1{level} other{levels}}'**
  String itemAndLevelCount(int items, int levelCount);

  /// No description provided for @downloadFolderCount.
  ///
  /// In en, this message translates to:
  /// **'Download folder ({count})'**
  String downloadFolderCount(Object count);

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyFolder;

  /// No description provided for @allDownloaded.
  ///
  /// In en, this message translates to:
  /// **'All downloaded'**
  String get allDownloaded;

  /// No description provided for @downloadNamed.
  ///
  /// In en, this message translates to:
  /// **'Download \'{label}\''**
  String downloadNamed(Object label);

  /// No description provided for @downloadPackExplanation.
  ///
  /// In en, this message translates to:
  /// **'Downloads the {count} {count, plural, =1{level} other{levels}} you don\'t have yet, one by one.\nThey\'re saved in the \'{folder}\' folder of the library, in the same folder layout as the pack.\nLevels you already have are skipped and stay where they are.'**
  String downloadPackExplanation(int count, Object folder);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @failedCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' · {failedCount} failed'**
  String failedCountSuffix(Object failedCount);

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @stopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get stopping;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @couldntLoadThePack.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the pack contents'**
  String get couldntLoadThePack;

  /// No description provided for @thisPackIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This pack is empty'**
  String get thisPackIsEmpty;

  /// No description provided for @playersPass.
  ///
  /// In en, this message translates to:
  /// **'{player}\'s pass'**
  String playersPass(Object player);

  /// No description provided for @loadingScore.
  ///
  /// In en, this message translates to:
  /// **'Loading score...'**
  String get loadingScore;

  /// No description provided for @couldntLoadTheScore.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the score'**
  String get couldntLoadTheScore;

  /// No description provided for @topDifficultyCleared.
  ///
  /// In en, this message translates to:
  /// **'Top difficulty cleared'**
  String get topDifficultyCleared;

  /// No description provided for @worldsFirstClearCount.
  ///
  /// In en, this message translates to:
  /// **'{count} world\'s first {count, plural, =1{clear} other{clears}}'**
  String worldsFirstClearCount(int count);

  /// No description provided for @rankedScoreWithoutThis.
  ///
  /// In en, this message translates to:
  /// **'Ranked score without this pass'**
  String get rankedScoreWithoutThis;

  /// No description provided for @clearedOn.
  ///
  /// In en, this message translates to:
  /// **'Cleared {date}'**
  String clearedOn(Object date);

  /// No description provided for @overallRank.
  ///
  /// In en, this message translates to:
  /// **'Overall rank'**
  String get overallRank;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @feelingRating.
  ///
  /// In en, this message translates to:
  /// **'Feeling rating'**
  String get feelingRating;

  /// No description provided for @expectedRating.
  ///
  /// In en, this message translates to:
  /// **'Expected rating'**
  String get expectedRating;

  /// No description provided for @watchVideoInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Watch video in browser'**
  String get watchVideoInBrowser;

  /// No description provided for @leavingTUF.
  ///
  /// In en, this message translates to:
  /// **'Leaving TUF?'**
  String get leavingTUF;

  /// No description provided for @youAreAboutTo.
  ///
  /// In en, this message translates to:
  /// **'You are about to visit an external site. Only continue if you trust this destination.'**
  String get youAreAboutTo;

  /// No description provided for @trustForThisSession.
  ///
  /// In en, this message translates to:
  /// **'Trust {host} for this session'**
  String trustForThisSession(Object host);

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get proceed;

  /// No description provided for @openVideo.
  ///
  /// In en, this message translates to:
  /// **'Open video'**
  String get openVideo;

  /// No description provided for @loadingPasses.
  ///
  /// In en, this message translates to:
  /// **'Loading passes…'**
  String get loadingPasses;

  /// No description provided for @loadingLevels.
  ///
  /// In en, this message translates to:
  /// **'Loading levels…'**
  String get loadingLevels;

  /// No description provided for @tilesUnit.
  ///
  /// In en, this message translates to:
  /// **'tiles'**
  String get tilesUnit;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @noLevels.
  ///
  /// In en, this message translates to:
  /// **'No levels'**
  String get noLevels;

  /// No description provided for @totalLevels.
  ///
  /// In en, this message translates to:
  /// **'Total levels'**
  String get totalLevels;

  /// No description provided for @curatedLevels.
  ///
  /// In en, this message translates to:
  /// **'Curated levels'**
  String get curatedLevels;

  /// No description provided for @totalLevelClears.
  ///
  /// In en, this message translates to:
  /// **'Total level clears'**
  String get totalLevelClears;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @levelsByDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Levels by difficulty'**
  String get levelsByDifficulty;

  /// No description provided for @noPasses.
  ///
  /// In en, this message translates to:
  /// **'No passes'**
  String get noPasses;

  /// No description provided for @difficultiesCleared.
  ///
  /// In en, this message translates to:
  /// **'Difficulties cleared'**
  String get difficultiesCleared;

  /// No description provided for @rankedScore.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score'**
  String get rankedScore;

  /// No description provided for @averageXAcc.
  ///
  /// In en, this message translates to:
  /// **'Average X-acc'**
  String get averageXAcc;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScore;

  /// No description provided for @viewUsersPacks.
  ///
  /// In en, this message translates to:
  /// **'View user\'s packs'**
  String get viewUsersPacks;

  /// No description provided for @viewCreatorProfile.
  ///
  /// In en, this message translates to:
  /// **'View creator profile'**
  String get viewCreatorProfile;

  /// No description provided for @playerBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get playerBio;

  /// No description provided for @clearsByDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Clears by difficulty'**
  String get clearsByDifficulty;

  /// No description provided for @clearCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{clear} other{clears}}'**
  String clearCount(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @oneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get oneDayAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @followerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{follower} other{followers}}'**
  String followerCount(int count);

  /// No description provided for @alsoKnownAs.
  ///
  /// In en, this message translates to:
  /// **'Also known as: {aliases}'**
  String alsoKnownAs(Object aliases);

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @allStats.
  ///
  /// In en, this message translates to:
  /// **'All stats'**
  String get allStats;

  /// No description provided for @rankedScoreRank.
  ///
  /// In en, this message translates to:
  /// **'Ranked score rank'**
  String get rankedScoreRank;

  /// No description provided for @atHighestRankRight.
  ///
  /// In en, this message translates to:
  /// **'At highest rank right now!'**
  String get atHighestRankRight;

  /// No description provided for @highestRank.
  ///
  /// In en, this message translates to:
  /// **'Highest rank: #{rank} ({date})'**
  String highestRank(Object rank, Object date);

  /// No description provided for @unranked.
  ///
  /// In en, this message translates to:
  /// **'Unranked'**
  String get unranked;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @titleStats.
  ///
  /// In en, this message translates to:
  /// **'{title}\'s stats'**
  String titleStats(Object title);

  /// No description provided for @viewPass.
  ///
  /// In en, this message translates to:
  /// **'View pass'**
  String get viewPass;

  /// No description provided for @difficultyClearCount.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} · {count} {count, plural, =1{clear} other{clears}}'**
  String difficultyClearCount(Object difficulty, int count);

  /// No description provided for @levelUploadPermission.
  ///
  /// In en, this message translates to:
  /// **'Level upload permission'**
  String get levelUploadPermission;

  /// No description provided for @uploadConditions.
  ///
  /// In en, this message translates to:
  /// **'Upload conditions: {text}'**
  String uploadConditions(Object text);

  /// No description provided for @playerPassCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{pass} other{passes}}'**
  String playerPassCount(int count);

  /// No description provided for @searchBySongOrArtist.
  ///
  /// In en, this message translates to:
  /// **'Search by song or artist'**
  String get searchBySongOrArtist;

  /// No description provided for @hideReclears.
  ///
  /// In en, this message translates to:
  /// **'Hide reclears'**
  String get hideReclears;

  /// No description provided for @levelsSection.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsSection;

  /// No description provided for @creatorLevelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{level} other{levels}}'**
  String creatorLevelCount(int count);

  /// No description provided for @searchThisCreatorsLevels.
  ///
  /// In en, this message translates to:
  /// **'Search this creator\'s levels'**
  String get searchThisCreatorsLevels;

  /// No description provided for @tournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournaments;

  /// No description provided for @openPack.
  ///
  /// In en, this message translates to:
  /// **'Open pack'**
  String get openPack;

  /// No description provided for @placementCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{placement} other{placements}}'**
  String placementCount(int count);

  /// No description provided for @otherTournaments.
  ///
  /// In en, this message translates to:
  /// **'Other tournaments'**
  String get otherTournaments;

  /// No description provided for @scoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Score breakdown'**
  String get scoreBreakdown;

  /// No description provided for @includeDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Include duplicates'**
  String get includeDuplicates;

  /// No description provided for @couldntLoadRankHistory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load rank history'**
  String get couldntLoadRankHistory;

  /// No description provided for @noRankHistoryStored.
  ///
  /// In en, this message translates to:
  /// **'No rank history stored yet'**
  String get noRankHistoryStored;

  /// No description provided for @rankOverTime.
  ///
  /// In en, this message translates to:
  /// **'Rank over time'**
  String get rankOverTime;

  /// No description provided for @rankedScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Ranked score'**
  String get rankedScoreLine;

  /// No description provided for @generalScore.
  ///
  /// In en, this message translates to:
  /// **'General score'**
  String get generalScore;

  /// No description provided for @passesAboveCountToward.
  ///
  /// In en, this message translates to:
  /// **'Passes above count toward Ranked Score'**
  String get passesAboveCountToward;

  /// No description provided for @scoreOrMore.
  ///
  /// In en, this message translates to:
  /// **'{score}+'**
  String scoreOrMore(Object score);

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @pack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get pack;

  /// No description provided for @rankedScoreValue.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score {score}'**
  String rankedScoreValue(Object score);

  /// No description provided for @chartLevelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{level} other{levels}}'**
  String chartLevelCount(int count);

  /// No description provided for @couldntOpenTheLevel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the level'**
  String get couldntOpenTheLevel;

  /// No description provided for @couldntOpenThePass.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the pass'**
  String get couldntOpenThePass;

  /// No description provided for @theLevelOfThis.
  ///
  /// In en, this message translates to:
  /// **'The level of this pass is unknown.'**
  String get theLevelOfThis;

  /// No description provided for @couldntOpenThePack.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the pack.'**
  String get couldntOpenThePack;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHere;

  /// No description provided for @couldntOpenThePage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the page'**
  String get couldntOpenThePage;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @couldntLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more'**
  String get couldntLoadMore;

  /// No description provided for @expectedDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Expected difficulty: {difficulty}'**
  String expectedDifficulty(Object difficulty);

  /// No description provided for @curation.
  ///
  /// In en, this message translates to:
  /// **'Curation: {curation}'**
  String curation(Object curation);

  /// No description provided for @baseScoreOverridePP.
  ///
  /// In en, this message translates to:
  /// **'Base score override: {score} PP (used instead of the difficulty\'s base score)'**
  String baseScoreOverridePP(int score);

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @tileCount.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get tileCount;

  /// No description provided for @noCreatorInfo.
  ///
  /// In en, this message translates to:
  /// **'No creator info'**
  String get noCreatorInfo;

  /// No description provided for @clearedByPlayerTotal.
  ///
  /// In en, this message translates to:
  /// **'Cleared by {players} {players, plural, =1{player} other{players}} ({clears} total)'**
  String clearedByPlayerTotal(int players, int clears);

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get watchVideo;

  /// No description provided for @steamWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Steam Workshop'**
  String get steamWorkshop;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @levelFileSize.
  ///
  /// In en, this message translates to:
  /// **'Level file size'**
  String get levelFileSize;

  /// No description provided for @downloadToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Download to library'**
  String get downloadToLibrary;

  /// No description provided for @updateToTheNew.
  ///
  /// In en, this message translates to:
  /// **'Update to the new version'**
  String get updateToTheNew;

  /// No description provided for @alreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get alreadyDownloaded;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @noFileToDownload.
  ///
  /// In en, this message translates to:
  /// **'No file to download directly from TUF'**
  String get noFileToDownload;

  /// No description provided for @noLink.
  ///
  /// In en, this message translates to:
  /// **'No link'**
  String get noLink;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added: {date}'**
  String addedOn(Object date);

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @baseScore.
  ///
  /// In en, this message translates to:
  /// **'Base score'**
  String get baseScore;

  /// No description provided for @charters.
  ///
  /// In en, this message translates to:
  /// **'Charters'**
  String get charters;

  /// No description provided for @vfx.
  ///
  /// In en, this message translates to:
  /// **'VFX'**
  String get vfx;

  /// No description provided for @worldsFirstClearBadge.
  ///
  /// In en, this message translates to:
  /// **'World\'s First Clear!'**
  String get worldsFirstClearBadge;

  /// No description provided for @worldsFirstPurePerfect.
  ///
  /// In en, this message translates to:
  /// **'World\'s First Pure Perfect!'**
  String get worldsFirstPurePerfect;

  /// No description provided for @autoSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Auto-submitted'**
  String get autoSubmitted;

  /// No description provided for @submittedStraightFromThe.
  ///
  /// In en, this message translates to:
  /// **'Submitted straight from the game'**
  String get submittedStraightFromThe;

  /// No description provided for @noHold.
  ///
  /// In en, this message translates to:
  /// **'No Hold'**
  String get noHold;

  /// No description provided for @altHoldOption.
  ///
  /// In en, this message translates to:
  /// **'Alt. hold option'**
  String get altHoldOption;

  /// No description provided for @beforeTheEngineChange.
  ///
  /// In en, this message translates to:
  /// **'Before the engine change (up to v2.9.8).\nTiming engine issues made it less stable and precise.'**
  String get beforeTheEngineChange;

  /// No description provided for @beforeXPerfectUp.
  ///
  /// In en, this message translates to:
  /// **'Before X-Perfect (up to v3.3.1).'**
  String get beforeXPerfectUp;

  /// No description provided for @whatThisPassAdds.
  ///
  /// In en, this message translates to:
  /// **'What this pass adds to the ranked score'**
  String get whatThisPassAdds;

  /// No description provided for @doesntCountTowardThe.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t count toward the ranked score (what it could have added)'**
  String get doesntCountTowardThe;

  /// No description provided for @speedMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedMultiplier;

  /// No description provided for @clearSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clearSortRecent;

  /// No description provided for @clearSortScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get clearSortScore;

  /// No description provided for @clearSortAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get clearSortAccuracy;

  /// No description provided for @clearSortDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get clearSortDifficulty;

  /// No description provided for @clearSortSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get clearSortSpeed;

  /// No description provided for @clearSortKeyCount.
  ///
  /// In en, this message translates to:
  /// **'Key count'**
  String get clearSortKeyCount;

  /// No description provided for @clearSortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get clearSortRandom;

  /// No description provided for @keyCountFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get keyCountFilterAll;

  /// No description provided for @keyCountFilterK12.
  ///
  /// In en, this message translates to:
  /// **'12K'**
  String get keyCountFilterK12;

  /// No description provided for @keyCountFilterK16.
  ///
  /// In en, this message translates to:
  /// **'16K'**
  String get keyCountFilterK16;

  /// No description provided for @worldsFirstFilterNone.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get worldsFirstFilterNone;

  /// No description provided for @worldsFirstFilterWf.
  ///
  /// In en, this message translates to:
  /// **'WF'**
  String get worldsFirstFilterWf;

  /// No description provided for @worldsFirstFilterWfpp.
  ///
  /// In en, this message translates to:
  /// **'WF PP'**
  String get worldsFirstFilterWfpp;

  /// No description provided for @worldsFirstFilterEither.
  ///
  /// In en, this message translates to:
  /// **'Either'**
  String get worldsFirstFilterEither;

  /// No description provided for @worldsFirstFilterBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get worldsFirstFilterBoth;

  /// No description provided for @gameVersionFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gameVersionFilterAll;

  /// No description provided for @gameVersionFilterLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get gameVersionFilterLatest;

  /// No description provided for @gameVersionFilterPre340.
  ///
  /// In en, this message translates to:
  /// **'<3.4.0'**
  String get gameVersionFilterPre340;

  /// No description provided for @gameVersionFilterV2.
  ///
  /// In en, this message translates to:
  /// **'v2'**
  String get gameVersionFilterV2;

  /// No description provided for @leaderboardSortRankedScore.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score'**
  String get leaderboardSortRankedScore;

  /// No description provided for @leaderboardSortTotalScoreV2.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get leaderboardSortTotalScoreV2;

  /// No description provided for @leaderboardSortGeneralScore.
  ///
  /// In en, this message translates to:
  /// **'General Score'**
  String get leaderboardSortGeneralScore;

  /// No description provided for @leaderboardSortPpScore.
  ///
  /// In en, this message translates to:
  /// **'PP Score'**
  String get leaderboardSortPpScore;

  /// No description provided for @leaderboardSortWfScore.
  ///
  /// In en, this message translates to:
  /// **'WF Score'**
  String get leaderboardSortWfScore;

  /// No description provided for @leaderboardSortWfPPScore.
  ///
  /// In en, this message translates to:
  /// **'WF PP Score'**
  String get leaderboardSortWfPPScore;

  /// No description provided for @leaderboardSortScore12K.
  ///
  /// In en, this message translates to:
  /// **'12K Score'**
  String get leaderboardSortScore12K;

  /// No description provided for @leaderboardSortAverageXacc.
  ///
  /// In en, this message translates to:
  /// **'Average X-acc'**
  String get leaderboardSortAverageXacc;

  /// No description provided for @leaderboardSortTotalPasses.
  ///
  /// In en, this message translates to:
  /// **'Total Passes'**
  String get leaderboardSortTotalPasses;

  /// No description provided for @leaderboardSortUniversalPassCount.
  ///
  /// In en, this message translates to:
  /// **'Universal Passes'**
  String get leaderboardSortUniversalPassCount;

  /// No description provided for @leaderboardSortWorldsFirstCount.
  ///
  /// In en, this message translates to:
  /// **'WF Passes'**
  String get leaderboardSortWorldsFirstCount;

  /// No description provided for @leaderboardSortWorldsFirstPPCount.
  ///
  /// In en, this message translates to:
  /// **'WF PP Passes'**
  String get leaderboardSortWorldsFirstPPCount;

  /// No description provided for @leaderboardSortTopDiff.
  ///
  /// In en, this message translates to:
  /// **'Top Difficulty'**
  String get leaderboardSortTopDiff;

  /// No description provided for @leaderboardSortTop12kDiff.
  ///
  /// In en, this message translates to:
  /// **'Top 12K Difficulty'**
  String get leaderboardSortTop12kDiff;

  /// No description provided for @creatorSortChartsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Levels'**
  String get creatorSortChartsTotal;

  /// No description provided for @creatorSortChartsCharted.
  ///
  /// In en, this message translates to:
  /// **'Levels Charted'**
  String get creatorSortChartsCharted;

  /// No description provided for @creatorSortChartsVfxed.
  ///
  /// In en, this message translates to:
  /// **'Levels VFX\'d'**
  String get creatorSortChartsVfxed;

  /// No description provided for @creatorSortChartsTeamed.
  ///
  /// In en, this message translates to:
  /// **'Levels as a team member'**
  String get creatorSortChartsTeamed;

  /// No description provided for @creatorSortTotalChartClears.
  ///
  /// In en, this message translates to:
  /// **'Total Level Clears'**
  String get creatorSortTotalChartClears;

  /// No description provided for @creatorSortTotalChartLikes.
  ///
  /// In en, this message translates to:
  /// **'Total Level Likes'**
  String get creatorSortTotalChartLikes;

  /// No description provided for @creatorSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get creatorSortName;

  /// No description provided for @packSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get packSortRecent;

  /// No description provided for @packSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get packSortName;

  /// No description provided for @packSortLevels.
  ///
  /// In en, this message translates to:
  /// **'Level Count'**
  String get packSortLevels;

  /// No description provided for @packSortFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get packSortFavorites;

  /// No description provided for @judgementTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too Early'**
  String get judgementTooEarly;

  /// No description provided for @judgementEarly.
  ///
  /// In en, this message translates to:
  /// **'Early!'**
  String get judgementEarly;

  /// No description provided for @judgementEarlyPerfect.
  ///
  /// In en, this message translates to:
  /// **'EPerfect'**
  String get judgementEarlyPerfect;

  /// No description provided for @judgementPerfectMinus.
  ///
  /// In en, this message translates to:
  /// **'Perfect−'**
  String get judgementPerfectMinus;

  /// No description provided for @judgementPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get judgementPerfect;

  /// No description provided for @judgementPerfectPlus.
  ///
  /// In en, this message translates to:
  /// **'Perfect+'**
  String get judgementPerfectPlus;

  /// No description provided for @judgementLatePerfect.
  ///
  /// In en, this message translates to:
  /// **'LPerfect'**
  String get judgementLatePerfect;

  /// No description provided for @judgementLate.
  ///
  /// In en, this message translates to:
  /// **'Late!'**
  String get judgementLate;

  /// No description provided for @judgementTooLate.
  ///
  /// In en, this message translates to:
  /// **'Too Late'**
  String get judgementTooLate;

  /// No description provided for @playerScoreRankedScore.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score'**
  String get playerScoreRankedScore;

  /// No description provided for @playerScoreRankedScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Decaying sum of 20 best clears (excluding reclears)'**
  String get playerScoreRankedScoreDescription;

  /// No description provided for @playerScoreTotalScoreV2.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get playerScoreTotalScoreV2;

  /// No description provided for @playerScoreTotalScoreV2Description.
  ///
  /// In en, this message translates to:
  /// **'Sum of all clears without reclears'**
  String get playerScoreTotalScoreV2Description;

  /// No description provided for @playerScoreGeneralScore.
  ///
  /// In en, this message translates to:
  /// **'General Score'**
  String get playerScoreGeneralScore;

  /// No description provided for @playerScoreGeneralScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Sum of all clears including reclears'**
  String get playerScoreGeneralScoreDescription;

  /// No description provided for @playerScorePpScore.
  ///
  /// In en, this message translates to:
  /// **'PP Score'**
  String get playerScorePpScore;

  /// No description provided for @playerScorePpScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score, but all clears must also be pure perfects'**
  String get playerScorePpScoreDescription;

  /// No description provided for @playerScoreWfScore.
  ///
  /// In en, this message translates to:
  /// **'WF Score'**
  String get playerScoreWfScore;

  /// No description provided for @playerScoreWfScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Sum of all level base scores from world\'s first passes'**
  String get playerScoreWfScoreDescription;

  /// No description provided for @playerScoreWfPPScore.
  ///
  /// In en, this message translates to:
  /// **'WF PP Score'**
  String get playerScoreWfPPScore;

  /// No description provided for @playerScoreWfPPScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Sum of all level base scores from world\'s first pure perfect passes'**
  String get playerScoreWfPPScoreDescription;

  /// No description provided for @playerScoreScore12K.
  ///
  /// In en, this message translates to:
  /// **'12K Score'**
  String get playerScoreScore12K;

  /// No description provided for @playerScoreScore12KDescription.
  ///
  /// In en, this message translates to:
  /// **'Ranked Score, but all clears must be 12K'**
  String get playerScoreScore12KDescription;

  /// No description provided for @playerScoreAverageXacc.
  ///
  /// In en, this message translates to:
  /// **'Average X-acc'**
  String get playerScoreAverageXacc;

  /// No description provided for @playerScoreAverageXaccDescription.
  ///
  /// In en, this message translates to:
  /// **'Average accuracy of top 20 passes'**
  String get playerScoreAverageXaccDescription;

  /// No description provided for @creatorVerificationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get creatorVerificationAllowed;

  /// No description provided for @creatorVerificationConditional.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get creatorVerificationConditional;

  /// No description provided for @creatorVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get creatorVerificationPending;

  /// No description provided for @creatorVerificationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get creatorVerificationDeclined;

  /// No description provided for @playerPassSortScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get playerPassSortScore;

  /// No description provided for @playerPassSortImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get playerPassSortImpact;

  /// No description provided for @playerPassSortSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerPassSortSpeed;

  /// No description provided for @playerPassSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get playerPassSortDate;

  /// No description provided for @playerPassSortXacc.
  ///
  /// In en, this message translates to:
  /// **'X-Accuracy'**
  String get playerPassSortXacc;

  /// No description provided for @playerPassSortDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get playerPassSortDifficulty;

  /// No description provided for @rankRangeDays30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get rankRangeDays30;

  /// No description provided for @rankRangeDays90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get rankRangeDays90;

  /// No description provided for @rankRangeDays365.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get rankRangeDays365;

  /// No description provided for @rankRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rankRangeAll;

  /// No description provided for @levelSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Newest (ID)'**
  String get levelSortRecent;

  /// No description provided for @levelSortDiff.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get levelSortDiff;

  /// No description provided for @levelSortClears.
  ///
  /// In en, this message translates to:
  /// **'Clears'**
  String get levelSortClears;

  /// No description provided for @levelSortTotalClears.
  ///
  /// In en, this message translates to:
  /// **'Total clears'**
  String get levelSortTotalClears;

  /// No description provided for @levelSortLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get levelSortLikes;

  /// No description provided for @levelSortBaseScore.
  ///
  /// In en, this message translates to:
  /// **'Base score'**
  String get levelSortBaseScore;

  /// No description provided for @levelSortBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get levelSortBpm;

  /// No description provided for @levelSortTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get levelSortTiles;

  /// No description provided for @levelSortTime.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get levelSortTime;

  /// No description provided for @levelSortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get levelSortRandom;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @extra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extra;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @lowestDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Lowest difficulty'**
  String get lowestDifficulty;

  /// No description provided for @highestDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Highest difficulty'**
  String get highestDifficulty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
