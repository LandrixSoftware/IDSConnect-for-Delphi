unit IDSConnectUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,Vcl.Controls, Vcl.Forms, System.UITypes,
  Vcl.Dialogs, Vcl.StdCtrls, System.Inifiles, System.StrUtils, System.IOUtils,
  System.DateUtils, System.Math, Vcl.ComCtrls, System.Generics.Collections,
  LandrixXmlDom, LandrixXmlWriter
  ,intf.IDSConnectTypes,intf.IDSConnect,intf.IDSConnectDlgWebBrowser, Vcl.ExtCtrls;

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
    Button6: TButton;
    Panel1: TPanel;
    FSaveResponse: TButton;
    FHeatinglabel: TButton;
    FHeatinglabelCart: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure SaveResponseClick(Sender : TObject);
    procedure HeatinglabelClick(Sender: TObject);
    procedure HeatinglabelCartClick(Sender: TObject);
  private
    //Aufbau der Ini-Datei mit Lieferanten
    //
    //[Settings]
    //HookUrl=https://<eigener-server>/idsconnect.php
    //                     Eigene Ruecksprungadresse, ueber die der Shop den
    //                     Warenkorb zurueckuebertraegt. Pflicht fuer WKE, WKS
    //                     und AS. Ein passendes Skript liegt als
    //                     idsconnect.php bei.
    //
    //[Name Lieferant]     Der Abschnittsname erscheint in der Anbieterliste
    //Username=...         Benutzername beim Grosshaendler
    //Password=...         Passwort beim Grosshaendler
    //Customernumber=...   Kundennummer beim Grosshaendler
    //                     Welche der drei Angaben noetig sind, verraet die
    //                     Abfrage "LI" (Schalter "Shop-Infos")
    //IDSConnectUrl=https://...
    //                     Einstiegsadresse der IDS-Schnittstelle des Shops
    //Version=2.5         optional, 2.5 oder 2.5.1. Ohne Eintrag fragt das
    //                     Beispiel den Shop einmal per SV und nimmt die hoechste
    //                     gemeinsame Version, ohne Antwort 2.5. Kein Shop der
    //                     Lieferantentabelle meldet bisher 2.5.1 - der fruehere
    //                     Standard 2.5.1 scheiterte z. B. bei Buderus.
    //DemoArticle=...      optional; Artikelnummer, die beim Auswaehlen des
    //                     Anbieters in das Feld Artikelnummer uebernommen wird
    //MultipleResult=1     optional; der Shop beherrscht die Mehrfachrueckgabe
    //                     an die HookUrl (ab IDS 2.5.1). Das laesst sich nicht
    //                     abfragen - der Parameter ist eine Zusage der
    //                     Handwerkssoftware an den Shop - und muss deshalb je
    //                     Anbieter einmal ausprobiert und hier hinterlegt
    //                     werden.
    //HeatinglabelUrl=...  optional; Adresse einer Heatinglabel-Plattform
    //                     (Aktion HLS), falls sie nicht die IDS-Adresse ist

    cfg : TMemIniFile;
    //Per SV ermittelte Versionen je Anbieter (Schluessel: Abschnittsname in
    //Kleinbuchstaben, wie TMemIniFile ohne Gross-/Kleinschreibung), damit
    //nicht jeder Aufruf erneut fragt; wird beim Laden der Ini geleert.
    //Ein Woerterbuch statt TStringList.Values: ein "=" im Abschnittsnamen
    //verwechselte dort die Eintraege.
    FDetectedVersions : TDictionary<String,String>;
    //Antwort der SV-Abfrage, die ReadShopVersion gerade fuer die Erkennung
    //gestellt hat - der Schalter "Shop-Infos" zeigt sie an, statt ein
    //zweites Mal zu fragen
    FSvFromDetection : Boolean;
    FSvAnswered : Boolean;
    FSvList : TStringList;
    FPages : TPageControl;
    FRawMemo, FCartMemo : TMemo;
    FResponseBody : TBytes;
    //Zuletzt empfangener Warenkorb (WKE, WKS mit Rueckgabe, AS) und sein
    //Anbieter; der Schalter "Heatinglabel aus Warenkorb" sendet dessen
    //Positionen mit EAN an die Heatinglabel-Plattform
    FLastCart : TIDSConnect_Warenkorb;
    FLastCartSection : String;
    procedure RememberCart(_Warenkorb : TIDSConnect_Warenkorb);
    //Gemeinsamer Teil beider Heatinglabel-Schalter: Version, Hook-URL,
    //Plattform-Adresse, Aufruf und Anzeige der Rueckgabe
    procedure SendHeatinglabel(_Label : TIDSConnect_Heatinglabel);
    procedure CreateResultViews;
    procedure HandleIDSRequest(const _Url,_Parameters : String);
    procedure HandleIDSResponse(const _Url : String; _StatusCode : Integer;
      const _Body : TBytes);
    procedure ShowReceivedCart(_Warenkorb : TIDSConnect_Warenkorb);
    function ConfigFilename : String;
    function ReadShopVersion(out _Version : TIDSConnect_Version) : Boolean;
    procedure LoadConfig;
    //Die Hook-URL muss auf einen eigenen Server zeigen; ueber sie laufen
    //Warenkorb-, Preis- und Kundendaten zurueck zur Handwerkssoftware.
    function PrepareHookUrl : Boolean;
    function SelectedSection : String;
    function TempHtmlFilename : String;
    //Ob der Shop die Mehrfachrueckgabe beherrscht, ist nicht abfragbar und
    //wird deshalb je Anbieter in der config.ini hinterlegt
    function UseMultipleResult : Boolean;
    procedure ShowWarenkorb(_Warenkorb : TIDSConnect_Warenkorb);
    //Zeigt die Rueckgabe einer Heatinglabel-Plattform an und speichert die
    //PDFs unter Dokumente\IDSConnect-Heatinglabel
    procedure ShowHeatinglabel(_Label : TIDSConnect_Heatinglabel);
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
var
  lDir : String;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName),'config.ini');
  if FileExists(Result) then
    exit;
  Result := TPath.Combine(ExtractFilePath(Application.ExeName),'configuration.ini');
  if FileExists(Result) then
    exit;
  lDir := ExtractFilePath(ExtractFileDir(ExtractFileDir(Application.ExeName)));
  Result := TPath.Combine(lDir,'config.ini');
  if not FileExists(Result) and FileExists(TPath.Combine(lDir,'configuration.ini')) then
    Result := TPath.Combine(lDir,'configuration.ini');
