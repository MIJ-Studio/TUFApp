; TUFApp installer script for Inno Setup 6.
; Build it with tool\build_installer.ps1, which builds the app and passes AppVersion and VcRuntimeDir.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef VcRuntimeDir
  #error VcRuntimeDir is not set. Build with tool\build_installer.ps1.
#endif

#define AppName "TUFApp"
#define AppExe "tufapp.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; Keeps upgrades and uninstalls tied to this app. Never change it.
AppId={{2EDD0E8D-D448-4420-825E-A9C0EB68CED6}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=MAIJEUN
AppPublisherURL=https://github.com/MAIJEUN/TUFApp
AppSupportURL=https://github.com/MAIJEUN/TUFApp/issues
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
; Installs for the current user without administrator rights (in %LocalAppData%\Programs);
; the first page lets the user install for all users instead.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=Output
OutputBaseFilename=TUFApp-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
; Asks to close a running TUFApp before replacing its files.
CloseApplications=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
#if FileExists(CompilerPath + "Languages\Korean.isl")
Name: "ko"; MessagesFile: "compiler:Languages\Korean.isl"
#endif

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Assets of an older version must not linger next to the new ones.
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Excludes: "*.lnk,*.pdb"; Flags: ignoreversion recursesubdirs createallsubdirs
; The Visual C++ runtime sits next to the app, so PCs without the redistributable installed can still run it.
Source: "{#VcRuntimeDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcRuntimeDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcRuntimeDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
