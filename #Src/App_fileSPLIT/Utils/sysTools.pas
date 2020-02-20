unit sysTools;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

uses
  Windows,
  SysUtils;

const
  SHOW_WINDOW_TYPES: array[0..11] of string =
  ('HIDE',
   'NORMAL',              // 1
   'MINIMIZED',           // 2
   'MAXIMIZE',            // 3
   'NOACTIVATE',          // 4
   'SHOW',                // 5
   'MINIMIZE',            // 6
   'MINNOACTIVE',         // 7
   'SHOWNA',              // 8
   'RESTORE',             // 9
   'SHOWDEFAULT',         // 10
   'FORCEMINIMIZE');      // 11

type
  EInvalidPeriod = class( Exception );

function _sysModuleFullName: string;
function _sysModuleName: string;
function _sysModulePath: string;

function _sysTempFile( strPath: string ): string; overload;
function _sysTempFile( strPath, strPrefix: string ): string; overload;
function _sysSystemGlobalTempFolder: string;

function _sysFileSize( strFileName: string ): longint;
function _sysCanAccess( strFileName: string; wFileOpenMode: LongWord ): boolean;

function _sysExecuteSynchron( strCmdLine: string; Visibility: Integer; fProcessMessages: boolean = False ): LongBool;
function _sysWinExecAndWait( strCmdLine: string; Visibility: Integer ): DWORD;
function _sysWinExec( strCmdLine: string; Visibility: Integer; fWait: boolean = False ): DWORD;

function _sysCurrentUser: string;
procedure _sysSendString( hSource, hTarget: THandle; idMsg: longint; strMsg: string );
function _sysDateDiff( Period: Word; Date2, Date1: TDatetime ): longint;

function _sysIsUnique( strId: string ): boolean;
procedure _sysDelay( iMilliseconds: Integer );
procedure _sysAddLog( strLogFile, strLogMsg: string );

function _sysIsHit( iWidth, iHeight: integer; MousePos: TPoint ): boolean;

function _sysExpandPath( strPath: string ): string;

function _sysIsAltDown : boolean;
function _sysIsCtrlDown : boolean;
function _sysIsShiftDown : boolean;


implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  Messages,
  Vcl.Forms,
  IniFiles,
  strTools;

type
  PTokenUser = ^TTokenUser;
  _TOKEN_USER = record
    User: TSIDAndAttributes;
  end;
  TTokenUser = _TOKEN_USER;

var
  _hUniqueMutex: THandle;
  _strWorkPath: string;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysModuleFullName: string;
var
  szFileName: array[0..MAX_PATH] of Char;