end;

function TMainForm.ReadShopVersion(out _Version : TIDSConnect_Version) : Boolean;
var
  lValue, lUrl : String;
  lDetected : TIDSConnect_Version;
begin
  lValue := Trim(cfg.ReadString(SelectedSection,'Version',''));
  if lValue = '' then
  begin
    //Keine Version eingetragen: einmal beim Shop nachfragen. Frueher galt
    //dann 2.5.1, das kein bekannter Shop meldet.
    if not FDetectedVersions.TryGetValue(LowerCase(SelectedSection),lValue) then
    begin
      lDetected := idsConnectVersion_Unkown;
      FSvList.Clear;
      FSvAnswered := false;
      lUrl := cfg.ReadString(SelectedSection,'IDSConnectUrl','');
      if lUrl <> '' then
      begin
        Screen.Cursor := crHourGlass;
        try
          FSvAnswered := TIDSConnect.IDSConnectSV(lUrl,FSvList,idsConnectVersion_2_5);
        finally
          Screen.Cursor := crDefault;
        end;
        FSvFromDetection := true;
        if FSvAnswered then
          lDetected := TIDSConnect.BestSupportedVersion(FSvList);
      end;
      if lDetected <> idsConnectVersion_Unkown then
      begin
        lValue := TIDSConnectHelper.VersionToStr(lDetected);
        Memo1.Lines.Add('Keine Version in '+ConfigFilename+' ['+SelectedSection+']: '+
                        'laut Versionsabfrage (SV) '+lValue+'.');
      end else
      begin
        lValue := '2.5';
        if FSvAnswered then
          //Der Shop antwortet, nennt aber nur Versionen vor 2.5 - die kann
          //diese Unit nicht erzeugen; 2.5 ist dann ein Versuch
          Memo1.Lines.Add('Keine Version in '+ConfigFilename+' ['+SelectedSection+']: '+
                          'der Shop meldet nur '+FSvList.CommaText+', diese Unit kann ab 2.5 - '+
                          'verwende 2.5, der Aufruf scheitert womöglich.')
        else
          Memo1.Lines.Add('Keine Version in '+ConfigFilename+' ['+SelectedSection+'] und keine '+
                          'Antwort auf die Versionsabfrage (SV): verwende 2.5.');
      end;
      FDetectedVersions.AddOrSetValue(LowerCase(SelectedSection),lValue);
    end;
  end;
  _Version := TIDSConnectHelper.VersionFromStr(lValue);
  Result := (lValue = '2.5') or (lValue = '2.5.1');
  if not Result then
  begin
    FPages.ActivePageIndex := 0;
    Memo1.Lines.Add('Ungültige Version in '+ConfigFilename+' ['+SelectedSection+']: "'+lValue+'". Erlaubt: 2.5 oder 2.5.1.');
  end;
