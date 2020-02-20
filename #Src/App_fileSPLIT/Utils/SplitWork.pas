unit SplitWork;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

type
  TCount = function( iType, iValue: integer ): boolean of object;

  procedure DoSplit
  (
    strFileToSplit: string;
    strFolder: string;
    dSize: double;
    cnt: TCount
  );

implementation

uses
  SysUtils, Classes;

(* ////////////////////////////////////////////////////////////////////////// *)
function SplitFileName( idx: integer ): string;
begin
  Result := 's.' + IntToStr( idx );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function TempFileName( idx: integer ): string;
begin
  Result := 'T.' + IntToStr( idx );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure CreateBatch
(
  idxFile: integer;
  strOrigFileName: string;
  lstBatch: TStringList
);
const
  QUOTE = '"';
var
  s: string;
  i: integer;
  Ready: boolean;
  iSrc, iDest, iTmp: integer;
begin
  s := 'del /F ' + QUOTE + strOrigFileName + QUOTE;
  lstBatch.Add( s );

  s := 'copy /b';

  iSrc := 2;
  iDest := 1;
  i := 0;
  Ready := False;
  while not Ready do
  begin
    if( i > 0 ) then
      s := s + ' +';

    s := s + ' ' + SplitFileName( i );

    if( length( s ) > 100 ) or ( i >= idxFile ) then
    begin
      iTmp := iSrc;
      iSrc := iDest;
      iDest := iTmp;
      s := s + ' ' + TempFileName( iDest );
      lstBatch.Add( s );

      if( i < idxFile ) then
        s := 'copy /b ' + TempFileName( iDest )
      else
        Ready := True;
    end;

    inc( i );
  end;

  s := 'ren ' + TempFileName( iDest ) + ' ' + QUOTE + strOrigFileName + QUOTE;
  lstBatch.Add( s );

  s := 'del ' + TempFileName( iSrc );
  lstBatch.Add( s );

  s := 'del ' + TempFileName( iDest );
  lstBatch.Add( s );

  for i := 0 to idxFile do
  begin
    s := 'del ' + SplitFileName(i);
    lstBatch.Add( s );
  end;
  s := 'del melt.bat';
  lstBatch.Add( s );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure DoSplit
(
  strFileToSplit: string;
  strFolder: string;
  dSize: double;
  cnt: TCount
);
var
  lstBatch: TStringList;
  iBufSize: integer;
  Buffer: PChar;
  i64TotalFileSize: int64;
  i64TotalReadSize: int64;
  iBytesToRead: integer;
  idxFile: integer;
  iBytesRead: integer;
  Ready: boolean;
  fFrom: integer;
  fTo: integer;
  d: double;
  dCounter: double;
  fUserAbort: boolean;
  offset64: int64;
begin
  fUserAbort := False;
  Buffer := nil;
  try
    if( strFolder[ length( strFolder ) ] <> '\' ) then
      strFolder := strFolder + '\';

    iBufSize := 1024 * 1024;
    Buffer := PChar( AllocMem( iBufSize ) );
    i64TotalReadSize := 0;

    fFrom := FileOpen( strFileToSplit,  fmOpenRead );
    offset64 := 0;
    i64TotalFileSize := FileSeek( fFrom, offset64, 2 );
    FileSeek( fFrom, 0, 0 );

    idxFile := 0;
    fTo := FileCreate( strFolder + SplitFileName( idxFile ) );

    dCounter := 0.0;
    Ready := False;
    while( not Ready ) do
    begin
      if( i64TotalReadSize + iBufSize <= dSize ) then
        iBytesToRead := iBufSize
      else
        iBytesToRead := round( dSize ) - i64TotalReadSize;

      iBytesRead := FileRead( fFrom, Buffer^, iBytesToRead );
      dCounter := dCounter + iBytesRead;
      i64TotalReadSize := i64TotalReadSize + iBytesRead;
      FileWrite( fTo, Buffer^, iBytesRead );

      if( assigned( cnt ) ) then
      begin
        d := dCounter / i64TotalFileSize;
        fUserAbort := not cnt( 1, round( 1000 * d ) );
      end;

      if( fUserAbort or ( iBytesRead <> iBytesToRead ) ) then
      begin
        FileClose( fTo );
        FileClose( fFrom );
        Ready := True;
      end
      else if( iBytesToRead <> iBufSize ) then
      begin
        FileClose( fTo );
        inc( idxFile );
        fTo := FileCreate( strFolder + SplitFileName( idxFile ) );
        i64TotalReadSize := 0;
      end;
    end;
  finally
    FreeMem( Buffer );
  end;

  if( fUserAbort ) then
  begin
    if( assigned( cnt ) ) then
      cnt( 3, 0 );
  end
  else
  begin
    lstBatch := TStringList.Create;
    CreateBatch( idxFile, ExtractFileName( strFileToSplit ), lstBatch );
    lstBatch.SaveToFile( strFolder + 'melt.bat' );
    lstBatch.Destroy;

    if( assigned( cnt ) ) then
      cnt( 2, idxFile + 1 );
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.


