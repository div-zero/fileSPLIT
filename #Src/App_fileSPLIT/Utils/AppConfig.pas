unit AppConfig;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

uses
  IniFiles;

type
  TLocation = ( locSystem, locSystemAllUsers, locPortable, locPortableMultiUser );

  CAppConfig = class( TIniFile )

    function exists: boolean;
    procedure tagAsExisting;

    procedure loadSettings;

    function expandVars( strText: string ): string;

  protected
    m_Location: TLocation;
    m_strAppRoot: string;
    m_strGlobalAppDataRoot: string;
    m_strGlobalDocRoot: string;
    m_strUserAppDataRoot: string;
    m_strUserDocRoot: string;

  private
    constructor Create; overload;

    procedure init;

    function getLocationByIndicator( strPath: string ): TLocation;

    function getTempPath: string;
    function getSystemUserTempFolder: string;
    function getIniFileName: string;

  public
    property Location: TLocation read m_Location;
    property AppRoot: string read m_strAppRoot;
    property GlobalAppDataRoot: string read m_strGlobalAppDataRoot;
    property GlobalDocRoot: string read m_strGlobalDocRoot;
    property UserAppDataRoot: string read m_strUserAppDataRoot;
    property UserDocRoot: string read m_strUserDocRoot;
    property TempPath: string read getTempPath;
    property IniFileName: string read getIniFileName;

  end;

function _AppConfig: CAppConfig; overload;
procedure _destroyAppConfig;

const
  APPCONFIG_GLOBAL_TEMP_PATH: string = '';
  APPCONFIG_EXPLICIT_INIFILE: string = '';

implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  SysUtils,
  appDef,
  sysTools,
  shellTools;

var
  _AppConfig_: CAppConfig;

const
  INDICATOR_PORTABLE = 'location.portable.txt';
  INDICATOR_PORTABLE_MULTI_USER = 'location.portable-multi-user.txt';
  INDICATOR_SYSTEM = 'location.system.txt';
  INDICATOR_SYSTEM_ALL_USERS = 'location.system-all-users.txt';

  USERS_FOLDER = 'Users';

  APP_ROOT = '{*app-root*}';
  GLOBAL_APPDATA_ROOT = '{*global-appdata-root*}';
  GLOBAL_DOC_ROOT = '{*global-doc-root*}';
  USER_APPDATA_ROOT = '{*user-appdata-root*}';
  USER_DOC_ROOT = '{*user-doc-root*}';
  TEMP_ROOT = '{*temp-root*}';
  USER = '{*current-user*}';
  SYSTEM_GLOBAL_TEMP = '{*system-global-temp*}';
  SYSTEM_USER_TEMP = '{*system-user-temp*}';

  INITIALIZED_AT = 'initialized-at';

