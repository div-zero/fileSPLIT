unit Media;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

uses
  Classes;

type
  TMediaUnits = ( muByte, muKB, muMB, muGB );

  CMedia = class
    constructor Create( strLabel: string; dSize: double; tUnits: TMediaUnits );
    procedure setSize( dSize: double; tUnits: TMediaUnits );

  protected
    m_strLabel: string;
    m_dSize: double;
    m_tUnits: TMediaUnits;

  public
    property Size: double read m_dSize;
    property Units: TMediaUnits read m_tUnits;
    property LabelText: string read m_strLabel write m_strLabel;

  end;

  CMediaList = class( TList )
    destructor Destroy; override;
    procedure load( strSection: string );
    procedure store( strSection: string );
    function getMedia( strLabel: string ): CMedia;
    procedure setUserSize( dSize: double; tUnits: TMediaUnits );

  end;

implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  SysUtils,
  AppConfig;

const
  _HDSize = 1457664;
  _UserLabel = '<Meine eigene Größe>';

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
{ CMediaList }
(* ////////////////////////////////////////////////////////////////////////// *)
constructor CMedia.Create( strLabel: string; dSize: double; tUnits: TMediaUnits );
begin
  m_strLabel := strLabel;
  setSize( dSize, tUnits );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMedia.setSize( dSize: double; tUnits: TMediaUnits );
begin
  m_tUnits := tUnits;
  if( dSize > 0 ) then
    m_dSize := dSize;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
{ CMediaList }
(* ////////////////////////////////////////////////////////////////////////// *)
destructor CMediaList.Destroy;
var
  i: integer;
  Media: CMedia;
begin
  for i := 0 to Count - 1 do
  begin
    Media := CMedia( Self[i] );
    Media.Destroy;
  end;

  inherited Destroy;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMediaList.load( strSection: string );
var
  Media: CMedia;
begin
  /// always add some fixed media ...
  Add( CMedia.Create( _UserLabel, _HDSize, muByte ) );
  Add( CMedia.Create( 'DVD5, 4.7 GB', 4480, muMB ) );
  Add( CMedia.Create( 'DVD9, 8.5 GB', 8150, muMB ) );
  Add( CMedia.Create( 'CD, 650 MB', 650, muMB ) );
  Add( CMedia.Create( 'CD, 700 MB', 700, muMB ) );
  Add( CMedia.Create( '10 MB', 10, muMB ) );
  Add( CMedia.Create( '64 MB', 64, muMB ) );
  Add( CMedia.Create( '128 MB', 128, muMB ) );
  Add( CMedia.Create( '256 MB', 256, muMB ) );
  Add( CMedia.Create( '512 MB', 512, muMB ) );
  Add( CMedia.Create( '1024 MB', 1024, muMB ) );
  Add( CMedia.Create( '3.5" HD Disk, 1.44 MB', _HDSize, muByte ) );
  Add( CMedia.Create( '3.5" DD Disk, 720 KB', 730112, muByte ) );

  Media := CMedia( self[0] );
  Media.setSize( _AppConfig.ReadFloat( 'user-media', 'size', 5 ), TMediaUnits( _AppConfig.ReadInteger( 'user-media', 'units', 2 ) ) );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMediaList.store( strSection: string );
var
  Media: CMedia;
begin
  Media := CMedia( self[0] );
  _AppConfig.WriteFloat( 'user-media', 'size', Media.Size );
  _AppConfig.WriteInteger( 'user-media', 'units', integer( Media.Units ) );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMediaList.setUserSize( dSize: double; tUnits: TMediaUnits );
var
  Media: CMedia;
begin
  if( Count >= 0 ) then
  begin
    Media := CMedia( Self[0] );
    Media.setSize( dSize, tUnits );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function CMediaList.getMedia( strLabel: string ): CMedia;
var
  i: integer;
  Media: CMedia;
begin
  Result := nil;
  strLabel := LowerCase( strLabel );
  for i := 0 to Count - 1 do
  begin
    Media := CMedia( Self[i] );
    if( LowerCase( Media.m_strLabel ) = strLabel ) then
    begin
      Result := Media;
      break;
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.
