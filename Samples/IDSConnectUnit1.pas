unit IDSConnectUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls
  ,intf.IDSConnectTypes;

type
  TMainForm = class(TForm)
    ListBox1: TListBox;
    Label1: TLabel;
    Button1: TButton;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

end.