end;

procedure TMainForm.CreateResultViews;
var
  lTab : TTabSheet;

  function AddMemo(const _Caption : String) : TMemo;
  var
    lPage : TTabSheet;
  begin
    lPage := TTabSheet.Create(Self);
    lPage.PageControl := FPages;
    lPage.Caption := _Caption;
    Result := TMemo.Create(Self);
    Result.Parent := lPage;
    Result.Align := alClient;
    Result.ReadOnly := true;
    Result.ScrollBars := ssBoth;
    Result.WordWrap := true;
    Result.Font.Name := 'Consolas';
  end;

begin
  FPages := TPageControl.Create(Self);
  FPages.Parent := Panel1;
  FPages.Align := alClient;
  lTab := TTabSheet.Create(Self);
  lTab.PageControl := FPages;
  lTab.Caption := 'Aufruf / Protokoll';
  Memo1.Parent := lTab;
  Memo1.Align := alClient;
  Memo1.ReadOnly := true;
  Memo1.WordWrap := false;
  FRawMemo := AddMemo('XML / Rückgabe');
  FCartMemo := AddMemo('Eingelesener Warenkorb');
  FPages.ActivePageIndex := 0;
end;

procedure TMainForm.HandleIDSRequest(const _Url,_Parameters : String);
begin
  Memo1.Lines.Add('Vorbereiteter Shop-Aufruf: POST '+_Url);
  Memo1.Lines.Add(_Parameters);
  Memo1.Lines.Add('Der Browser führt den Shop-Aufruf aus. Die Rückgabe wird über die Hook-URL abgeholt.');
  Memo1.Lines.Add('');
end;

procedure TMainForm.HandleIDSResponse(const _Url : String; _StatusCode : Integer;
  const _Body : TBytes);
var
  lText, lDecl : String;
  lEncoding : TEncoding;
  lDoc : TLandrixXmlDocument;
begin
  Memo1.Lines.Add(FormatDateTime('hh:nn:ss',Now)+' Hook-Abruf: HTTP '+
    IntToStr(_StatusCode)+', '+IntToStr(Length(_Body))+' Bytes');
  if _StatusCode = 404 then
    Memo1.Lines.Add('Noch keine Rückgabe an der Hook-URL vorhanden.');
  //Leere Polling-Antworten und 404 duerfen die letzte Nutzlast nicht verdecken.
  if (_StatusCode = 404) or (Length(_Body) = 0) then
    exit;
  FResponseBody := Copy(_Body,0,Length(_Body));
  FSaveResponse.Enabled := true;
  lDecl := TEncoding.ASCII.GetString(_Body,0,Min(Length(_Body),200));
  lEncoding := nil;
  try
    if ContainsText(lDecl,'iso-8859-1') then
      lEncoding := TEncoding.GetEncoding(28591)
    else if ContainsText(lDecl,'windows-1252') then
      lEncoding := TEncoding.GetEncoding(1252);
    if Assigned(lEncoding) then
      lText := lEncoding.GetString(_Body)
    else
    begin
      try
        lText := TEncoding.UTF8.GetString(_Body);
      except
        on E: EEncodingError do
        begin
          lEncoding := TEncoding.GetEncoding(28591);
          lText := lEncoding.GetString(_Body);
          Memo1.Lines.Add('Die Rückgabe ist kein gültiges UTF-8. Anzeige ersatzweise als ISO-8859-1; gespeicherte Bytes bleiben unverändert.');
        end;
      end;
    end;
    //Nur die Anzeige formatieren. FResponseBody bleibt fuer den Export
    //unveraendert; auch ungueltige XML-/HTML-Antworten bleiben sichtbar.
    lDoc := TLandrixXmlDocument.Create;
    try
      try
        if Length(_Body) = 0 then
          Abort;
        //Nur fuer die Anzeige: Leerraum zwischen Elementen verwerfen, sonst
        //bleibt eine teilweise formatierte Antwort ohne Einrueckung
        lDoc.WhitespaceMode := xwmDropBetweenElements;
        //Die Bibliothek erkennt die Kodierung selbst aus BOM und Deklaration
        lDoc.LoadFromBuffer(_Body[0],Length(_Body));
        lDoc.Indent := true;
        lDoc.LineBreak := xlbCRLF;
        FRawMemo.Text := lDoc.SaveToString;
      except
        on E: Exception do
          FRawMemo.Text := lText;
      end;
    finally
      lDoc.Free;
    end;
  finally
    lEncoding.Free;
  end;