begin
  FillChar( szFileName, SizeOf(szFileName), #0 );
  GetModuleFileName( hInstance, szFileName, MAX_PATH );
  Result := szFileName;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysModuleName: string;
begin
  Result := extractFileName( _sysModuleFullName );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysModulePath: string;
begin
  Result := extractFilePath( _sysModuleFullName );
  Result := _strDeleteLastSlash( Result );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysTempFile( strPath: string ): string;
begin
  Result := _sysTempFile( strPath, '' );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysTempFile( strPath, strPrefix: string ): string;
begin
  SetLength( Result, MAX_PATH );
  Windows.GetTempFileName( PChar( strPath ), PChar( strPrefix ), 0, PChar( Result ) );
  SetLength( Result, StrLen( PChar( Result ) ) );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysSystemGlobalTempFolder: string;
var
  tempFolder: array[0..MAX_PATH] of char;
begin
  GetTempPath( MAX_PATH, @tempFolder );
  Result := StrPas( tempFolder );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysFileSizeA( strFileName: string ): longint;
var
  f: file of byte;
begin
  assignFile( f, strFileName );
  reset( f );
  Result := fileSize( f );
  closeFile( f );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysFileSize( strFileName: string ): longint;
var
  sr: TSearchRec;
begin
  Result := 0;
  if( 0 = findFirst( strFileName, faAnyFile, sr ) ) then
    Result := sr.Size;
  findClose( sr );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysCanAccess( strFileName: string; wFileOpenMode: LongWord ): boolean;
var
  hFile: longint;
begin
  Result := False;
  hFile := fileOpen( strFileName, wFileOpenMode );
  if( hFile >= 0 ) then
  begin
    fileClose( hFile );
    Result := True;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysWinExecAndWait(strCmdLine: string; Visibility: Integer): DWORD;
begin
  Result := _sysWinExec( strCmdLine, Visibility, True );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysExecuteSynchron( strCmdLine: string; Visibility: Integer; fProcessMessages: boolean = False ): LongBool;
var
  zCmdLine: array[0..512] of char;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  WaitResult: DWORD;
begin
  FillChar( ProcessInfo, SizeOf( ProcessInfo ), #0 );
  FillChar( StartupInfo, SizeOf( StartupInfo ), #0 );
  StartupInfo.cb := SizeOf( StartupInfo );
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;

  StrPCopy( zCmdLine, strCmdLine );

  Result := CreateProcess
  (
    nil,
    zCmdLine,                { pointer to command line string }
    nil,                     { pointer to process security attributes }
    nil,                     { pointer to thread security attributes }
    False,                   { handle inheritance flag }
    NORMAL_PRIORITY_CLASS,
    nil,                     { pointer to new environment block }
    nil,                     { pointer to current directory name }
    StartupInfo,             { pointer to STARTUPINFO }
    ProcessInfo              { pointer to PROCESS_INF }
  );

  repeat
    WaitResult := WaitForSingleObject( ProcessInfo.hProcess, 0 );
    if( fProcessMessages ) then
      Application.ProcessMessages;
  until WaitResult <> 258;

  CloseHandle( ProcessInfo.hProcess );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysWinExec( strCmdLine: string; Visibility: Integer; fWait: boolean = False ): DWORD;

  procedure WaitFor( processHandle: THandle );
  var
    Msg: TMsg;
    ret: DWORD;
  begin
    repeat
      ret := MsgWaitForMultipleObjects
      (
        1, { 1 handle to wait on }
        processHandle, { the handle }
        False, { wake on any event }
        INFINITE, { wait without timeout }
        QS_PAINT or { wake on paint messages }
        QS_SENDMESSAGE { or messages from other threads }
      );
      if ret = WAIT_FAILED then Exit; { can do little here }
      if ret = ( WAIT_OBJECT_0 + 1 ) then
      begin
          { Woke on a message, process paint messages only. Calling
            PeekMessage gets messages send from other threads processed. }
        while PeekMessage( Msg, 0, WM_PAINT, WM_PAINT, PM_REMOVE ) do
          DispatchMessage( Msg );
      end;
    until ret = WAIT_OBJECT_0;
  end; { Waitfor }

var { V1 by Pat Ritchey, V2 by P.Below }
  zCmdLine: array[0..512] of char;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin { WinExecAndWait32V2 }
  StrPCopy( zCmdLine, strCmdLine );
  FillChar(StartupInfo, SizeOf( StartupInfo ), #0 );
  StartupInfo.cb := SizeOf( StartupInfo );
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess
  (
    nil,
    zCmdLine, { pointer to command line string }
    nil, { pointer to process security attributes }
    nil, { pointer to thread security attributes }
    False, { handle inheritance flag }
    CREATE_NEW_CONSOLE or { creation flags }
    NORMAL_PRIORITY_CLASS,
    nil, { pointer to new environment block }
    nil, { pointer to current directory name }
    StartupInfo, { pointer to STARTUPINFO }
    ProcessInfo { pointer to PROCESS_INF }
  ) then
    Result := DWORD(-1) { failed, GetLastError has error code }
  else
  begin
    if( fWait ) then
    begin
      Waitfor( ProcessInfo.hProcess );
      GetExitCodeProcess( ProcessInfo.hProcess, Result );
    end;

    CloseHandle( ProcessInfo.hProcess );
    CloseHandle( ProcessInfo.hThread );
  end; { Else }
end; { WinExecAndWait32V2 }

(* ////////////////////////////////////////////////////////////////////////// *)
procedure _sysSendString( hSource, hTarget: THandle; idMsg: longint; strMsg: string );
var
  CopyData: TCopyDataStruct;
  buf: array[0..255] of char;
begin
  if( hTarget <> 0 ) then
  begin
    FillChar( buf, SizeOf( buf ), #0 );
    StrCopy( buf, PChar( strMsg ) );

    CopyData.dwData := idMsg;
    CopyData.cbData := strlen( buf ) + 1;
    CopyData.lpData := @buf;

    SendMessage( hTarget, WM_COPYDATA, hSource, longint( @CopyData ) );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysCurrentUser: string;
var
  buf: array[0..255] of char;
  iSize: Cardinal;
begin
  iSize := SizeOf( buf );
  FillChar( buf, iSize, #0 );
  Windows.GetUserName( buf, iSize );
  Result := buf;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
Function _sysDateDiff( Period: Word; Date2, Date1: TDateTime ): longint;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;  //These are for Date 1
  Year1, Month1, Day1, Hour1, Min1, Sec1, MSec1: Word; //these are for Date 2
begin
 //Decode Dates Before Starting
 //This is probably ineficient but it will save doing it for each
 //different Period.
 DecodeDate(Date1, Year, Month, Day);
 DecodeDate(Date2, Year1, Month1, Day1);
 DecodeTime(Date1, Hour, Min, Sec, MSec);
 DecodeTime(Date2, Hour1, Min1, Sec1, MSec1);

 //Once Decoded Select Type of DateDiff To Return via Period Parameter
  case Period of
    1:  //Seconds
    begin
      //first work out days then * days by 86400 (mins in day)
      //Then minus the difference in hours * 3600
      //then minus the difference in minutes * 60
      //Then get the difference in seconds
      Result := (((((Trunc(Date1) - Trunc(Date2))* 86400) - ((Hour1 - Hour)* 3600))) - ((Min1 - Min) * 60)) - (Sec1 - Sec);
    end;
    2: //Minutes
    begin
      //first work out days then * days by 1440 (mins in day)
      //Then minus the difference in hours * 60
      //then minus the difference in minutes
      Result := (((Trunc(Date1) - Trunc(Date2))* 1440) - ((Hour1 - Hour)* 60)) - (Min1 - Min);
    end;
    3: //hours
    begin
      //First work out in days then * days by 24 to get hours
      //then clculate diff in Hours1 and Hours
      Result := ((Trunc(Date1) - Trunc(Date2))* 24) - (Hour1 - Hour);
    end;
    4: //Days
    begin
      //Trunc the two dates and return the difference
      Result := Trunc(Date1) - Trunc(Date2);
    end;
    5: //Weeks
    begin
      //Trunc the two dates and divide
      //result by seven for weeks
      Result := (Trunc(Date1) - Trunc(Date2)) div 7;
    end;
    6: //Months
    begin
      //Take Diff in Years and * 12 then add diff in months
      Result := ((Year - Year1) * 12) + (Month - Month1);
    end;
    7: //Years
    begin
      //Take Difference In Years and Return result
      Result := Year - Year1;
    end
    else //Invalid Period *** Raise Exception ***
    begin
      raise EInvalidPeriod.Create('Invalid Period Assigned To DateDiff');
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysIsUnique( strId: string ): boolean;
begin
  _hUniqueMutex := createMutex( nil, true, PChar( strId ) );
  Result := ( getLastError <> ERROR_ALREADY_EXISTS );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure _sysDelay( iMilliseconds: Integer );
var
  Tick: DWord;
  Event: THandle;
begin
  Event := CreateEvent( nil, False, False, nil );
  try
    Tick := GetTickCount + DWord( iMilliseconds );
    while ( iMilliseconds > 0 ) and
          ( MsgWaitForMultipleObjects( 1, Event, False, iMilliseconds, QS_ALLINPUT) <> WAIT_TIMEOUT ) do
    begin
      Application.ProcessMessages;
      if Application.Terminated then
        Exit;
      iMilliseconds := Tick - GetTickcount;
    end;
  finally
    CloseHandle( Event );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure _sysAddLog( strLogFile, strLogMsg: string );
var
  f: system.text;
begin
  try
    assignFile( f, strLogFile );
    if( fileExists( strLogFile ) ) then
      append( f )
    else
      rewrite( f );

    strLogMsg := format( '%s - %s', [DateTimeToStr(Now), strLogMsg] );
    writeln( f, strLogMsg );

    closeFile( f );
  except
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysIsHit( iWidth, iHeight: integer; MousePos: TPoint ): boolean;
begin
  Result := False;
  if( MousePos.x >= 0 ) then
    if( MousePos.y >= 0 ) then
      if( MousePos.x < iWidth ) then
        if( MousePos.y < iHeight ) then
          Result := True;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysExpandPath( strPath: string ): string;
begin
  if( pos( '.\', strPath ) = 1 ) then
  begin
    delete( strPath, 1, 2 );
    Result := format( '%s\%s', [_sysModulePath, strPath] );
  end
  else
    Result := strPath;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysIsAltDown : boolean;
var
  State: TKeyboardState;
begin
  GetKeyboardState(State);
  Result := ( ( State[vk_Menu] and 128 ) <> 0 );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysIsCtrlDown : boolean;
var
  State: TKeyboardState;
begin
  GetKeyboardState(State);
  Result := ( ( State[VK_CONTROL] and 128 ) <> 0 );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _sysIsShiftDown : boolean;
var
  State: TKeyboardState;
begin
  GetKeyboardState(State);
  Result := ( ( State[vk_Shift] and 128 ) <> 0 );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
initialization
  _hUniqueMutex := 0;
  _strWorkPath := '';

(* ////////////////////////////////////////////////////////////////////////// *)
finalization
  if( _hUniqueMutex <> 0 ) then
    closeHandle( _hUniqueMutex );

(* ////////////////////////////////////////////////////////////////////////// *)
end.



