unit MRU;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

uses
  Classes;

type
  CMRU = class( TStringList )
    constructor Create;
    procedure Load( strSection: string );
    procedure Store( strSection: string );
    procedure AddMRU( strEntry: string );
    procedure removeExisting( strEntry: string );
  private
    m_iSize: integer;
    procedure setSize( iValue: integer );
    procedure shrink;
  public
    property Size: integer read m_iSize write setSize;
  end;

implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  SysUtils,
  AppConfig;

(* ////////////////////////////////////////////////////////////////////////// *)
constructor CMRU.Create;
begin
  inherited Create;
  m_iSize := 20;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.AddMRU(strEntry: string);
begin
  removeExisting( strEntry );
  insert( 0, strEntry );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.shrink;
begin
  while Count > m_iSize do
    delete( Count - 1 );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.Load( strSection: string );
begin
  _AppConfig.ReadSection( strSection, self );
  shrink;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.setSize(iValue: integer);
begin
  if( iValue > 0 ) then
  begin
    m_iSize := iValue;
    shrink;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.Store( strSection: string);
var
  i: integer;
begin
  _AppConfig.EraseSection( strSection );
  for i := 0 to Count - 1 do
    _AppConfig.WriteString( strSection, self[i], '' );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CMRU.removeExisting( strEntry: string );
var
  i: integer;
begin
  strEntry := lowercase( strEntry );
  for i := Count - 1 downto 0 do
  begin
    if( lowercase( self[i] ) = strEntry ) then
      delete( i );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.
