unit FSplit;
(* --------------------------------------------------------------------------
   copyright (c) 2020 by Matthias Jung
   https://www.intelli-bit.de
   -------------------------------------------------------------------------- *)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons,
  Vcl.Imaging.pngimage,
  MRU,
  Media;

type
  TStatus = ( sOffline, sRunning, sAborting );

type
  TfrmFileSplit = class(TForm)
    btnFile: TButton;
    btnFolder: TButton;
    od: TOpenDialog;
    btnExit: TButton;
    btnStart: TButton;
    lblOne: TLabel;
    lblTwo: TLabel;
    lblFile: TLabel;
    lblThree: TLabel;
    lblOutputFolder: TLabel;
    lblFour: TLabel;
    lblMaxFileSize: TLabel;
    pnlHeader: TPanel;
    lblCaption: TLabel;
    pbCount: TProgressBar;
    comboFile: TComboBox;
    comboFolder: TComboBox;
    comboMedia: TComboBox;
    comboUnits: TComboBox;
    edtSize: TEdit;
    lblFileHint: TLabel;
    lblMaxFileSizeHint: TLabel;
    Panel2: TPanel;
    imgCaption: TImage;
    lblCopyright: TLinkLabel;

    procedure FormCreate( Sender: TObject );
    procedure FormDestroy( Sender: TObject );

    procedure btnFileClick( Sender: TObject );
    procedure btnFolderClick( Sender: TObject );
    procedure btnExitClick( Sender: TObject );
    procedure btnStartClick( Sender: TObject );

    procedure comboMediaClick( Sender: TObject );
    procedure lblCopyrightLinkClick( Sender: TObject; const Link: string; LinkType: TSysLinkType );

  private
    m_mruFolder: CMRU;
    m_mruFile: CMRU;
    m_lstMedia: CMediaList;
    m_status: TStatus;

    function Count( iType, iValue: integer ): boolean;
    function validate( var size: double ): boolean;
    procedure addFile( strFileName: string );
    procedure addFolder( strFolderName: string );
    procedure WMDropFiles( var msg: TWMDropFiles ); message wm_DropFiles;

  end;

var
  frmFileSplit: TfrmFileSplit;

implementation