end;

procedure TMainForm.SaveResponseClick(Sender : TObject);
var
  lDialog : TSaveDialog;
begin
  lDialog := TSaveDialog.Create(Self);
  try
    lDialog.Title := 'Unveränderte Rückgabe speichern';
    lDialog.Filter := 'XML-Datei (*.xml)|*.xml|Alle Dateien (*.*)|*.*';
    lDialog.DefaultExt := 'xml';
    lDialog.FileName := 'wke-rueckgabe.xml';
    lDialog.Options := lDialog.Options + [ofOverwritePrompt];
    if lDialog.Execute then
      TFile.WriteAllBytes(lDialog.FileName,FResponseBody);
  finally
    lDialog.Free;
  end;
end;

procedure TMainForm.ShowReceivedCart(_Warenkorb : TIDSConnect_Warenkorb);
var
  i : Integer;
  lItem : TIDSConnect_OrderItem;
begin
  FCartMemo.Clear;
  if _Warenkorb.WarenkorbInfo.Version = idsConnectVersion_Unkown then
    FCartMemo.Lines.Add('Version: unbekannt')
  else
    FCartMemo.Lines.Add('Version: '+TIDSConnectHelper.VersionToStr(_Warenkorb.WarenkorbInfo.Version));
  FCartMemo.Lines.Add('Kundennummer: '+_Warenkorb.Order.CustomerInfo.IDNo);
  FCartMemo.Lines.Add('Kommission: '+_Warenkorb.Order.OrderInfo.Kommission);
  FCartMemo.Lines.Add('Positionen: '+IntToStr(_Warenkorb.Order.OrderItems.Count));
  FCartMemo.Lines.Add('Hinweis: Fehlende Zahlenfelder können im Datenmodell als 0 erscheinen. Maßgeblich ist die XML-Rückgabe.');
  for i := 0 to _Warenkorb.Order.OrderItems.Count-1 do
  begin
    lItem := _Warenkorb.Order.OrderItems[i];
    FCartMemo.Lines.Add('');
    FCartMemo.Lines.Add(Format('Position %d: %s',[i+1,lItem.ArtNo]));
    FCartMemo.Lines.Add('  Kurztext: '+lItem.Kurztext);
    FCartMemo.Lines.Add('  Langtext: '+lItem.Langtext);
    FCartMemo.Lines.Add('  EAN: '+lItem.EAN);
    FCartMemo.Lines.Add(Format('  Menge: %.4f %s',[lItem.Qty,TIDSConnectHelper.QuToQuStr(lItem.QU)]));
    FCartMemo.Lines.Add(Format('  Nettopreis: %.4f   Preisbasis: %.4f   MwSt.: %.2f %%',
      [lItem.NetPrice,lItem.PriceBasis,lItem.VAT]));
    FCartMemo.Lines.Add('  Hinweis: '+lItem.Hinweis);
    FCartMemo.Lines.Add(Format('  Fehlercode: %d   Fehlertext: %s',[Ord(lItem.Fehlercode),lItem.Fehlertext]));
    if (lItem.Fehlercode <> idsConnectFc_None) or (lItem.Fehlertext <> '') then
      Memo1.Lines.Add(Format('Shop meldet einen Fehler bei Position %d: %s',[i+1,lItem.Fehlertext]));
  end;
  if _Warenkorb.Order.OrderItems.Count = 0 then
    Memo1.Lines.Add('Die Rückgabe enthält keine Positionen.');
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
  //Ein eindeutiger Name je Aufruf: Mit dem frueheren festen Namen
  //ueberschrieben sich parallele Instanzen gegenseitig. Die Unit loescht die
  //Datei nach Gebrauch (IDSCONNECT_TMPFILE_DELETE_DELAY).
  Result := TPath.Combine(TPath.GetTempPath,
              'idsconnect-'+TGUID.NewGuid.ToString.Trim(['{','}'])+'.html');
end;

