program SHKIDSConnect;

uses
  Vcl.Forms,
  SHKIDSConnectUnit1 in 'SHKIDSConnectUnit1.pas' {Form5};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
