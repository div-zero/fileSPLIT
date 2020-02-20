; -- fileSPLIT.iss --

#define APP_NAME "fileSPLIT"
#define APP_VER "2.02"

[Setup]
AppVerName={#APP_NAME} {#APP_VER}
OutputBaseFilename={#APP_NAME}-{#APP_VER}_setup

AppName={#APP_NAME}
AppCopyright=copyright (C) 2020 by Matthias Jung, intelli-bit
DefaultDirName={commonpf32}\intelli-bit\{#APP_NAME}
DefaultGroupName=intelli-bit\{#APP_NAME}
OutputDir=..\..\..\#Setup

AlwaysUsePersonalGroup=yes
ChangesAssociations=no

DisableDirPage=no
DisableStartupPrompt=yes
DisableReadyPage=yes
DisableProgramGroupPage=yes
DisableReadyMemo=yes

Uninstallable=yes
UninstallDisplayIcon={app}\fileSPLIT.exe


[Files]
Source: "..\..\..\#Bin\fileSPLIT\fileSPLIT.exe"; DestDir: "{app}"
Source: "..\..\__Deploy\fileSPLIT\Doc\*"; DestDir: "{app}\Doc"

[Icons]
Name: "{group}\fileSPLIT"; Filename: "{app}\fileSPLIT.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\fileSPLIT"; Filename: "{app}\fileSPLIT.exe"; WorkingDir: "{app}"