function TMainForm.UseMultipleResult: Boolean;
begin
  Result := cfg.ReadBool(SelectedSection,'MultipleResult',false);
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
    MessageDlg('In '+ConfigFilename+' fehlt die eigene Rücksprungadresse:'+sLineBreak+sLineBreak+
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

procedure TMainForm.Button6Click(Sender: TObject);
var
  lUrl : String;
  lLogin : TIDSConnect_LoginInfo;
  lVersions : TStringList;
  lVersion : TIDSConnect_Version;
  lAnswered : Boolean;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  FSvFromDetection := false;
  if not ReadShopVersion(lVersion) then
    exit;
  lUrl := cfg.ReadString(SelectedSection,'IDSConnectUrl','');
  if lUrl = '' then
    exit;

  Screen.Cursor := crHourGlass;
  try
    Memo1.Lines.Add('Abfrage an '+lUrl);
    Memo1.Lines.Add('Verwendete Version: '+TIDSConnectHelper.VersionToStr(lVersion));
    Memo1.Lines.Add('');

    //Aktion "SV": welche Schnittstellenversionen kann der Shop?
    lVersions := TStringList.Create;
    try
      //Hat ReadShopVersion gerade erst per SV gefragt, deren Antwort zeigen
      //statt ein zweites Mal zu fragen (bei einem stummen Shop zweimal Timeout)
      if FSvFromDetection then
      begin
        lAnswered := FSvAnswered;
        lVersions.Assign(FSvList);
      end else
        lAnswered := TIDSConnect.IDSConnectSV(lUrl,lVersions,lVersion);
      FSvFromDetection := false;
      if lAnswered then
      begin
        Memo1.Lines.Add('Unterstützte Versionen: '+lVersions.CommaText);
        //Dieselbe Liste auswerten statt einer zweiten SV-Abfrage
        Memo1.Lines.Add('Höchste gemeinsame Version: '+
          TIDSConnectHelper.VersionToStr(TIDSConnect.BestSupportedVersion(lVersions)));
      end else
        Memo1.Lines.Add('Versionsabfrage (SV) nicht beantwortet.');
    finally
      lVersions.Free;
    end;

    //Aktion "LI": welche Anmeldedaten braucht der Shop?
    if TIDSConnect.IDSConnectLI(lUrl,lLogin,lVersion) then
    begin
      Memo1.Lines.Add('');
      Memo1.Lines.Add('Kundennummer erforderlich: '+BoolToStr(lLogin.CustomerNoRequired,true));
      Memo1.Lines.Add('Benutzername erforderlich: '+BoolToStr(lLogin.UsernameRequired,true));
      Memo1.Lines.Add('Passwort erforderlich:     '+BoolToStr(lLogin.PasswordRequired,true));
    end else
      Memo1.Lines.Add('Loginabfrage (LI) nicht beantwortet.');

    //Die Mehrfachrueckgabe laesst sich nicht abfragen - sie ist eine Zusage
    //der Handwerkssoftware an den Shop. Deshalb wird sie je Anbieter in der
    //config.ini hinterlegt.
    Memo1.Lines.Add('');
    Memo1.Lines.Add('Mehrfachrückgabe laut config.ini: '+
                    BoolToStr(UseMultipleResult,true)+
                    '  (Schlüssel MultipleResult, nicht abfragbar)');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  lVersion : TIDSConnect_Version;
  lStarted : UInt64;
  lOldRequest : TIDSConnectOnRequest;
  lOldResponse : TIDSConnectOnResponse;
begin
  Memo1.Clear;
  FRawMemo.Clear;
  FCartMemo.Clear;
  FResponseBody := nil;
  FSaveResponse.Enabled := false;
  FPages.ActivePageIndex := 0;
  if SelectedSection = '' then
  begin
    Memo1.Lines.Add('Bitte zuerst einen Anbieter auswählen.');
    exit;
  end;
  if not ReadShopVersion(lVersion) then
    exit;
  if not PrepareHookUrl then
    exit;

  Memo1.Lines.Add('WKE – Warenkorb empfangen: '+SelectedSection);
  Memo1.Lines.Add('Im Shop den gewünschten Warenkorb an die Handwerkssoftware zurückgeben.');
  Memo1.Lines.Add('Browser: '+IfThen(CheckBox1.Checked,'integriert','Standardbrowser'));
  lStarted := GetTickCount64;
  lOldRequest := TIDSConnect.IDSCONNECT_ONREQUEST;
  lOldResponse := TIDSConnect.IDSCONNECT_ONRESPONSE;
  lWarenkorb := TIDSConnect_Warenkorb.Create;
  try
    TIDSConnect.IDSCONNECT_ONREQUEST := HandleIDSRequest;
    TIDSConnect.IDSCONNECT_ONRESPONSE := HandleIDSResponse;
    if not TIDSConnect.IDSConnectWKE(
              cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
              cfg.ReadString(SelectedSection,'Customernumber',''),
              cfg.ReadString(SelectedSection,'Username',''),
              cfg.ReadString(SelectedSection,'Password',''),
              TempHtmlFilename,
              lWarenkorb,lVersion) then
    begin
      Memo1.Lines.Add('Ergebnis: Kein Warenkorb erfolgreich eingelesen.');
      Memo1.Lines.Add('Bei Abbruch oder ausbleibender Rückgabe lässt sich daraus kein Shop-Fehler ableiten.');
      exit;
    end;

    Memo1.Lines.Add('Ergebnis: Rückgabe empfangen und als Warenkorb eingelesen.');
    Memo1.Lines.Add('Dies ist keine XML-Schema- oder fachliche Vollständigkeitsprüfung.');
    ShowReceivedCart(lWarenkorb);
    RememberCart(lWarenkorb);
  finally
    TIDSConnect.IDSCONNECT_ONREQUEST := lOldRequest;
    TIDSConnect.IDSCONNECT_ONRESPONSE := lOldResponse;
    Memo1.Lines.Add(Format('Dauer einschließlich Shop-Bedienung: %.1f s',[(GetTickCount64-lStarted)/1000]));
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.Button3Click(Sender: TObject);
var
  lVersion : TIDSConnect_Version;
begin
  if SelectedSection = '' then
    exit;
  if not ReadShopVersion(lVersion) then
    exit;
  TIDSConnect.IDSConnectADT(
            cfg.ReadString(SelectedSection,'IDSConnectUrl',''),
            cfg.ReadString(SelectedSection,'Customernumber',''),
            cfg.ReadString(SelectedSection,'Username',''),
            cfg.ReadString(SelectedSection,'Password',''),
            Edit1.Text,
            TempHtmlFilename,lVersion);
end;

procedure TMainForm.Button4Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  lVersion : TIDSConnect_Version;
  lSendOnly : Boolean;
  lAnswer : Integer;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  if not ReadShopVersion(lVersion) then
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
    lWarenkorb.WarenkorbInfo.Version := lVersion;
    //Ab IDS 2.5.1 werden Belegnummern als Referenzen uebergeben.
    if lVersion = idsConnectVersion_2_5_1 then
    with lWarenkorb.Order.OrderInfo.Referenzen.AddItem do
    begin
      ReferenzNumber := 'B-2024-0815';
      ReferenzDate := Date;
      ReferenzType := idsConnectRefType_220; //Bestellung
    end
    else
      lWarenkorb.Order.OrderInfo.PartNo := 'B-2024-0815';
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
    RememberCart(lWarenkorb);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.RememberCart(_Warenkorb: TIDSConnect_Warenkorb);
begin
  FLastCart.Assign(_Warenkorb);
  FLastCartSection := SelectedSection;
end;

procedure TMainForm.SendHeatinglabel(_Label: TIDSConnect_Heatinglabel);
var
  lVersion : TIDSConnect_Version;
  lUrl : String;
begin
  if not ReadShopVersion(lVersion) then
    exit;
  if not PrepareHookUrl then
    exit;
  //Die Heatinglabel-Plattform kann eine eigene Adresse haben; ohne Eintrag
  //wird die IDS-Adresse des Anbieters verwendet
  lUrl := cfg.ReadString(SelectedSection,'HeatinglabelUrl','');
  if lUrl = '' then
    lUrl := cfg.ReadString(SelectedSection,'IDSConnectUrl','');

  if not TIDSConnect.IDSConnectHLS(
            lUrl,
            cfg.ReadString(SelectedSection,'Customernumber',''),
            cfg.ReadString(SelectedSection,'Username',''),
            cfg.ReadString(SelectedSection,'Password',''),
            TempHtmlFilename,
            _Label,lVersion) then
  begin
    Memo1.Lines.Add('Es wurde kein Heatinglabel übernommen.');
    exit;
  end;
  ShowHeatinglabel(_Label);
end;

procedure TMainForm.HeatinglabelCartClick(Sender: TObject);
var
  lLabel : TIDSConnect_Heatinglabel;
  lCount : Integer;
begin
  Memo1.Clear;
  if SelectedSection = '' then
  begin
    Memo1.Lines.Add('Bitte zuerst einen Anbieter auswählen.');
    exit;
  end;
  if FLastCart.Order.OrderItems.Count = 0 then
  begin
    Memo1.Lines.Add('Es liegt noch kein empfangener Warenkorb vor.');
    Memo1.Lines.Add('Zuerst mit "Warenkorb empfangen" im Shop die Anlagenteile '+
                    '(z. B. Kessel, Regler, Speicher, Solarkollektoren) zurückgeben.');
    exit;
  end;
  //Die EANs stammen aus dem Shop eines Anbieters; an eine andere Plattform
  //geschickt, wuerde das Ergebnis nur verwirren
  if not SameText(FLastCartSection,SelectedSection) then
    if MessageDlg('Der letzte Warenkorb stammt von "'+FLastCartSection+'".'+sLineBreak+
                  'Trotzdem an "'+SelectedSection+'" senden?',
                  mtConfirmation,[mbYes,mbNo],0) <> mrYes then
      exit;

  lLabel := TIDSConnect_Heatinglabel.Create;
  try
    //Anlagenfunktion und -typ bleiben offen; die Plattform ermittelt sie aus
    //den Komponenten
    lLabel.Header.PackageSupplier := 'Musterbetrieb Heizung';
    lLabel.Header.IncludeProductLabels := true;
    //Uebernimmt nur Positionen mit EAN; die uebrigen meldet die Unit ueber
    //IDSCONNECT_ONERROR
    lCount := lLabel.AddFromWarenkorb(FLastCart);
    Memo1.Lines.Add(Format('Heatinglabel aus dem Warenkorb von "%s": %d von %d Positionen mit EAN.',
      [FLastCartSection,lCount,FLastCart.Order.OrderItems.Count]));
    if lCount = 0 then
    begin
      Memo1.Lines.Add('Ohne EAN kann die Plattform keine Komponente zuordnen - nichts gesendet.');
      exit;
    end;
    SendHeatinglabel(lLabel);
  finally
    lLabel.Free;
  end;
end;

procedure TMainForm.HeatinglabelClick(Sender: TObject);
var
  lLabel : TIDSConnect_Heatinglabel;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;

  lLabel := TIDSConnect_Heatinglabel.Create;
  try
    //Beispielanlage (Wolf): Gas-Brennwert-Zentrale mit Speicher, Bedienmodul,
    //Solarmodul und zwei Sonnenkollektoren - echte GTINs, damit eine
    //Plattform die Komponenten erkennen kann (Used statt NotFound). Fuer die
    //Artikel eines empfangenen Warenkorbs: Schalter "Heatinglabel aus
    //Warenkorb" (lLabel.AddFromWarenkorb).
    lLabel.Header.PackageFunction := idsHlPf_Combination;
    lLabel.Header.PackageType := idsHlPt_CombinationBoiler;
    lLabel.Header.LoadProfile := idsHlLp_XL;
    lLabel.Header.PackageSupplier := 'Musterbetrieb Heizung';
    lLabel.Header.SolarDeviceUsage := idsHlSu_Both;
    lLabel.Header.IncludeProductLabels := true;
    with lLabel.Positions.AddItem do
    begin
      GTIN := '4045013283442';
      Shorttext := 'Wolf Gasbrennwert-Zentrale CGW-2-24/140L';
      Qty := 1;
      RefItems_Customer := '1';
    end;
    with lLabel.Positions.AddItem do
    begin
      GTIN := '4045013189485';
      Shorttext := 'Wolf Bedienmodul BM-2 inkl. Außenfühler';
      Qty := 1;
      RefItems_Customer := '2';
    end;
    with lLabel.Positions.AddItem do
    begin
      GTIN := '4045013285590';
      Shorttext := 'Wolf Solarmodul SM1-2';
      Qty := 1;
      RefItems_Customer := '3';
    end;
    with lLabel.Positions.AddItem do
    begin
      GTIN := '4045013044869';
      Shorttext := 'Wolf Sonnenkollektor TopSon F3-1';
      Qty := 2;
      RefItems_Customer := '4';
    end;
    SendHeatinglabel(lLabel);
  finally
    lLabel.Free;
  end;
end;

procedure TMainForm.ShowHeatinglabel(_Label: TIDSConnect_Heatinglabel);
var
  i : Integer;
  lDir : String;
  lPos : TIDSConnect_HeatinglabelPosition;
  lCount : Integer;

  //Speichert ein PDF unter seinem Namen; der Name kommt von der Plattform und
  //wird deshalb auf einen reinen Dateinamen ohne Pfad reduziert
  //Die laufende Nummer vorn: das Schema erlaubt gleiche Namen, die sich
  //sonst gegenseitig ueberschrieben
  procedure SavePdf(_Pdf : TIDSConnect_HeatinglabelPDF; const _Fallback : String);
  var
    lName : String;
    c : Char;
  begin
    if _Pdf.IsEmpty then
      exit;
    lName := ExtractFileName(StringReplace(_Pdf.PDFName,'/','\',[rfReplaceAll]));
    for c in TPath.GetInvalidFileNameChars do
      lName := StringReplace(lName,c,'_',[rfReplaceAll]);
    if (lName = '') or (lName = '.') or (lName = '..') then
      lName := _Fallback;
    if not EndsText('.pdf',lName) then
      lName := lName+'.pdf';
    Inc(lCount);
    lName := TPath.Combine(lDir,Format('%.2d-%s',[lCount,lName]));
    _Pdf.SaveToFile(lName);
    Memo1.Lines.Add('  PDF '+IDS_HL_PDFTYPE_CODES[_Pdf.PDFType]+': '+lName);
  end;

begin
  lDir := TPath.Combine(TPath.GetDocumentsPath,'IDSConnect-Heatinglabel\'+FormatDateTime('yyyymmdd-hhnnss',Now));
  ForceDirectories(lDir);
  lCount := 0;
  Memo1.Lines.Add('Heatinglabel empfangen:');
  Memo1.Lines.Add('  Anlage: '+IDS_HL_PACKAGEFUNCTION_CODES[_Label.Header.PackageFunction]+' / '+
                  IDS_HL_PACKAGETYPE_CODES[_Label.Header.PackageType]+', zusammengestellt von '+
                  _Label.Header.PackageSupplier);
  for i := 0 to _Label.Header.PDFs.Count-1 do
    SavePdf(_Label.Header.PDFs[i],Format('anlage-%d',[i+1]));
  for i := 0 to _Label.Positions.Count-1 do
  begin
    lPos := _Label.Positions[i];
    Memo1.Lines.Add(Format('  Pos. %s: %s %s %s - %s, %s',
      [lPos.RefItems_Customer,lPos.SupplierID,lPos.Productnumber,lPos.GTIN,
       IDS_HL_STATUS_CODES[lPos.Status],IDS_HL_PRODUCTTYPE_CODES[lPos.Producttype]]));
    SavePdf(lPos.PDF,Format('position-%d',[i+1]));
  end;
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  lWarenkorb : TIDSConnect_Warenkorb;
  lVersion : TIDSConnect_Version;
begin
  Memo1.Clear;
  if SelectedSection = '' then
    exit;
  if not ReadShopVersion(lVersion) then
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
              //ab IDS 2.5.1: Mehrfachrueckgabe nur, wenn der Anbieter sie laut
              //config.ini beherrscht. Die Hook-URL bleibt jeweils
              //300 Sekunden nach der letzten Rueckgabe aktiv.
              UseMultipleResult,300,lVersion) then
    begin
      Memo1.Lines.Add('Es wurde kein Suchergebnis übernommen.');
      exit;
    end;

    ShowWarenkorb(lWarenkorb);
    RememberCart(lWarenkorb);
  finally
    lWarenkorb.Free;
  end;
end;

procedure TMainForm.LoadConfig;
var
  i : Integer;
begin
  if Assigned(cfg) then begin cfg.Free; cfg := nil; end;
  //Geaenderte Ini: Versionen neu ermitteln
  FDetectedVersions.Clear;
  FSvFromDetection := false;

  if not FileExists(ConfigFilename) then
  begin
    ListBox1.Clear;
    Memo1.Lines.Text := 'Die Datei '+ConfigFilename+' wurde nicht gefunden.'+sLineBreak+sLineBreak+
                        'Aufbau:'+sLineBreak+sLineBreak+
                        '['+CFG_SETTINGS+']'+sLineBreak+
                        'HookUrl=https://<eigener-server>/idsconnect.php'+sLineBreak+sLineBreak+
                        '[Name Lieferant]'+sLineBreak+
                        'Username=...'+sLineBreak+
                        'Password=...'+sLineBreak+
                        'Customernumber=...'+sLineBreak+
                        'IDSConnectUrl=https://...'+sLineBreak+
                        //Kommentare auf eigenen Zeilen: TMemIniFile liest einen
                        //Kommentar hinter dem Wert mit ("1 ; ..." ist kein Boolean)
                        '; optional, 2.5 oder 2.5.1 - ohne Eintrag per SV ermittelt'+sLineBreak+
                        'Version=2.5'+sLineBreak+
                        '; optional, füllt das Feld Artikelnummer'+sLineBreak+
                        'DemoArticle=...'+sLineBreak+
                        '; optional, Shop beherrscht die Mehrfachrückgabe'+sLineBreak+
                        'MultipleResult=1'+sLineBreak+sLineBreak+
                        'Die HookUrl ist die eigene Rücksprungadresse, über die der Shop'+sLineBreak+
                        'den Warenkorb zurückschickt. Ein passendes Serverskript liegt'+sLineBreak+
                        'dem Projekt als idsconnect.php bei.';
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
  FDetectedVersions := TDictionary<String,String>.Create;
  FSvList := TStringList.Create;
  FLastCart := TIDSConnect_Warenkorb.Create;
  CreateResultViews;
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
  FreeAndNil(FDetectedVersions);
  FreeAndNil(FSvList);
  FreeAndNil(FLastCart);
end;

end.
