unit IDSConnectUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,Vcl.Controls, Vcl.Forms, System.UITypes,
  Vcl.Dialogs, Vcl.StdCtrls, System.Inifiles, System.StrUtils, System.IOUtils,
  System.DateUtils
  ,intf.IDSConnectTypes,intf.IDSConnect,intf.IDSConnectDlgWebBrowser;

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
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    //Aufbau der Ini-Datei mit Lieferanten
    //[Settings]
    //HookUrl=https://<eigener-server>/idsconnect.php
    //
    //[Name Lieferant]
    //Username=...
    //Password=...
    //Customernumber=...
    //IDSConnectUrl=https://...
    //...

    cfg : TMemIniFile;
    function ConfigFilename : String;
    procedure LoadConfig;
    //Die Hook-URL muss auf einen eigenen Server zeigen; ueber sie laufen
    //Warenkorb-, Preis- und Kundendaten zurueck zur Handwerkssoftware.
    function PrepareHookUrl : Boolean;
    function SelectedSection : String;
    function TempHtmlFilename : String;
    procedure ShowWarenkorb(_Warenkorb : TIDSConnect_Warenkorb);
    procedure HandleIDSError(const _Message : String; _E : Exception);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  //Sektion mit allgemeinen Einstellungen; sie taucht nicht in der
  //Anbieterliste auf
  CFG_SETTINGS = 'Settings';

function TMainForm.ConfigFilename: String;
begin
  Result := ExtractFilePath(ExtractFileDir(ExtractFileDir(Application.ExeName)))+'configuration.ini';
end;

function TMainForm.TempHtmlFilename: String;
begin
  //Leerer Dateiname bedeutet fuer alle Aktionen: im integrierten Browser
  //anzeigen. Dann wird auch keine Datei mit Zugangsdaten geschrieben.
  if CheckBox1.Checked then
    exit('');

  //Die Datei enthaelt Kundennummer, Benutzername und Passwort im Klartext.
  //Sie gehoert deshalb nicht neben die EXE (dort schlaegt das Schreiben unter
  //C:\Program Files ausserdem fehl), sondern in das Benutzer-Temp-Verzeichnis.
  Result := TPath.Combine(TPath.GetTempPath,'idsconnect.html');
end;

function TMainForm.SelectedSection: String;
begin
  Result := '';
  if ListBox1.ItemIndex < 0 then
    exit;
  Result := ListBox1.Items[ListBox1.ItemIndex];
end;

function TMainForm.PrepareHookUrl: Boolean;
begin
  //Frueher stand hier fest die Adresse von landrix.de - wer den Hinweis
  //uebersah, hat seine Warenkoerbe an einen fremden Server geschickt.
  TIDSConnect.IDSCONNECT_HOOKURL := cfg.ReadString(CFG_SETTINGS,'HookUrl','');
  Result := TIDSConnect.IDSCONNECT_HOOKURL <> '';
  if not Result then
    MessageDlg('In der configuration.ini fehlt die eigene Rücksprungadresse:'+sLineBreak+sLineBreak+
               '['+CFG_SETTINGS+']'+sLineBreak+
               'HookUrl=https://<eigener-server>/idsconnect.php'+sLineBreak+sLineBreak+
               'Über diese Adresse werden Warenkorb- und Preisdaten zurückübertragen.',
               mtWarning,[mbOk],0);
end;

procedure TMainForm.ShowWarenkorb(_Warenkorb: TIDSConnect_Warenkorb);
var
  i : Integer;
begin
  Memo1.Clear;
  if _Warenkorb.Order.OrderItems.Count = 0 then
  begin
    Memo1.Lines.Add('Der empfangene Warenkorb enthält keine Positionen.');
    exit;
  end;
  for i := 0 to _Warenkorb.Order.OrderItems.Count-1 do
    Memo1.Lines.Add(_Warenkorb.Order.OrderItems[i].ArtNo+' '+
                    Format('%.2f',[_Warenkorb.Order.OrderItems[i].Qty])+' '+
                    TIDSConnectHelper.QuToQuStrInternal(_Warenkorb.Order.OrderItems[i].QU)+' '+
                    Format('%m',[_Warenkorb.Order.OrderItems[i].NetPrice])+' '+
                    _Warenkorb.Order.OrderItems[i].Kurztext);
end;

procedure TMainForm.HandleIDSError(const _Message: String; _E: Exception);
begin
  //Ohne diesen Callback verschwinden Parser- und Netzwerkfehler stillschweigend
  Memo1.Lines.Add('Fehler: '+_Message);
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  //Der Button hatte bisher keinen Handler
  LoadConfig;
end;

procedure TMainForm.ListBox1Click(Sender: TObject);
var
  lDemoArticle : String;
