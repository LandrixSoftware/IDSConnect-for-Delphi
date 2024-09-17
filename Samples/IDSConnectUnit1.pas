unit IDSConnectUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, System.Inifiles
  ,intf.IDSConnectTypes,intf.IDSConnect;

type
  TMainForm = class(TForm)
    ListBox1: TListBox;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Edit2: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    //Aufbau der Ini-Datei mit Lieferanten
    //[Name Lieferant]
    //Username=...
    //Password=...
    //Customernumber=...
    //IDSConnectUrl=https://...
    //...

    cfg : TMemIniFile;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.Button2Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
begin
  if ListBox1.ItemIndex < 0 then
    exit;
  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    //URL unbedingt gegen eigene austauschen!
    TIDSConnect.IDSCONNECT_HOOKURL := 'https://www.landrix.de/idsconnect.php';

    if not TIDSConnect.IDSConnectWKE(
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'IDSConnectUrl',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Customernumber',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Username',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Password',''),
              ExtractFilePath(Application.ExeName)+'idsconnect.html',
              lWarenkorb) then
      exit;
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
  if ListBox1.ItemIndex < 0 then
    exit;
  TIDSConnect.IDSConnectADT(
            cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'IDSConnectUrl',''),
            cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Customernumber',''),
            cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Username',''),
            cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Password',''),
            Edit1.Text,
            ExtractFilePath(Application.ExeName)+'idsconnect.html');
end;

procedure TMainForm.Button4Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  i : Integer;
  lSendOnly : Boolean;
begin
  Memo1.Clear;
  if ListBox1.ItemIndex < 0 then
    exit;

  lSendOnly := (MessageDlg('Warenkorb nur senden? (Bestellung)'+#13+#10+'Nein = empfangen zum Preise aktualisieren.', mtConfirmation, [mbYes, mbNo], 0) = mrYes);

  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    //URL unbedingt gegen eigene austauschen!
    TIDSConnect.IDSCONNECT_HOOKURL := 'https://www.landrix.de/idsconnect.php';

    lWarenkorb.WarenkorbInfo.Date := Date;
    lWarenkorb.WarenkorbInfo.Time := now;
    with lWarenkorb.Order.OrderItems.AddItem do
    begin
      ItemChara := idsConnectIc_normal;
      ArtNo := 'ONA9080EF';
      Qty := 1;
    end;
    with lWarenkorb.Order.OrderItems.AddItem do
    begin
      ItemChara := idsConnectIc_normal;
      ArtNo := 'AXPP2RM100200';
      Qty := 100;
    end;

    if not TIDSConnect.IDSConnectWKS(
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'IDSConnectUrl',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Customernumber',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Username',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Password',''),
              ExtractFilePath(Application.ExeName)+'idsconnect.html',
              lWarenkorb,lSendOnly) then
      exit;

    if lSendOnly then
      exit;

    for i := 0 to lWarenkorb.Order.OrderItems.Count-1 do
      Memo1.Lines.Add(lWarenkorb.Order.OrderItems[i].ArtNo+' '+Format('%m',[lWarenkorb.Order.OrderItems[i].NetPrice]));
  finally
    lWarenkorb.Free;
  end;

end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  i : Integer;
begin
  Memo1.Clear;
  if ListBox1.ItemIndex < 0 then
    exit;
  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    //URL unbedingt gegen eigene austauschen!
    TIDSConnect.IDSCONNECT_HOOKURL := 'https://www.landrix.de/idsconnect.php';

    if not TIDSConnect.IDSConnectAS(
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'IDSConnectUrl',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Customernumber',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Username',''),
              cfg.ReadString(ListBox1.Items[ListBox1.ItemIndex],'Password',''),
              ExtractFilePath(Application.ExeName)+'idsconnect.html',
              Edit2.Text,
              lWarenkorb) then
      exit;
    for i := 0 to lWarenkorb.Order.OrderItems.Count-1 do
      Memo1.Lines.Add(lWarenkorb.Order.OrderItems[i].ArtNo+' '+lWarenkorb.Order.OrderItems[i].Kurztext);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  cfg := TMemIniFile.Create(ExtractFilePath(ExtractFileDir(ExtractFileDir(Application.ExeName)))+'configuration.ini');
  cfg.ReadSections(ListBox1.Items);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(cfg) then begin cfg.Free; cfg := nil; end;
end;

end.