(* ////////////////////////////////////////////////////////////////////////// *)
function _AppConfig: CAppConfig;
begin
  if( not assigned( _AppConfig_ ) ) then
    _AppConfig_ := CAppConfig.create;

  Result := _AppConfig_;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure _destroyAppConfig;
begin
  if( assigned( _AppConfig_ ) ) then
    _AppConfig_.Destroy;

  _AppConfig_ := nil;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
constructor CAppConfig.Create;
var
  strIniFileName: string;
begin
  init;
  strIniFileName := getIniFileName;
  inherited create( strIniFileName );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CAppConfig.init;
var
  strSysDir: string;
begin
  m_strAppRoot := _sysModulePath;
  m_Location := getLocationByIndicator( m_strAppRoot );
  case m_Location of
    locSystem:
    begin
      strSysDir := _shellGetSpecialFolderPath( sfCommonAppData );
      m_strGlobalAppDataRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
      strSysDir := _shellGetSpecialFolderPath( sfCommonDocuments );
      m_strGlobalDocRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
      strSysDir := _shellGetSpecialFolderPath( sfMyAppData );
      m_strUserAppDataRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
      strSysDir := _shellGetSpecialFolderPath( sfMyDocuments );
      m_strUserDocRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
    end;
    locSystemAllUsers:
    begin
      strSysDir := _shellGetSpecialFolderPath( sfCommonAppData );
      m_strGlobalAppDataRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
      strSysDir := _shellGetSpecialFolderPath( sfCommonDocuments );
      m_strGlobalDocRoot := format( '%s\%s\%s', [strSysDir, APP_COMPANY, APP_NAME_CONTEXT] );
      m_strUserAppDataRoot := m_strGlobalAppDataRoot;
      m_strUserDocRoot := m_strGlobalDocRoot;
    end;
    locPortable:
    begin
      m_strGlobalAppDataRoot := m_strAppRoot;
      m_strGlobalDocRoot := m_strAppRoot;
      m_strUserAppDataRoot := m_strAppRoot;
      m_strUserDocRoot := m_strAppRoot;
    end;
    locPortableMultiUser:
    begin
      m_strGlobalAppDataRoot := m_strAppRoot;
      m_strGlobalDocRoot := m_strAppRoot;
      m_strUserAppDataRoot := format( '%s\%s\%s', [m_strAppRoot, USERS_FOLDER, _sysCurrentUser] );
      m_strUserDocRoot := m_strUserAppDataRoot;
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.getLocationByIndicator( strPath: string ): TLocation;
var
  strIndicatorFile: string;
begin
  strIndicatorFile := format( '%s\%s', [strPath, INDICATOR_PORTABLE] );
  if( FileExists( strIndicatorFile ) ) then
  begin
    Result := locPortable;
    exit;
  end;

  strIndicatorFile := format( '%s\%s', [strPath, INDICATOR_PORTABLE_MULTI_USER] );
  if( FileExists( strIndicatorFile ) ) then
  begin
    Result := locPortableMultiUser;
    exit;
  end;

  strIndicatorFile := format( '%s\%s', [strPath, INDICATOR_SYSTEM_ALL_USERS] );
  if( FileExists( strIndicatorFile ) ) then
  begin
    Result := locSystemAllUsers;
    exit;
  end;

  /// finally this is the default.
  /// we do not really check for INDICATOR_SYSTEM
  Result := locSystem;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.exists: boolean;
var
  strIniFileName: string;
  strCfgInit: string;
begin
  strIniFileName := getIniFileName;
  Result := FileExists( strIniFileName );
  if( not Result ) then
  begin
    /// avoid trouble with UNC path names ...
    strCfgInit := ReadString( 'application', INITIALIZED_AT, '' );
    Result := strCfgInit <> '';
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CAppConfig.tagAsExisting;
var
  strIniFileName: string;
begin
  strIniFileName := getIniFileName;
  WriteString( 'application', INITIALIZED_AT, FormatDateTime( 'yyyy-mm-dd hh:nn:ss', Now ) );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CAppConfig.loadSettings;
var
  strTempPath: string;
begin
  if( APPCONFIG_GLOBAL_TEMP_PATH <> '' ) then
    exit;

  strTempPath := ReadString( 'application', 'temp-path', getTempPath );
  APPCONFIG_GLOBAL_TEMP_PATH := expandVars( strTempPath );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.getTempPath: string;
begin
  if( APPCONFIG_GLOBAL_TEMP_PATH <> '' ) then
    Result := APPCONFIG_GLOBAL_TEMP_PATH
  else
    Result := format( '%s\Temp', [m_strUserAppDataRoot] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.getSystemUserTempFolder: string;
begin
  Result := format( '%s\%s\%s\Temp', [_shellGetSpecialFolderPath( sfMyAppData ), APP_COMPANY, APP_NAME_CONTEXT] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.getIniFileName: string;
begin
  if( APPCONFIG_EXPLICIT_INIFILE <> '' ) then
    Result := APPCONFIG_EXPLICIT_INIFILE
  else
  begin
    Result := _sysModuleName;
    Result := ChangeFileExt( Result, '.ini' );
    Result := format( '%s\%s', [m_strUserAppDataRoot, Result] );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CAppConfig.expandVars( strText: string ): string;
begin
  Result := strText;
  Result := StringReplace( Result, APP_ROOT, m_strAppRoot, [rfIgnoreCase] );
  Result := StringReplace( Result, GLOBAL_APPDATA_ROOT, m_strGlobalAppDataRoot, [rfIgnoreCase] );
  Result := StringReplace( Result, GLOBAL_DOC_ROOT, m_strGlobalDocRoot, [rfIgnoreCase] );
  Result := StringReplace( Result, USER_APPDATA_ROOT, m_strUserAppDataRoot, [rfIgnoreCase] );
  Result := StringReplace( Result, USER_DOC_ROOT, m_strUserDocRoot, [rfIgnoreCase] );
  Result := StringReplace( Result, TEMP_ROOT, getTempPath, [rfIgnoreCase] );
  Result := StringReplace( Result, USER, _sysCurrentUser, [rfIgnoreCase] );
  Result := StringReplace( Result, SYSTEM_GLOBAL_TEMP, _sysSystemGlobalTempFolder, [rfIgnoreCase] );
  Result := StringReplace( Result, SYSTEM_USER_TEMP, getSystemUserTempFolder, [rfIgnoreCase] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
initialization
  _AppConfig_ := nil;

(* ////////////////////////////////////////////////////////////////////////// *)
finalization
  if( assigned( _AppConfig_ ) ) then
  begin
    _AppConfig_.Destroy;
    _AppConfig_ := nil;
  end;

(* ////////////////////////////////////////////////////////////////////////// *)
end.


