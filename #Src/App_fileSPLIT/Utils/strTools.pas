unit strTools;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

function _strReplace(const S, Srch, Replace: string): string;
function _strGetNextValue( sTotal: string; cSeparator: char; var position: integer; var sSub: string ): boolean;
function _strGetValue( sTotal: string; idx: integer; cSeparator: char; var sSub: string ): boolean;
function _strExtractSub( var strFull, strSub: string; cSeparator: char ): boolean;
function _strFillLeft( s: string; sign: char; count: byte ): string;
function _strCutBlanks( theString: string ): string;
function _strCutChars( theString: string; c: char ): string;
function _strAppendSlash( s: string ): string;
function _strDeleteLastSlash( s: string ): string;
function _strXML2Plain( s: string ): string;
function _strPlain2XML( s: string ): string;
function _strBool2Str( b: boolean ): string;
function _strStr2Bool( s: string ): boolean;
function _strSplitKeyValue( strTotal: string; var strKey, strValue: string ): boolean;
function _strFormatTime( iSeconds: longint ): string;
function _strToLong( strValue: string; lDefault: longint ): longint;
function _strToDouble( strValue: string; dDefault: double ): double;
function _strToMinutes( strValue: string; var iMinutes: integer ): boolean;
function _strToHHMM( iMinutes: integer ): string;
function _strIsAnsi( const AString: string ): boolean;
function _strFormatHourMinSec( dSeconds: double ): string;
function _strEssential( s: string ): string;

implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  SysUtils;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strReplace(const S, Srch, Replace: string): string;
var
  i: Integer;
  Source: string;
begin
  Source := S;
  Result := '';
  repeat
    I := Pos( Srch, Source );
    if I > 0 then
    begin
      Result := Result + Copy( Source, 1, i - 1 ) + Replace;
      Source := Copy( Source, i + Length(Srch), MaxInt );
    end
    else
      Result := Result + Source;
  until I <= 0;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strGetNextValue( sTotal: string; cSeparator: char; var position: integer; var sSub: string ): boolean;
var
  bReady: boolean;
begin
  sSub := '';
  Result := position <= length( sTotal );

  if( Result ) then
  begin
    bReady := False;
    while not bReady do
    begin
      inc( position );
      if( position > length( sTotal ) ) then
        bReady := True
      else if( sTotal[position] = cSeparator ) then
        bReady := True
      else
        sSub := sSub + sTotal[position];
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strGetValue( sTotal: string; idx: integer; cSeparator: char; var sSub: string ): boolean;
var
  i, idxActual: integer;
begin
  sSub := '';
  idxActual := 0;
  for i := 1 to system.length( sTotal ) do
  begin
    if( sTotal[i] = cSeparator ) then
      inc( idxActual );

    if( idxActual = idx ) then
    begin
      if( sTotal[i] <> cSeparator ) then
        sSub := sSub + sTotal[i];
    end
    else if( idxActual > idx ) then
      break;
  end;
  Result := ( idxActual > idx ) or
            ( ( idxActual = idx ) and ( idx > 0 ) );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strFillLeft( s: string; sign: char; count: byte ): string;
var
  i, fill: integer;
begin
  Result := s;
  fill := count - system.length( s );
  for i := 1 to fill do
    Result := sign + Result;
end;

