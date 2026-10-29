# TUFApp

An unofficial Windows app for browsing and downloading ADOFAI custom levels and packs from [The Universal Forums](https://tuforums.com).

- Search levels, packs, passes, leaderboard and creators
- One-click download into your ADOFAI custom level folder
- Manage downloaded levels and check for updates

## Build

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/desktop) and Visual Studio 2022 (Desktop development with C++).

```bash
flutter pub get
flutter build windows --release
```

### Installer

With [Inno Setup 6](https://jrsoftware.org/isinfo.php) installed, this builds the app and packs it into `installer\Output\TUFApp-Setup-<version>.exe`:

```bash
powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1
```

The installer includes the Visual C++ runtime, so it runs on PCs without the redistributable. It installs for the current user without administrator rights, or for all users if chosen.

## Translations

UI text lives in `lib/l10n/app_<language code>.arb`, with English (`app_en.arb`) as the template. To add a language, copy `app_en.arb` to e.g. `app_ja.arb`, set `@@locale`, translate the values and rebuild; it then appears in the language menu. Messages left untranslated fall back to English.

## References

TUFApp uses the public TUF API and follows the TUF website's behavior and wording, referencing [T21C/t21c-web-frontend](https://github.com/T21C/t21c-web-frontend) (UI layout, display rules such as creator names, accuracy and tag outlines, Korean/English wording).

No source code from that project is included in this repository.

## License

TUFApp is licensed under the [GNU General Public License v3.0](LICENSE).

Third-party components keep their own licenses:

- [Flutter](https://github.com/flutter/flutter) and Dart packages (`http`, `intl`, `path`, `path_provider`, `url_launcher`, `file_selector`, `ffi`, `webview_windows`): BSD-3-Clause
- `archive`, `cupertino_icons`: MIT
- [Roboto](https://fonts.google.com/specimen/Roboto) font: SIL Open Font License 1.1 ([`assets/fonts/OFL.txt`](assets/fonts/OFL.txt))
- [Font Awesome Free](https://fontawesome.com/license/free) icons via `font_awesome_flutter`: icons CC BY 4.0, font SIL OFL 1.1, package MIT
- Microsoft Visual C++ runtime DLLs (in the installer): redistributed under the Visual Studio license terms

## Disclaimer

TUFApp is not created nor approved by 7th Beat Games or the TUF Dev Team. The TUF name and logo, level data and images belong to TUF and the level creators, and are not covered by this project's license. *A Dance of Fire and Ice* is a trademark of 7th Beat Games.
