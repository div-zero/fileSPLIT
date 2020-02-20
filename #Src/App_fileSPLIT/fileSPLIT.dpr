program fileSPLIT;

uses
  SysUtils,
  Forms,
  appDef in 'appDef.pas',
  FSplit in 'Forms\FSplit.pas' {frmFileSplit},
  MRU in 'Utils\MRU.pas',
  SplitWork in 'Utils\SplitWork.pas',
  Media in 'Utils\Media.pas',
  AppConfig in 'Utils\AppConfig.pas',
  sysTools in 'Utils\sysTools.pas',
  shellTools in 'Utils\shellTools.pas',
  strTools in 'Utils\strTools.pas';

{$R *.RES}

begin
  Application.Initialize;

  FormatSettings.DecimalSeparator := '.';
  Application.UpdateFormatSettings := False;
  Application.MainFormOnTaskbar := True;

  Application.Title := APP_NAME;
  Application.CreateForm(TfrmFileSplit, frmFileSplit);
  Application.Run;
end.