begin
  //Hat der Anbieter einen Demoartikel hinterlegt, wandert er in das Feld
  //Artikelnummer. Ohne Eintrag bleibt eine eigene Eingabe stehen.
  if SelectedSection = '' then
    exit;
  lDemoArticle := cfg.ReadString(SelectedSection,'DemoArticle','');
  if lDemoArticle <> '' then
    Edit1.Text := lDemoArticle;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  if not PrepareHookUrl then
    exit;

  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    if not TIDSConnect.IDSConnectWKE(
              cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
              cfg.ReadString(SelectedSection,'Customernumber',''),
              cfg.ReadString(SelectedSection,'Username',''),
              cfg.ReadString(SelectedSection,'Password',''),
              TempHtmlFilename,
              lWarenkorb) then
    begin
      //Bisher wurde der empfangene Warenkorb kommentarlos verworfen
      Memo1.Lines.Add('Es wurde kein Warenkorb empfangen.');
      exit;
    end;

    ShowWarenkorb(lWarenkorb);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
  if SelectedSection = '' then
    exit;
  TIDSConnect.IDSConnectADT(
            cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
            cfg.ReadString(SelectedSection,'Customernumber',''),
            cfg.ReadString(SelectedSection,'Username',''),
            cfg.ReadString(SelectedSection,'Password',''),
            Edit1.Text,
            TempHtmlFilename);
end;

procedure TMainForm.Button4Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  lSendOnly : Boolean;
  lAnswer : Integer;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  if not PrepareHookUrl then
    exit;

  //ESC lieferte hier frueher mrCancel, was als "Nein" durchging und den
  //Warenkorb trotzdem abgeschickt hat
  lAnswer := MessageDlg('Warenkorb nur senden? (Bestellung)'+sLineBreak+
                        'Nein = empfangen zum Preise aktualisieren.',
                        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if lAnswer = mrCancel then
    exit;
  lSendOnly := lAnswer = mrYes;

  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    lWarenkorb.WarenkorbInfo.Date := Date;
    //Now enthaelt auch den Datumsanteil; das Feld ist ein TTime
    lWarenkorb.WarenkorbInfo.Time := TimeOf(Now);
    //Ab IDS 2.5.1 werden Belegnummern als Referenzen uebergeben
    lWarenkorb.WarenkorbInfo.Version := idsConnectVersion_2_5_1;
    with lWarenkorb.Order.OrderInfo.Referenzen.AddItem do
    begin
      ReferenzNumber := 'B-2024-0815';
      ReferenzDate := Date;
      ReferenzType := idsConnectRefType_220; //Bestellung
    end;
    lWarenkorb.Order.OrderInfo.Kommission := 'Bauvorhaben Müller & Sohn <Neubau>';

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
              cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
              cfg.ReadString(SelectedSection,'Customernumber',''),
              cfg.ReadString(SelectedSection,'Username',''),
              cfg.ReadString(SelectedSection,'Password',''),
              TempHtmlFilename,
              lWarenkorb,lSendOnly) then
    begin
      Memo1.Lines.Add('Der Warenkorb konnte nicht übertragen werden.');
      exit;
    end;

    if lSendOnly then
    begin
      Memo1.Lines.Add('Der Warenkorb wurde an den Shop übertragen.');
      exit;
    end;

    ShowWarenkorb(lWarenkorb);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  if not PrepareHookUrl then
    exit;

  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    if not TIDSConnect.IDSConnectAS(
              cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
              cfg.ReadString(SelectedSection,'Customernumber',''),
              cfg.ReadString(SelectedSection,'Username',''),
              cfg.ReadString(SelectedSection,'Password',''),
              TempHtmlFilename,
              Edit2.Text,
              lWarenkorb,
              //ab IDS 2.5.1: keine Mehrfachrueckgabe, Hook-URL 300 Sekunden aktiv
              false,300) then
    begin
      Memo1.Lines.Add('Es wurde kein Suchergebnis übernommen.');
      exit;
    end;

    ShowWarenkorb(lWarenkorb);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.LoadConfig;
var
  i : Integer;
begin
  if Assigned(cfg) then begin cfg.Free; cfg := nil; end;

  if not FileExists(ConfigFilename) then
  begin
    ListBox1.Clear;
    Memo1.Lines.Text := 'Die Datei '+ConfigFilename+' wurde nicht gefunden.'+sLineBreak+sLineBreak+
                        'Aufbau:'+sLineBreak+
                        '['+CFG_SETTINGS+']'+sLineBreak+
                        'HookUrl=https://<eigener-server>/idsconnect.php'+sLineBreak+sLineBreak+
                        '[Name Lieferant]'+sLineBreak+
                        'Username=...'+sLineBreak+
                        'Password=...'+sLineBreak+
                        'Customernumber=...'+sLineBreak+
                        'IDSConnectUrl=https://...';
    //Damit die Buttons trotzdem definiert arbeiten koennen
    cfg := TMemIniFile.Create(ConfigFilename);
    exit;
  end;

  cfg := TMemIniFile.Create(ConfigFilename);
  cfg.ReadSections(ListBox1.Items);
  //Die Einstellungs-Sektion ist kein Anbieter
  for i := ListBox1.Items.Count-1 downto 0 do
    if SameText(ListBox1.Items[i],CFG_SETTINGS) then
      ListBox1.Items.Delete(i);

  if ListBox1.Items.Count > 0 then
  begin
    ListBox1.ItemIndex := 0;
    ListBox1Click(ListBox1);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
  TIDSConnect.IDSCONNECT_ONERROR := HandleIDSError;
  //Wie lange beim Senden/Empfangen auf die Rueckuebertragung gewartet wird.
  //0 waere ohne Zeitbegrenzung, bis der Anwender abbricht.
  TIDSConnect.IDSCONNECT_HOOKURL_TIMEOUT := 300;
  LoadConfig;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TIDSConnect.IDSCONNECT_ONERROR := nil;
  if Assigned(cfg) then begin cfg.Free; cfg := nil; end;
end;

end.
