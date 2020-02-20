; -- fileSPLIT_portable.iss --

#define APP_NAME "fileSPLIT"
#define APP_VER "2.02"

[Setup]
AppVerName={#APP_NAME} {#APP_VER} (portable)
OutputBaseFilename={#APP_NAME}-{#APP_VER}-portable_setup

AppName={#APP_NAME} (portable)
AppCopyright=copyright (C) 2020 by Matthias Jung, intelli-bit
DefaultDirName={sd}\intelli-bit\{#APP_NAME}
DefaultGroupName=intelli-bit\{#APP_NAME}
OutputDir=..\..\..\#Setup

AlwaysUsePersonalGroup=yes
ChangesAssociations=no

DisableDirPage=no
DisableStartupPrompt=yes
DisableReadyPage=yes
DisableProgramGroupPage=yes
DisableReadyMemo=yes

Uninstallable=no
UninstallDisplayIcon={app}\fileSPLIT.exe


[Files]
Source: "..\..\..\#Bin\fileSPLIT\fileSPLIT.exe"; DestDir: "{app}"
Source: "..\..\__Deploy\_Location\location.portable.txt"; DestDir: "{app}"
Source: "..\..\__Deploy\fileSPLIT\Doc\*"; DestDir: "{app}\Doc"