(* ////////////////////////////////////////////////////////////////////////// *)
uses
  ShellAPI,
  shellTools,
  appDef,
  AppConfig,
  SplitWork;

{$R *.DFM}

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.FormCreate( Sender: TObject );
var
  i: integer;
  strFileName: string;
begin
  m_status := sOffline;

  Caption := APP_NAME + ' ' + APP_VER;
  m_mruFolder := CMRU.Create;
  m_mruFile := CMRU.Create;

  m_lstMedia := CMediaList.Create;
  m_lstMedia.load( 'Media' );

  for i := 0 to m_lstMedia.Count - 1 do
    comboMedia.Items.Add( CMedia( m_lstMedia[i] ).LabelText );

  m_mruFolder.Load( 'MRU-Folder' );
  m_mruFile.Load( 'MRU-File' );

  comboFolder.Items.Assign( m_mruFolder );
  comboFile.Items.Assign( m_mruFile );

  DragAcceptFiles( Handle, True );

  comboFolder.ItemIndex := _AppConfig.ReadInteger( 'fileSPLIT', 'LastFolder', 0 );
  comboMedia.ItemIndex := _AppConfig.ReadInteger( 'fileSPLIT', 'LastMedia', 1 );

  if( ParamCount > 0 ) then
  begin
    strFileName := ParamStr( 1 );
    if( fileExists( strFileName ) ) then
      addFile( strFileName );
  end;

  comboMediaClick(Self);
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.FormDestroy( Sender: TObject );
begin
  if( assigned( m_mruFolder ) ) then
  begin
    m_mruFolder.Store( 'MRU-Folder' );
    m_mruFolder.Destroy;
  end;

  if( assigned( m_mruFile ) ) then
  begin
    m_mruFile.Store( 'MRU-File' );
    m_mruFile.Destroy;
  end;

  _AppConfig.WriteInteger( 'fileSPLIT', 'LastFolder', comboFolder.ItemIndex );
  _AppConfig.WriteInteger( 'fileSPLIT', 'LastMedia', comboMedia.ItemIndex );

  m_lstMedia.store( 'Media' );
  m_lstMedia.Destroy;

  DragAcceptFiles( Handle, False );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.lblCopyrightLinkClick( Sender: TObject; const Link: string; LinkType: TSysLinkType );
begin
  ShellExecute(Handle, nil, PChar( Link ), nil, nil, 1);
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.btnFileClick( Sender: TObject );
begin
  od.FileName := comboFile.Text;
  if( od.Execute ) then
    addFile( od.FileName );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.addFile( strFileName: string );
begin
  m_mruFile.AddMRU( strFileName );
  comboFile.Items.Assign( m_mruFile );
  comboFile.ItemIndex := 0;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.btnFolderClick( Sender: TObject );
var
  strFolder: string;
begin
  strFolder := comboFolder.Text;
  if( _shellBrowseForFolder( Handle, 'SPLIT-Verzeichnis auswählen', strFolder, True ) ) then
    addFolder( strFolder );
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.addFolder( strFolderName: string );
begin
  m_mruFolder.AddMRU( strFolderName );
  comboFolder.Items.Assign( m_mruFolder );
  comboFolder.ItemIndex := 0;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.btnExitClick( Sender: TObject );
begin
  Close;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function TfrmFileSplit.validate( var size: double ): boolean;
var
  v: double;
  n: integer;
  s: string;
begin
  Result := True;

  if( comboFile.Text = '' ) then
  begin
    MessageBox( Handle, 'Wie wäre es mit einer Datei zum Zerteilen ?', APP_NAME, mb_IconHand );
    btnFile.SetFocus;
    Result := False;
  end
  else
  begin
    if( not fileExists( comboFile.Text ) ) then
    begin
      MessageBox( Handle, 'Oh je: Die ausgewählte Datei gibt es nicht (mehr) ...', APP_NAME, mb_IconHand );
      m_mruFile.removeExisting( comboFile.Text );
      comboFile.Items.Assign( m_mruFile );
      comboFile.ItemIndex := -1;
      btnFile.SetFocus;
      Result := False;
    end;
  end;

  if( Result ) then
  begin
    if( comboFolder.Text = '' ) then
    begin
      MessageBox( Handle, 'Bevor es losgeht müssen Sie erst ein Verzeichnis für die SPLIT-Dateien angeben!.', APP_NAME, mb_IconHand );
      btnFolder.SetFocus;
      Result := False;
    end
    else
    begin
      if( not SysUtils.DirectoryExists( comboFolder.Text ) ) then
      begin
        MessageBox( Handle, 'Oh je: Das ausgewähle Verzeichnis gibt es nicht (mehr) ...', APP_NAME, mb_IconHand );
        m_mruFolder.removeExisting( comboFolder.Text );
        comboFolder.Items.Assign( m_mruFolder );
        comboFolder.ItemIndex := -1;
        btnFolder.SetFocus;
        Result := False;
      end;
    end;
  end;

  if( Result ) then
  begin
    s := edtSize.Text;
    n := pos( ',', s );
    if( n > 0 ) then
      s[n] := '.';

    try
      v := StrToFloat( s );
    except
      v := -1;
    end;

    if( v <= 0 ) then
    begin
      MessageBox( Handle, 'Also, die SPLIT-Größe sollte schon ein echter, positiver Wert sein!', APP_NAME, mb_IconHand );
      edtSize.SetFocus;
      Result := False;
    end
    else
    begin
      if( comboMedia.ItemIndex = 0 ) then
        m_lstMedia.setUserSize( v, TMediaUnits( comboUnits.ItemIndex ) );

      case comboUnits.ItemIndex of
        0: size := v;
        1: size := v * 1024;
        2: size := v * 1024 * 1024;
        3: size := v * 1024 * 1024 * 1024;
        else size := v;
      end;
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.btnStartClick( Sender: TObject );
var
  size: double;
begin
  case m_status of
    sOffline:
    begin
      if( validate( size ) ) then
      begin
        btnStart.Caption := 'Stop';
        btnExit.Enabled := False;
        m_status := sRunning;
        DoSplit( comboFile.Text, comboFolder.Text, size, Count );
        m_status := sOffline;
        btnExit.Enabled := True;
        btnStart.Caption := 'Start';
      end;
    end;
    sRunning:
      m_status := sAborting;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
function TfrmFileSplit.Count( iType, iValue: integer ): boolean;
var
  s: string;
begin
  Result := True;

  Application.ProcessMessages;

  case iType of
    0:  /// Initialisierung
    begin
      pbCount.Min := 0;
      pbCount.Max := iValue;
      pbCount.Position := 0;
    end;
    1:  /// Next step is done ...
    begin
      pbCount.Position := iValue;
      if( m_status = sAborting ) then
        Result := False;
    end;
    2:  /// Fertig
    begin
      pbCount.Position := 0;
      s := '"%s"' + #13#10;
      s := s + 'erfolgreich in %d Teile zersägt und diese in' + #13#10;
      s := s + '"%s"' + #13#10;
      s := s + 'abgelegt.' + #13#10#13#10;
      s := s + 'Guten Transport!';
      s := Format( s, [comboFile.Text, iValue, comboFolder.Text] );
      MessageBox( Handle, PChar( s ), APP_NAME, mb_IconInformation );
    end;
    3:  /// Aborted
    begin
      pbCount.Position := 0;
      s := 'Split von "%s"' + #13#10;
      s := s + 'abgebrochen. Datei-Reste könnten sich in' + #13#10;
      s := s + '"%s"' + #13#10;
      s := s + 'befinden.';
      s := Format( s, [comboFile.Text, comboFolder.Text] );
      MessageBox( Handle, PChar( s ), APP_NAME, mb_IconWarning );
    end;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.WMDropFiles( var msg: TWMDropFiles );
var
  iNumDropped: integer;
  DroppedName: array[0..255] of char;
begin
  iNumDropped := DragQueryFile( msg.Drop, $FFFFFFFF, nil, 0 );
  if( iNumDropped > 0 ) then
  begin
    DragQueryFile( msg.Drop, 0, DroppedName, SizeOf( DroppedName ) );
    DragFinish( msg.Drop );

    if( fileExists( DroppedName ) ) then
      addFile( DroppedName )
    else if( SysUtils.DirectoryExists( DroppedName ) ) then
      addFolder( DroppedName )
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
procedure TfrmFileSplit.comboMediaClick( Sender: TObject );
var
  Media: CMedia;
begin
  edtSize.Readonly := comboMedia.ItemIndex > 0;
  comboUnits.Enabled := comboMedia.ItemIndex = 0;

  Media := m_lstMedia.getMedia( comboMedia.Text );

  edtSize.Text := FloatToStr( Media.Size );
  comboUnits.ItemIndex := integer( Media.Units );

  if( edtSize.Readonly ) then
  begin
    edtSize.Color := clBtnFace;
    comboUnits.Color := clBtnFace;
  end
  else
  begin
    edtSize.Color := clWindow;
    comboUnits.Color := clWindow;
  end;
end;

(* ////////////////////////////////////////////////////////////////////////// *)
(* ////////////////////////////////////////////////////////////////////////// *)
end.