(* ////////////////////////////////////////////////////////////////////// *)
function _strCutBlanks( theString: string ): string;
begin
  Result := _strCutChars( theString, ' ' );
end;

(* ////////////////////////////////////////////////////////////////////// *)
function _strCutChars( theString: string; c: char ): string;
var
  i: word;
begin
  Result := '';
  for i := 1 to length( theString ) do
  begin
    if( theString[i] <> c ) then
      Result := Result + theString[i];
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strAppendSlash( s: string ): string;
var
  l: integer;
begin
  Result := s;
  l := length( Result );
  if( l > 0 ) then
    if( not CharInSet( Result[l], ['\'] ) ) then
      Result := Result + '\';
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strDeleteLastSlash( s: string ): string;
var
  l: integer;
begin
  Result := s;
  l := length( Result );
  if( l > 0 ) then
    if( CharInSet( Result[l], ['\'] ) ) then
      delete( Result, l, 1 );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strXML2Plain( s: string ): string;
begin
  Result := s;
  Result := _strReplace( Result, '&', '&amp;' );
  Result := _strReplace( Result, '<', '&lt;' );
  Result := _strReplace( Result, '>', '&gt;' );
  Result := _strReplace( Result, '"', '&quot;' );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strPlain2XML( s: string ): string;
begin
  Result := s;
  Result := _strReplace( Result, '&lt;', '<' );
  Result := _strReplace( Result, '&gt;', '>' );
  Result := _strReplace( Result, '&quot;', '"' );
  Result := _strReplace( Result, '&amp;', '&' );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strBool2Str( b: boolean ): string;
begin
  if( b ) then
    Result := 'true'
  else
    Result := 'false';
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strStr2Bool( s: string ): boolean;
begin
  s := LowerCase( s );
  Result := ( s = 'true' ) or ( s = 'yes' ) or ( s= 'y' ) or ( s= '1' )
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strSplitKeyValue( strTotal: string; var strKey, strValue: string ): boolean;
var
  p: integer;
begin
  Result := False;
  strKey := '';
  strValue := '';
  p := pos( '=', strTotal );
  if( p > 1 ) then
  begin
    strKey := copy( strTotal, 1, p - 1 );
    strValue := copy( strTotal, p + 1, length( strTotal ) );
    Result := True; 
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strFormatTime( iSeconds: longint ): string;
var
  iTimeHours: integer;
  iTimeHoursSecs: integer;
  iTimeMinutes: integer;
  iTimeMinutesSecs: integer;
  iTimeSeconds: integer;
begin
  iTimeHours := iSeconds div ( 60 * 60 );
  iTimeHoursSecs := iTimeHours * 60 * 60;
  iTimeMinutes := ( iSeconds - iTimeHoursSecs ) div ( 60 );
  iTimeMinutesSecs := iTimeMinutes * 60;
  iTimeSeconds := iSeconds - iTimeHoursSecs - iTimeMinutesSecs;

  Result := format( '%d:%.2d:%.2d', [iTimeHours, iTimeMinutes, iTimeSeconds] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strToLong( strValue: string; lDefault: longint ): longint;
begin
  try
    Result := StrToInt( strValue );
  except
    Result := lDefault;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strToDouble( strValue: string; dDefault: double ): double;
begin
  strValue := _strReplace( strValue, ',', '.' );
  try
    FormatSettings.DecimalSeparator := '.';
    Result := StrToFloat( strValue );
  except
    Result := dDefault;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strToMinutes( strValue: string; var iMinutes: integer ): boolean;
var
  dTime: double;
  iHH: integer;
  iMM: integer;
begin
  Result := False;

  try
    FormatSettings.DecimalSeparator := '.';
    dTime := StrToFloat( strValue );
    iMinutes := round( dTime * 60 );
    Result := True;
    exit;
  except
  end;

  try
    FormatSettings.DecimalSeparator := ',';
    dTime := StrToFloat( strValue );
    iMinutes := round( dTime * 60 );
    Result := True;
    exit;
  except
  end;

  try
    FormatSettings.DecimalSeparator := ':';
    dTime := StrToFloat( strValue );
    iHH := trunc( dTime );
    iMM := round( ( dTime - iHH ) * 100 );
    iMinutes := ( 60 * iHH ) + iMM;
    Result := True;
  except
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strToHHMM( iMinutes: integer ): string;
var
  iHH: integer;
  iMM: integer;
begin
  iHH := iMinutes div 60;
  iMM := iMinutes - ( iHH * 60 );
  Result := format( '%d:%.2d', [iHH, iMM] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strIsAnsi( const AString: string ): boolean;
var
  tempansi : AnsiString;
  temp : string;
begin
  tempansi := AnsiString( AString );
  temp := string( tempansi );
  Result := temp = AString;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strExtractSub( var strFull, strSub: string; cSeparator: char ): boolean;
var
  p: integer;
begin
  Result := False;

  strFull := trim(strFull);
  if ('' = strFull) then
    exit;

  p := pos( cSeparator, strFull );
  if ( p > 1 ) then
  begin
    strSub := copy( strFull, 1, p );
    strSub := trim( strSub );
    delete( strFull, 1, p );
  end
  else
  begin
    strSub := strFull;
    strFull := '';
  end;

  Result := True;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strFormatHourMinSec( dSeconds: double ): string;
begin
  if( dSeconds < 60*60 ) then
    Result := FormatDateTime('nn:ss', dSeconds / SecsPerDay )
  else if( dSeconds < SecsPerDay ) then
    Result := FormatDateTime('hh:nn:ss', dSeconds / SecsPerDay )
  else
    Result := Format( '%.1f day', [dSeconds / SecsPerDay] );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function _strEssential( s: string ): string;
var
  idx: integer;
begin
  Result := '';
  s := LowerCase( s );
  for idx := 1 to Length( s ) do
    if( CharInSet( s[idx], ['a'..'z', '0'..'9'] ) ) then
      Result := Result + s[idx];
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.
