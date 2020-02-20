unit shellTools;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

type
  TSpecialFolder =
  (
    sfMyDesktopDirectory,
    sfMyDocuments,
    sfMyAppData,
    sfMyLocalAppData,
    sfCommonDocuments,
    sfCommonAppData,
    sfProgramFiles,
    sfProgramFilesCommon,
    sfSystem,
    sfWindows
  );

function _shellBrowseForFolder
(
  Handle: Integer;
  Caption: string;
  var strFolder: string;
  fMayCreateNewFolder: boolean = False
): Boolean;

function _shellGetSpecialFolderPath( sf: TSpecialFolder ): string;


implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  Windows,
  SysUtils,
  ShlObj,
  SHFolder,
  strTools;

(* ////////////////////////////////////////////////////////////////////////// *)
function BrowseCallbackProc( hwnd: HWND; uMsg: UINT; lParam: LPARAM; lpData: LPARAM ): Integer; stdcall;
begin
  if( uMsg = BFFM_INITIALIZED ) then
    SendMessage( hwnd, BFFM_SETSELECTION, 1, lpData );
  BrowseCallbackProc := 0;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _shellBrowseForFolder
(
  Handle: Integer;
  Caption: string;
  var strFolder: string;
  fMayCreateNewFolder: boolean = False
): Boolean;
const
  BIF_STATUSTEXT           = $0004;
  BIF_NEWDIALOGSTYLE       = $0040;
  BIF_RETURNONLYFSDIRS     = $0080;
  BIF_SHAREABLE            = $0100;
  BIF_USENEWUI             = BIF_EDITBOX or BIF_NEWDIALOGSTYLE;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  JtemIDList: PItemIDList;
  Path: PChar;
begin
  Result := False;
  Path := StrAlloc( 2 * MAX_PATH );
  SHGetSpecialFolderLocation( Handle, CSIDL_DRIVES, JtemIDList );
  with BrowseInfo do
  begin
    hwndOwner := Handle;
    pidlRoot := JtemIDList;
    SHGetSpecialFolderLocation( Handle, CSIDL_DRIVES, JtemIDList );

    { return display name of item selected }
    pszDisplayName := StrAlloc( 2 * MAX_PATH );

    { set the title of dialog }
    lpszTitle := PChar( Caption );
    { flags that control the return stuff }
    lpfn := @BrowseCallbackProc;
    { extra info that's passed back in callbacks }
    lParam := LongInt( PChar( strFolder ) );

    ulFlags := BIF_NEWDIALOGSTYLE;
    if not fMayCreateNewFolder then
      ulFlags := ulFlags or BIF_NONEWFOLDERBUTTON;
  end;

  ItemIDList := SHBrowseForFolder( BrowseInfo );

  if( ItemIDList <> nil ) then
  begin
    if SHGetPathFromIDList( ItemIDList, Path ) then
    begin
      strFolder := Path;
      Result := True
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _shellGetSpecialFolderPath( sf: TSpecialFolder ): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
  iFolder: integer;
begin
  Result := '';
  iFolder := 0;

  case sf of
    sfMyDesktopDirectory:
      // [Current User]\Desktop
      iFolder := CSIDL_DESKTOPDIRECTORY;

    sfMyDocuments:
      // [Current User]\My Documents
      iFolder := CSIDL_MYDOCUMENTS;

    sfCommonDocuments:
      // All Users\Documents
      iFolder := CSIDL_COMMON_DOCUMENTS;

    sfMyAppData:
      // [Current User]\Application Data
      iFolder := CSIDL_APPDATA;

    sfCommonAppData:
      // All Users\Application Data
      iFolder := CSIDL_COMMON_APPDATA;

    sfMyLocalAppData:
      // [Current User]\Local Settings\Application Data
      iFolder := CSIDL_LOCAL_APPDATA;

    sfProgramFiles:
      // Program Files
      iFolder := CSIDL_PROGRAM_FILES;

    sfProgramFilesCommon:
      iFolder := CSIDL_PROGRAM_FILES_COMMON;

    sfSystem:
      iFolder := CSIDL_SYSTEM;

    sfWindows:
      iFolder := CSIDL_WINDOWS;
    end;

  if SUCCEEDED( SHGetFolderPath( 0, iFolder, 0, SHGFP_TYPE_CURRENT, @path[0] ) ) then
    Result := _strDeleteLastSlash( path );
end;


(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.

